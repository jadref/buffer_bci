function mi=matchEvents(ev,mtype,mval)
% mi=matchEvents(ev,mtype,mval)
%
% Inputs:
%  ev -- [struct array] set of event structure to match within
%  mtype -- {cell} cell array of possible event types to match
%           N.B. mtype='*' means match everything
%  mval  -- {cell} cell array of possible event values to match
%           N.B. mval='*' means match everything
if ( nargin<2 ) mtype='*'; end;
if ( nargin<3 ) mval='*'; end;
if ( isempty(ev) || isempty(mtype) || isempty(mval) ) mi=[]; return; end; % fast path!
if ( ischar(mtype) && ~isequal(mtype,'*') ) mtype={mtype}; end;
if ( ischar(mval) && ~isequal(mval,'*') )   mval={mval}; end;

% find matching types
mi=true(size(ev));
if ( isequal(mtype,'*') )
elseif ( isnumeric(mtype) )
  type=[ev.type]; type=type(:);
  mi=any(repop(type(mi),'==',mtype(:)'),2);
elseif ( iscell(mtype) && ischar(mtype{1}) )
  mi(:)=false;
  for ei=1:numel(mi);
    estr=ev(ei).type;
    for vi=1:numel(mtype);
      mstr=mtype{vi};
      if ( strcmp(estr,mstr) || ... % normal match || prefix match
           ( mstr(end)=='*' && numel(estr)>=numel(mstr)-1 && strcmp(estr(1:numel(mstr)-1),mstr(1:end-1))) )
        mi(ei)=true; break; 
      end
    end
  end
else
  warning('Unrec type-match spec: ignored!');
end
% find matching values
if ( isequal(mval,'*') )
elseif ( isnumeric(mval) )
  value=[ev.value]; value=value(:);
  mi(mi)=any(repop(value(mi),'==',mval(:)'),2);
elseif ( iscell(mval) && ischar(mval{1}) )
  ms =find(mi);
  mi(ms)=false;
  for ei=ms(:)';
    vstr=ev(ei).value;
    for vi=1:numel(mval);
      mstr=mval{vi};
      if ( strcmp(vstr,mstr) || ... % normal match || prefix match
           ( mstr(end)=='*' && numel(vstr)>=numel(mstr)-1 && strcmp(vstr(1:numel(mstr)-1),mstr(1:end-1))) ) 
        mi(ei)=true; break; 
      end;     
    end
  end
else
  warning('Unrec val-match spec: ignored!');
end
return;