function [curpath]=exGenPath(sourcedir,excludeDirs,todisplay,cellp)
% Genpath wrapper with ability to specify a excluded directory patterns
%
% [curpath]=exGenPath(sourcedir,excludeDirs,todisplay,cellp)
%
% Inputs:
%  sourcedir -- [str] starting directory
%  excludeDirs -- {cell of strs} sub-strings to exclude
%                   ({'CVS','.svn','.git','__MACOSX','MacOS','private'})
%  todisplay -- 1 display added folders (0 don't)
%  cellp     -- [bool] return path as a cell array  (0)
if nargin < 3, todisplay = 0; end
if nargin < 4, cellp=0; end;
% Genpath wrapper with ability to specify a excluded directory patterns
if ( nargin < 2 || isempty(excludeDirs) )
	excludeDirs={'CVS','.svn','.git','__MACOSX','MacOS','private'};
end
N=genpath(sourcedir);
dirIdx=[0 find(N==pathsep)];
if (cellp) curpath={}; else curpath=''; end;
for i = 1 : numel(dirIdx)-1
	dname=N(dirIdx(i)+1:dirIdx(i+1)-1);
	excluded=false;
	for j=1:numel(excludeDirs);
		if ( ~isempty(strfind(dname,excludeDirs{j})) )
			excluded=true;
			break;
		end
	end
	if( ~excluded )
       if (cellp) curpath={curpath{:} dname};
       else curpath=[curpath pathsep dname];
       end
		if todisplay, disp(dname); end
	end
end