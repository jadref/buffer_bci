if ( exist('OCTAVE_VERSION','builtin') ) % octave specific
  page_screen_output(0); %prevent paging of output..
  page_output_immediately(1); % prevent buffering output
end
%Add necessary paths
buffer_bcidir=fileparts(fileparts(mfilename('fullpath'))); % parent directory
if ( exist(fullfile(buffer_bcidir,'dataAcq'),'dir') ) addpath(fullfile(buffer_bcidir,'dataAcq')); end;
if ( exist(fullfile(buffer_bcidir,'utilities'),'dir') ) addpath(fullfile(buffer_bcidir,'utilities')); end;
if ( exist(fullfile(buffer_bcidir,'stimulus'),'dir') ) addpath(fullfile(buffer_bcidir,'stimulus')); end;
if ( exist(fullfile(buffer_bcidir,'classifiers'),'dir') ) addpath(fullfile(buffer_bcidir,'classifiers')); end;
if ( exist(fullfile(buffer_bcidir,'plotting'),'dir') ) addpath(fullfile(buffer_bcidir,'plotting')); end;
if ( exist(fullfile(buffer_bcidir,'signalProc'),'dir') ) addpath(fullfile(buffer_bcidir,'signalProc')); end;
if ( exist(fullfile(buffer_bcidir,'offline'),'dir') ) addpath(fullfile(buffer_bcidir,'offline')); end;

dataAcq_dir=fullfile(fileparts(buffer_bcidir),'dataAcq');
if ( ~exist(dataAcq_dir,'dir') )
  dataAcq_dir=fullfile(fileparts(buffer_bcidir),'dataAcq');
end
fprintf('Adding paths from dataAcq dir = %s\n',dataAcq_dir);
if ( exist(dataAcq_dir,'dir') ) 
  addpath(dataAcq_dir); 
  if ( exist(fullfile(dataAcq_dir,'buffer'),'dir') ) 
    addpath(fullfile(dataAcq_dir,'buffer')); 
  end
  if ( usejava('jvm') && ...
       exist(fullfile(dataAcq_dir,'buffer','java'),'dir') ) % use java buffer if it's there
    bufferjavaclassdir=fullfile(dataAcq_dir,'buffer','java');
    addpath(bufferjavaclassdir); 
    bufferjar = fullfile(bufferjavaclassdir,'BufferClient.jar');
    if ( exist(bufferjar,'file') ) 
      if ( ~any(strcmp(javaclasspath,bufferjar)) )
        warning('Modifying javaclass path -- this clears all variables!');
        javaaddpath(bufferjar); % N.B. this will clear all variables!
      end
    elseif ( ~any(strcmp(javaclasspath,bufferjavaclassdir)) )
      warning('Modifying javaclass path -- this clears all variables!');
      javaaddpath(bufferjavaclassdir); % N.B. this will clear all local variables!
    end
  end
end;

