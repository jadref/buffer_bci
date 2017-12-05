run ../../utilities/initPaths
if ( 0 ) 
   dataRootDir = '~/data/bci'; % main directory the data is saved relative to in sub-dirs
   datasets_brainfly_local;
elseif ( 0 ) 
   dataRootDir = '/Volumes/Wrkgrp/STD-Donders-ai-BCI_shared'; % main directory the data is saved relative to in sub-dirs
   datasets_brainfly;
else
   dataRootDir = '~/data/bci'; % main directory the data is saved relative to in sub-dirs
   datasets_brainfly_flight;  
end

trlen_ms=750;
fs      =250;
label   ='p300'; % generic label for this slice/analysis type
makePlots=0; % flag if we should make summary ERP/AUC plots whilst slicing
sliceInPhases=1; % slice preserving phase info
sliceAll=1; % slice in one big dataset

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

     if( sliceAll )
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
        [clsfr,res,X,Y]=buffer_train_erp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[6 8 80 90],'width_ms',250,'aveType','abs','classify',0,'visualize',1);
        % save plots
        figure(1); saveaspdf(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_ERP',subj,label)));
        figure(2); saveaspdf(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_AUC',subj,label)));
     end
     end

     
     if( sliceInPhases ) 
     savefn=sprintf('%s_phases',savefn);
     if( exist(savefn,'file') ||  exist([savefn '.mat'],'file') ) %don't re-slice already done
        fprintf('Skipping already sliced file: %s\n',savefn);
        continue;
     end
     try;
                                     % now slice into phases
        [phases,hdr,allevents]=slicePhases(sessdir,'phaseStart','brainfly_p3','startSet',{'stimulus.tgtFlash'},'trlen_ms',trlen_ms,'offset_ms',[0 0]);

        fprintf('Saving %d phases to: %s',numel(phases),savefn);
        save(savefn,'phases','hdr','allevents');
        fprintf('done.\n');

        if( makePlots ) 
                                % also make summary plots
          for phi=1:numel(phases);
            data=phases(phi).data; devents=phases(phi).devents;
          [clsfr,res,X,Y]=buffer_train_erp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[0 .1 20 30],'classify',0,'visualize',1);
        % save plots
          figure(1); saveaspdf(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_ERP_%s%d',subj,label,phase(phi).label,phi)));
          figure(2); saveaspdf(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_AUC',subj,label,phase(phi).label,phi)));
          end
          end
     catch
        le=lasterror, fprintf('%s: %s:%d\n',le.message,le.stack(1).file,le.stack(1).line)
        fprintf('Couldnt slice: %s,  IGNORED\n',sessdir)
     end
     end
     
  end % sessions
end % subjects
