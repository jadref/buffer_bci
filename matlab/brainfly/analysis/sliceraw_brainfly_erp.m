run ../../utilities/initPaths
if ( 0 ) 
   dataRootDir = '~/data/bci'; % main directory the data is saved relative to in sub-dirs
   datasets_brainfly_local();
else
   dataRootDir = '/Volumes/Wrkgrp/STD-Donders-ai-BCI_shared'; % main directory the data is saved relative to in sub-dirs
   datasets_brainfly();
end

trlen_ms=750;
label   ='p300'; % generic label for this slice/analysis type
makePlots=0; % flag if we should make summary ERP/AUC plots whilst slicing

                                % slice data
si=1; sessi=3;
for si=1:numel(datasets);
  if( isempty(datasets{si}) ) continue; end;
  subj   =datasets{si}{1};
  for sessi=1:numel(datasets{si})-1;
     session=datasets{si}{1+sessi};
     saveDir=session;
     if(~isempty(stripFrom))
        tmp=strfind(session,stripFrom);
        if ( ~isempty(tmp) ) saveDir=session(1:tmp-1);  end
     end
     sessdir=fullfile(dataRootDir,expt,subj,session);
     savefn = fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_sliced',subj,label));

     if( exist(savefn,'file') ||  exist([savefn '.mat'],'file') ) %don't re-slice already done
        fprintf('Skipping already sliced file: %s\n\n',savefn);
        continue;
     end
     
     % do the actual slicing now
     fprintf('Trying : %s\n',sessdir);
     try;
        [data,devents,hdr,allevents]=sliceraw(sessdir,'startSet',{'stimulus.tgtFlash'},'trlen_ms',trlen_ms,'offset_ms',[0 0]);
        if( numel(data)>0 ) 
           % save the sliced data
           fprintf('Saving to: %s',savefn);
           save(savefn,'data','devents','hdr','allevents');
           fprintf('done\n');
        end
     catch
        le=lasterror, le.stack(1)
        fprintf('Couldnt slice: %s,  IGNORED\n',sessdir)
     end

     if( makePlots ) 
        % also make summary plots
        [clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[6 8 80 90],'width_ms',250,'aveType','abs','classify',0,'visualize',1);
        % save plots
        figure(1); saveaspdf(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_ERP',subj,label)));
        figure(2); saveaspdf(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_AUC',subj,label)));
     end
  end % sessions
end % subjects
