run ../../utilities/initPaths
if ( 0 ) 
   dataRootDir = '~/data/bci'; % main directory the data is saved relative to in sub-dirs
   datasets_brainfly_local;
   postfix='_local';
elseif ( 0 ) 
   dataRootDir = '/Volumes/Wrkgrp/STD-Donders-ai-BCI_shared'; % main directory the data is saved relative to in sub-dirs
   datasets_brainfly;
   postfix='';
else
   dataRootDir = '~/data/bci'; % main directory the data is saved relative to in sub-dirs
   datasets_brainfly_flight;
   postfix='_flight';
end
trlen_ms=750;
label   ='movement_phases'; % generic label for this slice/analysis type
makePlots=1; % flag if we should make summary ERP/AUC plots whilst slicing
analysisType='ersp';  % type of pre-processing / analsysi to do
nsessions = 3;
trnPhases = {'calibrate' 'contfeedback'};
ntrn      = 3;
postfix   = sprintf('%s_trn%d',postfix,ntrn);


% get the set of algorithms to run
algorithms_brainfly;
% list of default arguments to always use
% N.B. Basicially this is a standard ERSP analysis setup
default_args={,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[6 8 28 30],'width_ms',250,'aveType','abs'};

% summary results storage.  Format is 2-d cell array.  
% Each row is an algorithm run with 4 columns: {subj session algorithm_label performance}
resultsfn=fullfile(dataRootDir,expt,sprintf('analyse_%s%s',label,postfix));
if ( ~exist('results','var') ) 
  try % load the previously saved results if possible..
    load(resultsfn);
  catch
    results=cell(0,4);
  end
elseif( isempty(results) ) 
  results=cell(0,4);
end

