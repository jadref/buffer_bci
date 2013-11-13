% load a visual speller dataset
expt='own_experiments/visual/p300_prn_2';
subj='rutger';
session='20100714';
label='rc_5_flash_ep';
z=jf_load(expt,subj,label,session);
if ( 1 ) 
  % slice into simple dataset
  runsubFn('preprocess',z,'ss128','eegonly','seq2epoch','flatteny','baldata');
else
  % slice into epochs
  start_ms=shiftdim(cat(3,z.di(n2d(z.di,'letter')).extra.flashi_ms));
  z=jf_windowData(z,'dim',{'time' 'letter'},'windowType',1,...
                  'start_ms',start_ms,'width_ms',600,'di','epoch',...
                  'summary','per-flash epochs');
  % setup the labels
  Yl = single(cat(1,z.di(n2d(z.di,'letter')).extra.flash))';
  Yl = Yl(1:size(z.X,n2d(z.di,'epoch')),:); % sub-set!
  [z.Y fkey fspMx]= lab2ind(Yl,[1 0],[],1);  % convert to +1/-1, ensure 1 is +class
  z.Ydi= mkDimInfo(size(z.Y),'epoch',[],[],'letter',[],[],'subProb',[],{['tgt v non-tgt']},[],[],[]);
  z.Ydi(1)=z.di(n2d(z.di,'epoch'));  % epoch info
  [z.Ydi(1).extra(1:size(Yl,1)).marker]=num2csl(Yl,2); % override epoch marker info with true info
  z.Ydi(2)=z.di(n2d(z.di,'letter')); % letter info
  z.Ydi(1).info=struct('label',{'tgt' 'non-tgt'},... % human name for this class
                       'spKey',fkey,...  % col to classID mapping, match z.Ydi(1).extra.marker
                       'spType','1vR','spMx',fspMx);  % decoding matrix

  % balance the classes..
  balI=balanceYs(z.Y,[],3);
  z.foldIdxs=gennFold(z.Y.*single(balI<0),10,'dim',3); % exclude unbal points from all training/testing
  z=jf_compressDims(z,'dim',{'epoch' 'letter'});
  z=jf_retain(z,'dim','epoch','idx',balI(:)<0,'summary','bal pts only');
  z=jf_retain(z,'dim','ch','idx',[z.di(n2d(z.di,'ch')).extra.iseeg],'summary','eeg only');
  z.Ydi(2).info.label={'tgt' 'non-tgt'}; % so plots look right
end
oz=z;

%save a 'raw' version of this data
X=z.X; Y=z.Y; fs=z.di(2).info.fs; Cnames=z.di(1).vals; Cpos=[z.di(1).extra.pos2d];
save('ERPdata','-V6','X','Y','fs','Cnames','Cpos');

% plot
clf;jf_plotERP(z); suptitle('Raw data');saveaspdf('raw.pdf');

% detrend
z=jf_detrend(z);
clf;jf_plotERP(z); suptitle('Detrend');saveaspdf('detrend.pdf');

% bad-ch rm
z=jf_rmOutliers(z,'dim','ch','thresh',2);
clf;jf_plotERP(z); suptitle('Detrend + bad-ch rm');saveaspdf('detrend+badch.pdf');

% slap
z=jf_spatdownsample(z,'dim','ch','capFile','cap64','idx','eegonly');
clf;jf_plotERP(z); suptitle('Detrended + bad-ch rm + SLAP');saveaspdf('detrend+badch+slap.pdf');

% spectral filter
z=jf_fftfilter(z,'bands',[.1 .5 13 15]);%[7 9 28 29]
clf;jf_plotERP(z); suptitle('Detrended + bad-ch rm + SLAP + spectral filter');saveaspdf('detrend+badch+slap+specfilt.pdf');

% train classifier
jf_cvtrain(jf_compKernel(z))


% add some ERSP stuff...
