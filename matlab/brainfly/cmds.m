%z=jf_load('own_experiments/motor_imagery/cybathalon/imtest','S10','am_trn','170612/1330');
%train_ersp_clsfr(z.X,z.Y,'capFile','cap_im_dense_subset.txt','overridechnms',0,'ch_names',z.di(1).vals,'fs',z.di(2).info.fs,'spatialfilter','car+wht','detrend',1,'freqband',[8 28],'objFn','mlr_cg','binsp',0,'spMx','1vR')


                                % buffer_bci commands only...
run ../utilities/initPaths
expt='own_experiments/motor_imagery/brainfly';
subj={'s1'};
sessions={{ 
'0606di/1308/raw_buffer/0002'
'0907do/1235/raw_buffer/0001'
'0911ma/1002/raw_buffer/0001'
'0912di/1624/raw_buffer/0001'
'170925/1015AM/raw_buffer/0001'
'170926/0424PM/raw_buffer/0001'
'171002/1038AM/raw_buffer/0001'
'171003/0353PM/raw_buffer/0001'
'171009/1055AM/raw_buffer/0001'
'171023/1103AM/raw_buffer/0001'
'171030/1015AM/raw_buffer/0001'
'171031/0345PM/raw_buffer/0001'
}};

si=1; sessi=3;
% slice data
sessdir=fullfile('~/data/bci',expt,subj{si},sessions{si}{sessi});
[data,devents,hdr,allevents]=sliceraw(sessdir,'startSet',{'stimulus.target'},'trlen_ms',750,'offset_ms',[0 0]);

trlen_ms=750
ms2samp    = @(x) x*hdr.Fs/1000
s2samp    = @(x) x*hdr.Fs
calls2samp = @(x) x*hdr.Fs*1000/trlen_ms
s2calls    = @(x) x*1000./trlen_ms

                                % summary plots
si=1; sessi=2;  avePow=[]; perf=[]; clear clsfrs resss;

for sessi=2:numel(sessions{si});

                                % slice data
  sessdir=fullfile('~/data/bci',expt,subj{si},sessions{si}{sessi});
  [data,devents,hdr,allevents]=sliceraw(sessdir,'startSet',{'stimulus.target'},'trlen_ms',trlen_ms,'offset_ms',[0 0]);

  % tidy up the class labels if needed..
  for ei=1:numel(devents);
     if( strcmp(devents(ei).value,'LH') ) devents(ei).value='2 LH ';
     elseif ( strcmp(devents(ei).value,'RH') ) devents(ei).value='1 RH ';
     end
  end

  if ( 0 )                               % pre-process
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[6 8 80 90],'width_ms',250,'aveType','abs','classify',0,'visualize',0);
  avePow(:,:,sessi) = mean(X,3);
  end

  if( 1 ) 
  % train classifier
  % global wht
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','wht','freqband',[6 8 28 30],'width_ms',250,'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(8)},'freqband',[6 8 38 30],'width_ms',250,'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht + prefilt
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',0,'preFiltFn',{'filterFilt' 'filter' {'butter' 3 .2}},'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(70)},'freqband',[6 8 38 30],'width_ms',250,'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht + filterbank + hf
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',0,'preFiltFn',{'filterFilt' 'filter' {'butter' 3 .2}},'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(70)},'freqband',[6:4:32 36 54;10:4:36 48 78],'width_ms',250,'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);


  % adaptive wht + adaptive EOG rm
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'filtPipeline' {'artChRegress',[],{'AF7' 'Fp1' 'Fpz' 'Fp2' 'AF8'},'covFilt',5} {'adaptWhitenFilt','covFilt',s2samp(70)}},'freqband',[6 8 28 30],'width_ms',250,'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht + adaptive EMG rm
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'filtPipeline' {'rmEMGFilt','covFilt',s2samp(70),'minCorr',.3} {'adaptWhitenFilt','covFilt',s2samp(70)}},'freqband',[6 8 28 30],'width_ms',250,'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht + biasFilt
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(70)},'freqband',[6 8 28 30],'width_ms',250,'featFiltFn',{'biasFilt' s2calls(70)},'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht + feature-std-fn
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(70)},'freqband',[6 8 28 30],'width_ms',250,'featFiltFn',{'stdFilt' s2calls(35)},'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht + feature-rel-baseline
  [clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(70)},'freqband',[6 8 28 30],'width_ms',250,'featFiltFn',{'relFilt' s2calls(35)},'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht + biasPredFilt
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(70)},'freqband',[6 8 28 30],'width_ms',250,'predFiltFn',{'biasFilt' s2calls(700)},'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht + timefeat
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(70)},'freqband',[6 8 28 30],'width_ms',250,'timefeat',1,'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht + temporal embedding
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(70)},'freqband',[6 8 28 30],'width_ms',250,'featFiltFn',{'temporalEmbeddingFilt' [1 25]},'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adapt wht + EOGrm + EMGRm + feat-filt
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'filtPipeline' {'rmEMGFilt','covFilt',s2samp(700)} {'artChRegress',[],{'AF7' 'Fp1' 'Fpz' 'Fp2' 'AF8'},'covFilt',s2samp(70)0} {'adaptWhitenFilt','covFilt',s2samp(70)}},'freqband',[6 8 28 30],'width_ms',250,'featFiltFn',{'stdFilt' 500},'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adapt wht + EOGrm + EMGRm + feat-filt + high-freq
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'filtPipeline' {'rmEMGFilt','covFilt',s2samp(700)} {'artChRegress',[],{'AF7' 'Fp1' 'Fpz' 'Fp2' 'AF8'},'covFilt',s2samp(70)0} {'adaptWhitenFilt','covFilt',s2samp(70)}},'freqband',{[6 8 44 46] [54 56 70 78]},'width_ms',250,'featFiltFn',{'stdFilt' 50},'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adapt wht + EMGRm + feat-filt
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'filtPipeline' {'rmEMGFilt','covFilt',s2samp(700)} {'adaptWhitenFilt','covFilt',s2samp(70)}},'freqband',[6 8 70 78],'width_ms',250,'featFiltFn',{'stdFilt' 50},'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  end

  clsfrs(sessi)=clsfr; ress(sessi)=res;
  perf(:,sessi)=res.opt.tst;
end
fprintf('\nperf=[%s]  <%4.3f>\n',sprintf('%5.3f  ',perf(1,:)),mean(perf(1,:),2));

return;

freqs=8+((0:size(avePow,2)-1)*1000./250);
clf;image3d(avePow,1,'disptype','plot','xvals',hdr.label(1:size(X,1)),'yvals',freqs,'zVals',sessions{si});

% show the average power per frequency
[freqs;sum(sum(avePow,1),3)]




for sessi=1:size(avePow,3);
   apsi=avePow(:,:,sessi);
   npsi=apsi(:,freqs>46 & freqs<54);
   fprintf('%10s perf=[%s] 50Hz=%6.1e (%5.0f db) NF=%3.2f\n',...
           sessions{si}{sessi}(1:find(sessions{si}{sessi}=='/')-1),...
           sprintf('%5.3f,',perf(:,sessi)), ...
           mean(npsi(:)),20*log(mean(npsi(:))),sum(npsi(:))./sum(apsi(:)));
end
fprintf('%10s perf=[%s]\n','ave',sprintf('%5.3f,',mean(perf,2)));
