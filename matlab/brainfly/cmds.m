z=jf_load('own_experiments/motor_imagery/cybathalon/imtest','S10','am_trn','170612/1330');
train_ersp_clsfr(z.X,z.Y,'capFile','cap_im_dense_subset.txt','overridechnms',0,'ch_names',z.di(1).vals,'fs',z.di(2).info.fs,'spatialfilter','car+wht','detrend',1,'freqband',[8 28],'objFn','mlr_cg','binsp',0,'spMx','1vR')


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
<<<<<<< HEAD
=======
'171003/0353PM/raw_buffer/0001'
>>>>>>> master
}};

si=1; sessi=3;
% slice data
sessdir=fullfile('~/data/bci',expt,subj{si},sessions{si}{sessi});
[data,devents,hdr,allevents]=sliceraw(sessdir,'startSet',{'stimulus.target'},'trlen_ms',750,'offset_ms',[0 0]);

                                % summary plots
si=1; sessi=2;  avePow=[];
for sessi=2:numel(sessions{si});

                                % slice data
  sessdir=fullfile('~/data/bci',expt,subj{si},sessions{si}{sessi});
  [data,devents,hdr,allevents]=sliceraw(sessdir,'startSet',{'stimulus.target'},'trlen_ms',750,'offset_ms',[0 0]);

  if ( 0 )                               % pre-process
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[6 8 80 90],'width_ms',250,'aveType','abs','classify',0,'visualize',0);
  avePow(:,:,sessi) = mean(X,3);
  end

  if( 1 ) 
  % train classifier
<<<<<<< HEAD
  [clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',1,'badchrm',1,'detrend',1,'spatialfilter','wht','freqband',[6 8 28 30],'width_ms',250,'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);
  %  [clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',1,'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',50},'freqband',[6 8 28 30],'width_ms',250,'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);
=======
  % global wht
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','wht','freqband',[6 8 28 30],'width_ms',250,'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',3,'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',50},'freqband',[6 8 38 30],'width_ms',250,'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht + adaptive EOG rm
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'filtPipeline' {'artChRegress',[],{'AF7' 'Fp1' 'Fpz' 'Fp2' 'AF8'},'covFilt',5} {'adaptWhitenFilt','covFilt',50}},'freqband',[6 8 28 30],'width_ms',250,'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht + adaptive EMG rm
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'filtPipeline' {'rmEMGFilt','covFilt',50,'minCorr',.3} {'adaptWhitenFilt','covFilt',50}},'freqband',[6 8 28 30],'width_ms',250,'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht + feature-filt-fn
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',50},'freqband',[6 8 28 30],'width_ms',250,'featFiltFn',{'biasFilt' 500},'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adaptive wht + feature-std-fn
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',50},'freqband',[6 8 70 78],'width_ms',250,'featFiltFn',{'stdFilt' 50},'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adapt wht + EOGrm + EMGRm + feat-filt
  [clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'filtPipeline' {'rmEMGFilt','covFilt',500} {'artChRegress',[],{'AF7' 'Fp1' 'Fpz' 'Fp2' 'AF8'},'covFilt',500} {'adaptWhitenFilt','covFilt',50}},'freqband',{[6 8 44 46] [54 56 70 78]},'width_ms',250,'featFiltFn',{'stdFilt' 50},'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

  % adapt wht + EMGRm + feat-filt
  %[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'filtPipeline' {'rmEMGFilt','covFilt',500} {'adaptWhitenFilt','covFilt',50}},'freqband',[6 8 70 78],'width_ms',250,'featFiltFn',{'stdFilt' 50},'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

>>>>>>> master
  end

  clsfrs(sessi)=clsfr; ress(sessi)=res;
  perf(:,sessi)=res.opt.tst;
end
fprintf('\nperf=[%s]  <%4.3f>\n',sprintf('%5.3f  ',perf(1,:)),mean(perf(1,:),2));

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