% run the given analysis
si=1; sessi=3;
for si=4:numel(datasets);
   if ( isempty(datasets{si}) ) continue; end;
  subj   =datasets{si}{1};
  for sessi=1:nsessions:numel(datasets{si})-1;
    allphases={};
    for ssi=1:nsessions;
      if( sessi+ssi > numel(datasets{si}) ) break; end;
     session=datasets{si}{sessi+ssi};
     saveDir=session;
     if(~isempty(stripFrom))
        tmp=strfind(session,stripFrom);
        if ( ~isempty(tmp) ) saveDir=session(1:tmp-1);  end
     end

     % load the sliced data
     dname = fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_sliced_phases',subj,label(1:find(label=='_',1)-1)));
     if( ~(exist(dname,'file') || exist([dname '.mat'],'file')) )
        warning('Couldnt find sliced data for : %s.  skipping',dname);
        continue;
     end
     fprintf('Loading: %s\n',dname);
     load(dname);
     allphases{ssi}=phases;
     
     fprintf('Loaded %d phases\n',numel(phases));
    end
    phases=cat(2,allphases{:});

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
        %try; % run in catch so 1 bad alg doesn't stop everything

          % train on the calibrate phase & test on the rest
        calphasei = false(numel(phases),1);
        for phi=1:numel(phases);
          calphasei(phi)= calphasei(phi) |  any(strcmp(phases(phi).label,trnPhases));
        end;
          if( ~any(calphasei) )
            calphasei=1;
          else
            calphasei=find(calphasei); calphasei=calphasei(1:min(end,ntrn));
          end
          calphase=phases(calphasei);
          data=cat(1,phases(calphasei).data);
          devents=cat(1,phases(calphasei).devents);
          fprintf('Training on: %s,  %d events\n',phases(calphasei(1)).label,numel(devents));
          if( strcmp(lower(analysisType),'ersp') )
              [clsfr,res]=buffer_train_ersp_clsfr(data,devents,hdr,default_args{:},algorithms{ai}{2:end},'visualize',makePlots);
           elseif( strcmp(lower(analysisType),'erp') )
              [clsfr,res]=buffer_train_erp_clsfr(data,devents,hdr,default_args{:},algorithms{ai}{2:end},'visualize',makePlots);
           else
              error('Unrecognised analysis type: %s',analysisType)
          end% save the summary results
          if( makePlots )
                    figure(2); saveaspdf(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_%s_ERP%s',subj,label,alg,postfix)));
                    figure(3); saveaspdf(fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_%s_AUC%s',subj,label,alg,postfix)));
          end
          
                                % test on the other phases
           aucphase=[]; tstphase=[];
           for phasei=[1:numel(phases)];
             d=phases(phasei);
             % apply the trained classifier
             if( 1 ) % propogate updated clasifier between phases 
                oclsfr=clsfr;
                [f,fraw,p,Xpp,clsfr] = buffer_apply_clsfr(d.data,clsfr); % predictions
             else
                f = buffer_apply_clsfr(d.data,clsfr);
             end
             y = lab2ind({d.devents.value},clsfr.spKey,clsfr.spMx); %map events->clsfr targets
             conf    = dv2conf(y,f); % confusion matrix
             tst     = conf2loss(conf,'bal'); % performance
             auc     = dv2auc(y,f); % auc -scor
             if(any(phasei==calphasei));
               fprintf('%20s:%2.0f(%2.0f)T \n',d.label,tst*100,auc*100); 
               aucsess(phasei)=0; tstsess(phasei)=0;
               continue;  
             end;
             aucphase(phasei)=auc;  tstphase(phasei)=tst;
             fprintf('%20s:%2.0f(%2.0f)  \n',d.label,tstphase(phasei)*100,aucphase(phasei)*100);
           end
           meantstphase = sum(tstphase)./(numel(tstphase)-numel(calphasei));
           meanaucphase = sum(aucphase)./(numel(aucphase)-numel(calphasei));
           fprintf('%20s:%2.0f(%2.0f)\n\n','<ave>',meantstphase*100,meanaucphase*100);
           
           % record the summary results
           results(end+1,1:5)={subj saveDir alg mean(tstphase) mean(aucphase)};
           for phasei=1:numel(phases); % add per-phase results
             results(end,5+(phasei-1)*3+[1:3])=...
                {phases(phasei).label tstphase(phasei) aucphase(phasei)};
           end;
           %results(end,:)
           
        %catch;
        %   err=lasterror, err.message, err.stack(1)
        %   fprintf('Error in : %d=%s,    IGNORED\n',ai,alg);
        %end

     end

     % save the updated summary results
     results=sortrows(results,1:3); % canonical order... subj, session, alg
     fprintf('Saving results to : %s\n',resultsfn);
     save(resultsfn,'results');   
     fid=fopen([resultsfn '.txt'],'w');
     for ri=1:size(results,1);
       fprintf(fid,'%8s,\t%30s,\t%40s,\t',results{ri,1:3});
       fprintf(fid,'%20s,\t%4.2f,\t%4.3f',results{ri,4:end});
       fprintf(fid,'\n');
     end
     fclose(fid);

  end % sessions
end % subjects
% show the final results set
%results

for ri=1:size(results,1);
  fprintf('%8s,\t%30s,\t%40s,\t',results{ri,1:3});
  fprintf('        %20s,\t%4.2f,\t%4.3f',results{ri,4:end});
  fprintf('\n');
end

% some simple algorithm summary info
algs=unique(results(:,3));
for ai=1:numel(algs);
   mi=strcmp(results(:,3),algs{ai});
   resai = [[results{mi,4}]' [results{mi,5}]'];
   fprintf('%2d) %40s = %5.3f (%5.3f)\n',ai,algs{ai},mean(resai,1));
end


% per-subject summary / also per-week
algs=unique(results(:,3));
subjs=unique(results(:,1));
for ai=1:numel(algs);
   alg=algs{ai};
   fprintf('\n\nAlg: %s\n',alg);
   for si=1:numel(subjs);
      mi = strcmp(results(:,1),subjs{si}) & strcmp(results(:,3),alg);
      resai = [[results{mi,4}]' [results{mi,5}]'];
      fprintf('%2d) %10s = %5.3f (%5.3f) ',si,subjs{si},mean(resai,1));
      for si=find(mi);
         fprintf('%5.2f  ',results{si,4});
      end
      fprintf('\n');
   end
   fprintf('---\n');
   mi = strcmp(results(:,3),alg);
   resai = [[results{mi,4}]' [results{mi,5}]'];
   fprintf('ave %10s = %5.3f (%5.3f) ','ave',mean(resai,1));
   fprintf('\n');
end


printphases={'contfeedback','brainfly'};
ai=1;si=1;mii=1;ppi=1;
for ai=1:numel(algs);
   alg=algs{ai};
   fprintf('\n\nAlg: %s\n',alg);
   for si=1:numel(subjs);
      mi = find(strcmp(results(:,1),subjs{si}) & strcmp(results(:,3),alg));
      ressubj=zeros(2,numel(mi),numel(printphases));
      for mii=1:numel(mi); % loop over sesions for this subj+alg
         sas=mi(mii);
         ressas = results(sas,:);
         fprintf('%7s %20s | ',ressas{1},ressas{2});
         for ppi=1:numel(printphases); % loop over phases for this session
            pp    = find(strcmp(ressas,printphases{ppi}));
            if( isempty(pp) ) continue; end;
            resai = [mean([ressas{pp+1}]) mean([ressas{pp+2}])];
            fprintf(' %15s %4.2f (%4.2f) \t',printphases{ppi},resai);
            ressubj(:,mii,ppi)=resai; % record cross-session summary
         end
         fprintf('\n');         
      end
      fprintf('---\n');         
      fprintf('%7s %20s | ',ressas{1},'<ave>');
      for ppi=1:numel(printphases); % loop over phases for this session
         fprintf(' %15s %4.2f (%4.2f) \t',printphases{ppi},sum(ressubj(:,:,ppi),2)./sum(ressubj(:,:,ppi)>0,2));
      end
      fprintf('\n');
   end
end
