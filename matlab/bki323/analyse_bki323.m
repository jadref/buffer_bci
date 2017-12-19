% This file contains the complete code to train a classifier and compute it's
% performance on a set of subjects and sessions for the individual experiment
% phases and store the summary results at the end.
%
% Terminology:
%  subject -- you participant
%  session -- one time the subject sat down and tried to perform the experiment
%  phase   -- one part of the experiment, e.g. calibration, or neurofeedback.
%             Note:  The BKI323  experiment has the following phases:
%                  calibrate     == calibration phase
%                  epochfeedback == evaluation phase
%                  contfeedback  == neuro-feedback training phase
%
% To use this script you must:
%  1) Setup the data-sets to point to the subject/session information for your analysis
%  2) run it -- possibly changing the analysis pipeline if you want
%  3) Collect the results to perform your statistical tests.
%
% Note: This script only computes classifier performances.  If you wish to
% compute a direct signal strength (e.g. ERD strength), then you should
% modify it to extract the preprocessed data (which is in [channels x
% frequencies x trials] format and stored in the variable Xpp.  This is
% generated and returned when looping over the phases around line 101 below.

                           % setup the paths for the other analysis functions
run ../utilities/initPaths

% experiment config parameters, analysis configuration parameters
trlen_ms=750;  % length of 1 anaysis period.  This is correct for the BKI323 experiment
makePlots=0; % flag if we should make summary ERP/AUC plots
capFile  ='cap_tmsi_mobita_im'; % the file which says where the electrodes are on the head
overridechnms = 1 ; % flag to say to trust the capFile information rather than the save info


% First is the experiment  root directory where all data is stored below --
% this points to the root directory where within which all the subject
% specific data directories lie.
rootdir='bki323';

%Then there is a list of nested cell-array of cell-arrays.  Each entry
%corrosponds to a different subject.  Within this each entry consists firstly
%of the subject directoryname, and then a series of sub-directory names where
%the data for this subject can be found.
%This information is used in combination to find the directory where the data
%for each subject for each session exists.
% E.G. for subject S1, whos 1st session data is in the sub-directory
% `20171106/1345/raw_buffer/0001` and 2nd session is in directory
% `20171113/1345/raw_buffer/0001` we would have:
%  datasets{1} = {'s1'
%                 '20171106/1345/raw_buffer/0001'
%                 '20171106/1345/raw_buffer/0001'}
% N.B. put the different sessions on different lines othersise you may get a
% matrix size error You will need to modify this information to reflect the
% directory structure you have used in your experiment.

% dataset format: cell-array of cell-arrays.  1 sub-cell array per subject.
% First entry is subject ID, rest of the entries are the subject sessions.

% Change these to reflect the directory struture you have used!
datasets{1}={'s1' % first subject directory
             '20171116/0224PM/raw_buffer/0001' % session 1 directory
            };                                
datasets{2}={'s2' % second subject directory
             '20171116/0224PM/raw_buffer/0001' % session 1 directory
            };
% add more subjects/sessions as you have them


                                % process the given data-sets
results={}; % clear the results summary info
for si=1:numel(datasets); % loop over data-sets = subjects  to process
  if( isempty(datasets{si}) ) continue; end;
  subj   =datasets{si}{1};
  for sessi=1:numel(datasets{si})-1; % loop over sessions for this subject
     session =datasets{si}{1+sessi};
     % construct the directory where the raw-save file is found
     sessdir =fullfile(rootdir,subj,session);
     % file name to save the sliced data..
     savefn = fullfile(rootdir,subj,session,sprintf('%s_sliced',subj));
     fprintf('Trying : %s\n',sessdir);
     if ( ~exist(sessdir,'file') ) fprintf('Dir not found, Skipped\n'); continue; end;
              
% 1) Slice the data into 'trials' grouped by the phases that the experiment was run in.
% to get help on what is computed used : help slicePhases
% Basically; this returns an array of structures, 1 element for each phase.
% For each phase this tructure contains the data and trigger events from that
% phase.  This can then be used to train a classifier or analyssi the data..
     [phases,hdr,allevents]=
     slicePhases(sessdir,'phaseStart',{{'calibrate' 'epochfeedback' 'contfeedback'} 'start'},'startSet',{'stimulus.target'},'trlen_ms',trlen_ms);
     if( isempty(phases) )
       fprintf('Warning: no phases found in : %s...\n SKIPPING\n',sessdir);
       continue;
     end
                                % save the sliced data
     fprintf('Saving %d phases to: %s',numel(phases),savefn);
     save(savefn,'phases','hdr','allevents');
     fprintf('done.\n');
     


