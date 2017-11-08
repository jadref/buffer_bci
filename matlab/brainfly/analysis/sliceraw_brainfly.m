run ../../utilities/initPaths
datasets_brainfly();
dataRootDir = '~/data/bci'; % main directory the data is saved relative to in sub-dirs
trlen_ms=750;
label   ='movement'; % generic label for this slice/analysis type
makePlots=1; % flag if we should make summary ERP/AUC plots whilst slicing

                                % slice data
si=1; sessi=3;
for si=1:numel(datasets);
  subj   =datasets{si}{1};
  session=datasets{si}{1+sessi};
  saveDir=session;
  if(~isempty(stripFrom))
    tmp=strfind(stripFrom,session);
    if ( ~isempty(tmp) ) saveDir=session(1:tmp);  end
  end
  sessdir=fullfile(dataRootDir,expt,subj,session);
  [data,devents,hdr,allevents]=sliceraw(sessdir,'startSet',{'stimulus.target'},'trlen_ms',trlen_ms,'offset_ms',[0 0]);
                                % save the sliced data
  save(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_sliced',subj,label)),'data','devents','hdr','allevents');

  if( makePlots ) 
                                % also make summary plots
    [clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[6 8 80 90],'width_ms',250,'aveType','abs','classify',0,'visualize',1);
                                % save plots
    figure(1); saveaspdf(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_ERP',subj,label)));
    figure(2); saveaspdf(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_AUC',subj,label)));
  end
  
end
