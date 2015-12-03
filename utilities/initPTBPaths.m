if ( ~isempty(which('WaitSecs')) && ~isempty(which('Screen')) ) continue; end; % don't bother if already in the path

mdir=fileparts(mfilename('fullpath'));

if ( isequal(strfind(lower(computer()),'pcwin'),1) ) % default windows location
    psychpath='C:/toolbox';
    if ( ~exist(psychpath,'dir') ) psychpath='C:/Toolboxes'; end;
elseif( isequal(strfind(lower(computer()),'mac'),1)) % default MacOs location
    psychpath='/Applications/Psychtoolbox';
    if ( ~exist(psychpath,'dir') ) psychpath='/Users/Shared/Psychtoolbox'; end
else
  psychpath='/usr/share/octave/site/m/psychtoolbox-?';
  if ( ~exist(psychpath,'dir') )
	 psychpath=fullfile(mdir,'..','Psychtoolbox'); % otherwise guess?
  end
end
if ( ~exist(psychpath,'dir') ) % search relative to here, 2 dir up
  psychpath=fullfile(mdir,'..','..','toolboxes','Psychtoolbox');
end
% look 1 layer deeper for source distributions
if ( exist(fullfile(psychpath,'Psychtoolbox'),'dir') )
    psychpath=fullfile(psychpath,'Psychtoolbox');
end
if ( exist(psychpath,'dir') )
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
end
if ( isempty(which('Screen')) ) % error if PTB not found
  try;
	 uiwait(msgbox({'Error couldnt find Psychtoolbox on your path!' 'Ignoring.'},'Error','modal'),10);
  catch;
  end;
  warning('Couldnt find Psychtoolbox on your path!');
end