% 2) Analyse the data, by training on *all* the calibration phases and testing on the rest...
% 2.1) Identify the calibration phases     
     calphasei = find(strcmp({phases.label},'calibrate'));
% combine the information from the calibration phases to make a training set for the classifier.
     data=cat(1,phases(calphasei).data); % combine the data
     devents=cat(1,phases(calphasei).devents); % combine the devents

                       % 2.2) Train an ERSP classifer on the calibration data
% Note: This is the default pre-processing settings as used in the on-line training
% thus the performance should be similar.
% Feel free to change these settings if you want to try different training options
%
     % N.B. pre-processed calibration phase data is output here!
     [clsfr,res,Xpp,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'capFile',capFile,'overridechnms',overridechnms,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','wht','freqband',[6 8 28 30],'width_ms',250,'aveType','abs','visualize',makePlots);     


     if( makePlots ) % save a copy of the visualization plots if wanted
       % Note: Plots saved to the same directory as the data was loaded from
       figure(2); saveaspdf(fullfile(rootdir,subj,session,sprintf('%s_ERP_calibrate',subj)));
       figure(3); saveaspdf(fullfile(rootdir,subj,session,sprintf('%s_AUC_calibrate',subj)));
     end

        % 2.3) Compute the performance of this classifier on the other phases
                                % test on the other phases
     aucphase=[]; % contains the AUC score computed for each phase
     tstphase=[]; % contains the binary classifier performance computed for each phase
     for phasei=[1:numel(phases)];

% apply the pre-processing and trained classifier on the data from this phase
% Note: Xpp = [ nCh x nFreq x nTrl ] contains the pre-processed input data.
%       this may be useful if you want to visualize what the data for this phase looks like.
%
     % N.B. pre-processed data for this phase is output here
       [f,fraw,p,Xpp,clsfr] = buffer_apply_clsfr(phases(phasei).data,clsfr); % predictions
       %map events->clsfr targets, so can compute performance
       y = lab2ind({phases(phasei).devents.value},clsfr.spKey,clsfr.spMx);
       % Compute performance information
       conf    = dv2conf(y,f);          % confusion matrix
       tst     = conf2loss(conf,'bal'); % binary performance
       auc     = dv2auc(y,f);           % auc -scorce

                                % log the performance information:
       if(any(phasei==calphasei)) % Training phase, mark with T yo indicate this in the log
         fprintf('%20s:%2.0f(%2.0f)T \n',phases(phasei).label,tst*100,auc*100); 
         aucphase(phasei)=0; tstphase(phasei)=0;
         continue;  
       end;
       aucphase(phasei)=auc;  tstphase(phasei)=tst;
       fprintf('%20s:%2.0f(%2.0f)  \n',phases(phasei).label,tstphase(phasei)*100,aucphase(phasei)*100);
     end
     meantstphase = sum(tstphase)./(numel(tstphase)-numel(calphasei));
     meanaucphase = sum(aucphase)./(numel(aucphase)-numel(calphasei));
     fprintf('%20s:%2.0f(%2.0f)\n\n','<ave>',meantstphase*100,meanaucphase*100);
           
                                % record the summary results in the results database
                        % results database format: cell array of cell-arrays.
                        % 1 cell array for each session.
                        % Within this format is: subject, session
     % then triples with: phaseName binaryperformance aucscore
     results(end+1,1:2)={subj session };
     for phasei=1:numel(phases); % add per-phase results
       results(end,2+(phasei-1)*3+[1:3])=...
       {phases(phasei).label tstphase(phasei) aucphase(phasei)};
     end;

     
  end % sessions
end % subjects

% save the results database
savefn = fullfile(rootdir,sprintf('results'));
save(savefn,'results');

                                % log summary results to screen
for ri=1:size(results,1);
  fprintf('%s %s\n',results{ri,1},results{ri,2});
  fprintf('       %30s = tstbin (tstauc)\n','session');
  for pi=3:3:size(results,2);
    fprintf('       %30s = %4.2f  (%4.2f)\n',results{ri,pi},results{ri,pi+1},results{ri,pi+2});
  end
  fprintf('\n\n');
end
