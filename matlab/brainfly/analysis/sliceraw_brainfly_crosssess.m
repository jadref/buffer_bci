run ../../utilities/initPaths
dataRootDir = '~/data/bci'; % main directory the data is saved relative to in sub-dirs
dataRootDir = '/Volumes/Wrkgrp/STD-Donders-ai-BCI_shared'; % main directory the data is saved relative to in sub-dirs
datasets_brainfly();

trlen_ms=750;
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

     if( ~(exist(sessfn,'file') ||  exist([sessfn '.mat'],'file')) ) 
       fprintf('Skipping missing session file');
       continue;
     end
     d=load(sessfn);
     d.session=session; d.sessdir=fullfile(expt,subj,session);
     if ( isempty(alldata) ) 
       alldata=d;
     else
       alldata(end+1)=d;
     end
  end % sessions
  fprintf('%d sessions to combine\n',numel(alldata));
  savefn = fullfile(dataRootDir,expt,subj,sprintf('%s_%s_sliced',subj,label));
  save(savefn,'alldata');
end % subjects
