run ../../utilities/initPaths
if ( 1 ) 
   dataRootDir = '~/data/bci'; % main directory the data is saved relative to in sub-dirs
   datasets_brainfly_local();
else
   dataRootDir = '/Volumes/Wrkgrp/STD-Donders-ai-BCI_shared'; % main directory the data is saved relative to in sub-dirs
   datasets_brainfly();
end
trlen_ms=750;
label   ='movement'; % generic label for this slice/analysis type
makePlots=0; % flag if we should make summary ERP/AUC plots whilst slicing
analysisType='ersp';  % type of pre-processing / analsysi to do

% get the set of algorithms to run
algorithms_brainfly();
% list of default arguments to always use
% N.B. Basicially this is a standard ERSP analysis setup
default_args={,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[6 8 80 90],'width_ms',250,'aveType','abs'};

% summary results storage.  Format is 2-d cell array.  
% Each row is an algorithm run with 4 columns: {subj session algorithm_label performance}
resultsfn=fullfile(dataRootDir,expt,sprintf('analyse_%s',label));
try % load the previously saved results if possible..
   if ( ~exist('results','var') ) 
      load(resultsfn);
   end
catch
   results=cell(0,4);
end

% run the given analysis
si=1; sessi=3;
for si=1:numel(datasets);
   if ( isempty(datasets{si}) ) continue; end;
  subj   =datasets{si}{1};
  for sessi=1:numel(datasets{si})-1;
     session=datasets{si}{1+sessi};
     saveDir=session;
     if(~isempty(stripFrom))
        tmp=strfind(session,stripFrom);
        if ( ~isempty(tmp) ) saveDir=session(1:tmp-1);  end
     end

     % load the sliced data
     dname = fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_sliced',subj,label));
     if( ~(exist(dname,'file') || exist([dname '.mat'],'file')) )
        warning('Couldnt find sliced data for : %s.  skipping',dname);
        continue;
     end
     fprintf('Loading: %s\n',dname);
     load(dname);
     fprintf('Loaded %d events\n',numel(devents));
     if ( numel(devents)==0 ) continue; end;

     % run the set of algorithms to test
     for ai=1:numel(algorithms)
        alg=algorithms{ai}{1};

        % check if already been run
        mi=strcmp(subj,results(:,1)) &strcmp(saveDir,results(:,2)) &strcmp(alg,results(:,3));
        if( any(mi) ) 
           fprintf('Skipping prev run analysis: %s\n',alg);
           continue;
        end

        fprintf('Trying: %s %s\n',subj,alg);
        try; % run in catch so 1 bad alg doesn't stop everything

           if( strcmp(lower(analysisType),'ersp') )
              [clsfr,res]=buffer_train_ersp_clsfr(data,devents,hdr,default_args{:},algorithms{ai}{2:end},'visualize',0);
           elseif( strcmp(lower(analysisType),'erp') )
              [clsfr,res]=buffer_train_erp_clsfr(data,devents,hdr,default_args{:},algorithms{ai}{2:end},'visualize',0);
           else
              error('Unrecognised analysis type: %s',analysisType)
           end% save the summary results
           results(end+1,:)={subj saveDir alg res.opt.tst};
           fprintf('%d) %s %s %s = %f\n',ai,results{end,:});

        catch;
           err=lasterror, err.message, err.stack(1)
           fprintf('Error in : %d=%s,    IGNORED\n',ai,alg);
        end

     end

     % save the updated summary results
     results=sortrows(results,1:3); % canonical order... subj, session, alg
     fprintf('Saving results to : %s\n',resultsfn);
     save(resultsfn,'results');   
     fid=fopen([resultsfn '.txt'],'w'); rr=results'; fprintf(fid,'%8s,\t%30s,\t%40s,\t%4.2f\n',rr{:}); fclose(fid);


     % ----------- generate summary plots ------------------
     if( makePlots ) 
        % also make summary plots
        if( strcmp(lower(analysisType),'ersp') )
           [clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[6 8 80 90],'width_ms',250,'aveType','abs','classify',0,'visualize',1);
        elseif( strcmp(lower(analysisType),'erp') )
           [clsfr,res,X,Y]=buffer_train_erp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[.1 .5 12 14],'classify',0,'visualize',1);
        end
        % save plots
        figure(1); saveaspdf(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_%s',subj,label,analysisType)));
        figure(2); saveaspdf(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_%s_AUC',subj,label,analysisType)));
     end
  end % sessions
end % subjects
% show the final results set
results

% some simple algorithm summary info
algs=unique(results(:,3));
for ai=1:numel(algs);
   mi=strcmp(results(:,3),algs{ai});
   resai = [results{mi,4}];
   fprintf('%2d) %40s = %5.3f (%5.3f)\n',ai,algs{ai},mean(resai),std(resai));
end


% per-subject summary / also per-week
algs=unique(results(:,3));
subjs=unique(results(:,1));
for ai=1:numel(algs);
   alg=algs{ai};
   fprintf('\n\nAlg: %s\n',alg);
   for si=1:numel(subjs);
      mi = strcmp(results(:,1),subjs{si}) & strcmp(results(:,3),alg);
      resai = [results{mi,4}];
      fprintf('%2d) %10s = %5.3f (%5.3f) ',si,subjs{si},mean(resai),std(resai));
      if( any(strcmp(results(mi,2),'Week')) )
         fprintf(' / Wk = ');
         for wki=1:6;
            mi = strcmp(results(:,1),subjs{si}) & ...
                 strcmp(results(:,3),alg) & ...
                 (strncmp(results(:,2),sprintf('Week%d',wki),5) | strncmp(results(:,2),sprintf('Week %d',wki),6));
            if( any(mi) )  fprintf('%5.2f  ',mean([results{mi,4}]));
            else           fprintf(' -     '); 
            end
         end
      else
         for si=find(mi);
            fprintf('%5.2f  ',results{si,4});
         end
      end
      fprintf('\n');
   end
   fprintf('---\n');
   mi = strcmp(results(:,3),alg);
   resai = [results{mi,4}];
   fprintf('ave %10s = %5.3f (%5.3f) ','ave',mean(resai),std(resai));
   fprintf(' / Wk = ');
   for wki=1:6;
      mi = strcmp(results(:,3),alg) & ...
           (strncmp(results(:,2),sprintf('Week%d',wki),5) | strncmp(results(:,2),sprintf('Week %d',wki),6));
      if( any(mi) )  fprintf('%5.2f  ',mean([results{mi,4}]));
      else           fprintf(' -     '); 
      end
   end
   fprintf('\n');
end
