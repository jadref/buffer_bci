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
maxtrlen_ms=5000;
fs      =250;
label   ='movement'; % generic label for this slice/analysis type
makePlots=1; % flag if we should make summary ERP/AUC plots whilst slicing
sliceInPhases=1; % slice preserving phase info
sliceAll=0; % slice in one big dataset

% set of sourec->dest target class mappings to ensure all classes have the same labels
subistuteVals={'1 LH ' '2 LH';
               '2 RH ' '1 RH';
               '2 LH ' '2 LH';
               '1 RH ' '1 RH';
               'LH'   '2 LH';
               'RH'   '1 RH'};

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
     if ( ~exist(sessdir,'file') ) fprintf('Dir not found, Skipped\n'); continue; end;
         
     
     % do the actual slicing now
     if( sliceAll )
     if( exist(savefn,'file') ||  exist([savefn '.mat'],'file') ) %don't re-slice already done
        fprintf('Skipping already sliced file: %s\n',savefn);
        continue;
     end
     try;
        [data,devents,hdr,allevents]=sliceraw(sessdir,'startSet',{'stimulus.target'},'trlen_ms',trlen_ms,'offset_ms',[0 0]);

        % BODGE: fix-up the labels to remove annoying training whitespace
        for ei=1:numel(devents);
           val = devents(ei).value; 
           for ri=1:size(subistuteVals,1);
              if strcmp(val,subistuteVals{ri,1}) val = subistuteVals{ri,2}; end
           end
           devents(ei).value = val;
        end

        % save the sliced data
        fprintf('Saving to: %s',savefn);
        save(savefn,'data','devents','hdr','allevents');
        fprintf('done\n');        


        if( makePlots ) 
                                % also make summary plots
          [clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[6 8 80 90],'width_ms',250,'aveType','abs','classify',0,'visualize',1);
        % save plots
          figure(2); saveaspdf(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_ERP',subj,label)));
          figure(3); saveaspdf(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_AUC',subj,label)));
        end        


     catch
        le=lasterror, le.stack(1)
        fprintf('Couldnt slice: %s,  IGNORED',sessdir)
     end
     end

     if( sliceInPhases ) 
     savefn=sprintf('%s_phases',savefn);
     if( exist(savefn,'file') ||  exist([savefn '.mat'],'file') ) %don't re-slice already done
        fprintf('Skipping already sliced file: %s\n',savefn);
        %continue;
     end
     try;
                                     % now slice into phases
%        [phases,hdr,allevents]=slicePhases(sessdir,'phaseStart',{{'calibrate' 'epochfeedback' 'contfeedback' 'brainfly'} 'start'},'startSet',{'stimulus.target'},'trlen_ms',trlen_ms,'offset_ms',[0 0]);
       trlen_samp   = ceil(trlen_ms*fs/1000);
       maxtrlen_samp= ceil(maxtrlen_ms*fs/1000);
        [phases,hdr,allevents]=slicePhases(sessdir,'phaseStart',{{'calibrate' 'epochfeedback' 'contfeedback' 'brainfly'} 'start'},'startSet',@(devents) upsampleEvents(devents,{'stimulus.target'},maxtrlen_samp,trlen_samp,trlen_samp),'trlen_ms',trlen_ms,'offset_ms',[0 0]);

            % BODGE: fix-up the labels to remove annoying training whitespace
        for phi=1:numel(phases);
           devents=phases(phi).devents;
           for ei=1:numel(devents);
              val = devents(ei).value; 
              for ri=1:size(subistuteVals,1);
                 if strcmp(val,subistuteVals{ri,1}) 
                    val = subistuteVals{ri,2}; 
                 end
              end
              devents(ei).value = val;
           end
           phases(phi).devents=devents;
        end
        fprintf('Saving %d phases to: %s',numel(phases),savefn);
        save(savefn,'phases','hdr','allevents');
        fprintf('done.\n');

        if( makePlots ) 
                                % also make summary plots
          for phi=1:numel(phases);
            data=phases(phi).data; devents=phases(phi).devents;
          [clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[6 8 80 90],'width_ms',250,'aveType','abs','classify',0,'visualize',1);
        % save plots
          figure(2); tmpfn=fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_ERP_%s%d',subj,label,phases(phi).label,phi)); fprintf('Saving fig(2) to: %s\n',tmpfn); saveaspdf(tmpfn);
          figure(3); tmpfn=fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_AUC_%s%d',subj,label,phases(phi).label,phi)); fprintf('Saving fig(3) to: %s\n',tmpfn); saveaspdf(tmpfn);
          end
        end        


     catch
        le=lasterror, fprintf('%s: %s:%d\n',le.message,le.stack(1).file,le.stack(1).line)
        fprintf('Couldnt slice: %s,  IGNORED\n',sessdir)
     end
     end

     
  end % sessions
end % subjects
