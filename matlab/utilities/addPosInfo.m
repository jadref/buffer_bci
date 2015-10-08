function [di]=addPosInfo(di,capFile,overridenms,prefixMatch,verb,capDir)
% add electrode position info to a dimInfo structure
%
% [di]=addPosInfo(di,capFile,overridenms,prefixMatch,verb,capDir)
%
% Inputs:
%  di -- dim-info for the channels *only*
%        OR
%        {chnms} cell array of channel names to get pos-info for
%  capFile -- file name of a file which contains the pos-info for this cap
%  overridedims -- flag that we should ignore the channel names in di
%  prefixMatch  -- [bool] match channel names if only the start matches?
%  verb         -- [int] verbosity level  (0)
%  capDir       -- 'str' directory to search for capFile
if ( nargin < 2 || isempty(capFile) ); capFile='1010'; end;
if ( nargin < 3 ); overridenms=0; end; % override di's vals info with info from capfile?
if ( nargin < 4 || isempty(prefixMatch) ); prefixMatch=0; end;
if ( nargin < 5 || isempty(verb) ); verb=0; end;
if ( nargin < 6 ); capDir=[]; end;
[Cnames latlong xy xyz]        =readCapInf(capFile,capDir);
if ( isstruct(di) ); vals=di.vals; 
else 
  vals=di; 
  if( iscell(vals) ); tmp={vals}; else; tmp=vals; end; % N.B. for matlab struct cons bug!
  di=struct('name','ch','units',[],'vals',tmp,'extra',[]); 
end;
if ( (isnumeric(vals) || (~isempty(overridenms) && overridenms)) )%...
   %     && numel(Cnames)<=numel(vals)  )
   ovals=vals;
   if ( isnumeric(vals) ); vals = num2cell(vals(:)); end;
   if ( isempty(vals) ); vals(1:numel(Cnames))=Cnames; % Use ch-names from capFile
   else                 vals(1:min(end,numel(Cnames)))=Cnames(1:min(numel(vals),end)); % Use ch-names from capFile
   end
end
% Add the channel position info, and iseeg status
chnm={}; matchedCh=false(numel(Cnames),1);
for i=1:numel(vals);
   ti=0;
   if ( iscell(vals) ); chnm{i}=vals{i};  else; chnm{i}=vals(i); end;
   if ( isstr(chnm{i}) )
      for j=1:numel(Cnames);  
        % case insenstive match
        if ( ~matchedCh(j) && strcmp(lower(chnm{i}),lower(Cnames{j})) ) 
          ti=j; matchedCh(j)=true; break; 
        end; 
      end;
      if ( prefixMatch && ti==0 ) % try prefix match
        for j=1:numel(Cnames);  
          % case insenstive match
          if ( ~matchedCh(j) && ~isempty(strmatch(lower(Cnames{j}),lower(chnm{i}))) ) 
            ti=j; matchedCh(j)=true; break; 
          end; 
        end;
      end
   elseif ( isnumeric(chnm{i}) && i<=numel(Cnames) ) % numeric mean exact order          
     chnm{i}=Cnames{i}; % over-ride input name with Cname
     ti = i;
     matchedCh(i)=true;
   else
      ti = 0;
      warning('Channel names are difficult');      
   end
   tii(i)=ti;
   if ( ~isempty(ti) && numel(ti)==1 && ti>0 && ti<=size(xy,2) ) 
      if ( verb>0 ); fprintf('%3d) Matched : %s\t ->\t %s\n',i,chnm{i},Cnames{ti}); end;
      chnm{i}=Cnames{ti}; % replace with nomional version
      di.extra(i).pos2d=xy(:,ti); 
      di.extra(i).pos3d=xyz(:,ti);
      di.extra(i).iseeg=true;
   else
      di.extra(i).pos2d=[-1;1];    
      di.extra(i).pos3d=[-1;1;0];
      di.extra(i).iseeg=false;
   end
end
di.vals=chnm;
return;
%---------------------------------------------------------------
function testCase();
% with di as input
addPosInfo(di);
% with cell array of channel names as input
Cnames={'Cz' 'CPz'};
addPosInfo(Cnames)
