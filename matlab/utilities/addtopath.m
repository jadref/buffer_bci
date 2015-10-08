function []=addtopath(rootdir,varargin)
% function to add sub-directories to the path -- without dup warnings
% and ignoring obvious non-matlab containing sub-directories
%
% []=addtopath(rootdir,varargin)
if ( numel(varargin)==1 && iscell(varargin{1}) ); varargin=varargin{1}; end;
if ( numel(varargin)==0 ); varargin={''}; end;
excludeDirs={'.','..','CVS','.svn','.git'};
for i=1:numel(varargin);
  if ( ~isempty(strmatch(varargin{i},excludeDirs)) ); continue; end;
  p=path;
  dname=fullfile(rootdir,varargin{i});
   mi = strfind(p,dname(3:end));
   if ( isempty(mi) || ~any(p(mi+numel(dname))==pathsep) ) % if not already there
      addpath(dname); 
   end;
end
return;
%----------------------------------------------------------------------------
