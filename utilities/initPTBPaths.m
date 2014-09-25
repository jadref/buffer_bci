if ( ~isempty(which('WaitSecs')) && ~isempty(which('Screen')) ) continue; end; % don't bother if already in the path

if ( isequal(strfind(lower(computer()),'pcwin'),1) )
    psychpath='C:/toolbox';
elseif( isequal(strfind(lower(computer()),'mac'),1))
    psychpath='/Applications/Psychtoolbox';
else
    psychpath='/Pyschtoolbox';
end
if ( ~exist(psychpath,'dir') ) % search relative to here, 2 dir up
  mdir=fileparts(mfilename('fullpath'));
  psychpath=fullfile(mdir,'..','..','toolboxes','Psychtoolbox');
end
% look 1 layer deeper for source distributions
if ( exist(fullfile(psychpath,'Psychtoolbox'),'dir') )
    psychpath=fullfile(psychpath,'Psychtoolbox');
end
if ( isempty(strfind(path,psychpath)) ) % only if not already there
  addpath(exGenPath(psychpath));
  if ( isequal(strfind(lower(computer()),'pcwin'),1))
    addpath(fullfile(psychpath,'PsychBasic','MatlabWindowsFilesR2007a'))
  end
end
psychJavadir = fullfile(psychpath,'PsychJava');
if ( usejava('jvm') && ~any(strcmp(javaclasspath,psychJavadir)) )
  warning('Modifying javaclass path -- this clears all Global & JAVA variables!');
  javaaddpath(exGenPath(psychJavadir,[],0,1));
end

if ( isempty(which('Screen')) ) % error if PTB not found
  uiwait(msgbox({'Error couldnt find Psychtoolbox on your path!' 'Aborting'},'Error','modal'),10);
  error('Couldnt find Psychtoolbox on your path!');
end