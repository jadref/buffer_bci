run ../../utilities/initPaths
if ( 1 ) 
   dataRootDir = '~/data/bci'; % main directory the data is saved relative to in sub-dirs
   datasets_brainfly_local();
else
   dataRootDir = '/Volumes/Wrkgrp/STD-Donders-ai-BCI_shared'; % main directory the data is saved relative to in sub-dirs
   datasets_brainfly();
end

% set of sourec->dest target class mappings to ensure all classes have the same labels
subistuteVals={'1 LH ' '2 LH';
               '2 RH ' '1 RH';
               '2 LH ' '2 LH';
               '1 RH ' '1 RH';
               'LH'   '2 LH';
               'RH'   '1 RH'};

trlen_ms=750;
subsamplefs=83.3; % output sample rate
label   ='movement'; % generic label for this slice/analysis type

for si=1:numel(datasets);
  if( isempty(datasets{si}) ) continue; end;
  subj   =datasets{si}{1};
  alldata =[];
  for sessi=1:numel(datasets{si})-1;
    session=datasets{si}{1+sessi};
    saveDir=session;
    if(~isempty(stripFrom))
      tmp=strfind(session,stripFrom);
      if ( ~isempty(tmp) ) saveDir=session(1:tmp-1);  end
    end
    sessdir=fullfile(dataRootDir,expt,subj,session);
    sessfn = fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_sliced',subj,label));
    
    % load the file, check it's consistent, skip to next if problems
    fprintf('Trying: %s\n',sessfn);
     if( ~(exist(sessfn,'file') ||  exist([sessfn '.mat'],'file')) ) 
       fprintf('Skipping missing session file\n');
       continue;
     end
     d=load(sessfn);
     if( isempty(d.data) || isempty(d.devents) )
        fprintf('Skipping session with no data/events\n');
        continue;
     end

     if( ~isempty(subsamplefs) ) % down-sample to make smaller if wanted
        fprintf('Downsampling: %g -> %g\n',d.hdr.Fs,subsamplefs);
        for ei=1:numel(d.data);
           outsz=round(size(d.data(ei).buf,2)*subsamplefs./d.hdr.Fs);
           d.data(ei).buf = subsample(d.data(ei).buf,outsz,2);
        end
        d.hdr.Fs   = subsamplefs;
     end

     % BODGE: fix-up the labels to remove annoying training whitespace
     for ei=1:numel(d.devents);
        val = d.devents(ei).value; 
        for ri=1:size(subistuteVals,1);
           if strcmp(val,subistuteVals{ri,1}) val = subistuteVals{ri,2}; end
        end
        d.devents(ei).value = val;
     end

     % add session info
     d.session=session; 
     d.sessdir=fullfile(expt,subj,session);

     % add to the full set of data
     if ( isempty(alldata) ) 
       alldata=d;
     else
       alldata(end+1)=d;
     end
  end % sessions
  savefn = fullfile(dataRootDir,expt,subj,sprintf('%s_%s_sliced',subj,label));
  fprintf('Saving %d session to : %s\n',numel(alldata),savefn);
  save(savefn,'-v7.3','alldata');
end % subjects
