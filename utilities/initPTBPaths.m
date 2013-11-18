psychpath='/home/jdrf/source/matfiles/toolboxes/Psychtoolbox';%hard code PTB location, N.B. *MUST* be absolute path
if ( ~exist(psychpath,'dir') ) % search relative to here..
  mdir=fileparts(mfilename('fullpath'));
  psychpath=fullfile(mdir,'toolboxes','Psychtoolbox');
end
% look 1 layer deeper for source distributions
if ( exist(fullfile(psychpath,'Psychtoolbox'),'dir') )
    psychpath=fullfile(psychpath,'Psychtoolbox');
end
if ( isempty(strfind(path,psychpath)) ) % only if not already there
  addpath(exGenPath(psychpath));
end
psychJavadir = fullfile(psychpath,'PsychJava');
if ( usejava('jvm') && ~any(strcmp(javaclasspath,psychJavadir)) )
  warning('Modifying javaclass path -- this clears all Global & JAVA variables!');
  javaaddpath(exGenPath(psychJavadir,[],0,1));
end
