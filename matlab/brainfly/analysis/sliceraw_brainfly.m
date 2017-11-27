run ../../utilities/initPaths
if ( 1 ) 
   dataRootDir = '~/data/bci'; % main directory the data is saved relative to in sub-dirs
   datasets_brainfly_local;
else
   dataRootDir = '/Volumes/Wrkgrp/STD-Donders-ai-BCI_shared'; % main directory the data is saved relative to in sub-dirs
   datasets_brainfly;
end

trlen_ms=750;
label   ='movement'; % generic label for this slice/analysis type
makePlots=1; % flag if we should make summary ERP/AUC plots whilst slicing
sliceInPhases=1; % slice preserving phase info
sliceAll=0; % slice in one big dataset

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
     fprintf('Trying : %s\n',sessdir);

     if( exist(savefn,'file') ||  exist([savefn '.mat'],'file') ) %don't re-slice already done
        fprintf('Skipping already sliced file: %s\n',savefn);
        continue;
     end
     
     % do the actual slicing now
     if( sliceAll )
     try;
        [data,devents,hdr,allevents]=sliceraw(sessdir,'startSet',{'stimulus.target'},'trlen_ms',trlen_ms,'offset_ms',[0 0]);
        % save the sliced data
        fprintf('Saving to: %s',savefn);
        save(savefn,'data','devents','hdr','allevents');
        fprintf('done\n');        
     catch
        le=lasterror, le.stack(1)
        fprintf('Couldnt slice: %s,  IGNORED',sessdir)
     end
     end

     if( sliceInPhases ) 
     try;
                                     % now slice into phases
        [phases,hdr,allevents]=slicePhases(sessdir,'startSet',{'stimulus.target'},'trlen_ms',trlen_ms,'offset_ms',[0 0]);
        fn=sprintf('%s_phases',savefn);
        fprintf('Saving %d phases to: %s',numel(phases),fn);
        save(fn,'phases','hdr','allevents');
        fprintf('done.\n');
     catch
        le=lasterror, fprintf('%s: %s:%d\n',le.message,le.stack(1).file,le.stack(1).line)
        fprintf('Couldnt slice: %s,  IGNORED\n',sessdir)
     end
     end

     
  end % sessions
end % subjects
