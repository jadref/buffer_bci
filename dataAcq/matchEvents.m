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
else
										  % extract all the type info
  if ( ischar(ev(1).type) )
	 type={ev.type}; type=type(:);
  else
	 try;   type  =cat(1,ev.type); % single type, matrix
	 catch; type ={ev.type}; type=type(:); % mixed types => cell-array
	 end
  end
  if ( isnumeric(mtype) && isnumeric(type) ) % fast path
	 mi=any(repop(type(mi),'==',mtype(:)'),2);
  elseif ( iscell(type) )
	 mi(:)=false;
	 for ei=1:numel(mi);
		estr=type{ei};
		for vi=1:numel(mtype);
        if ( iscell(mtype) ) mstr=mtype{vi}; else mstr=mtype(vi); end;
        if ( ischar(estr) && ischar(mstr) )
			 if ( strcmp(estr,mstr) || ... % normal match || prefix match
					( mstr(end)=='*' && numel(estr)>=numel(mstr)-1 && strcmp(estr(1:numel(mstr)-1),mstr(1:end-1))) )
				mi(ei)=true; break;
			 end
		  elseif ( isequal(estr,mstr) )
			 mi(ei)=true; break;
		  end				
		end
	 end
  else
	 warning('1:Unrec type-match spec: ignored!');
  end
end
% find matching values
if ( isequal(mval,'*') )
else
														  % extract the values
  if ( ischar(ev(1).value) )
	 value={ev.value}; value=value(:);
  else
	 try;   value =cat(1,ev.value); % single type, matrix
	 catch; value ={ev.value}; value=value(:); % mixed types => cell-array
	 end
  end
  if ( isnumeric(mval) && isnumeric(value) )
	 mi(mi)=any(repop(value(mi),'==',mval(:)'),2);
  elseif ( iscell(type) )
	 ms =find(mi);
	 mi(ms)=false;
	 for ei=ms(:)';
		vstr=value{ei};
		for vi=1:numel(mval);
        if ( iscell(mval) ) mstr=mval{vi}; else mstr=mval(vi); end;
		  if ( ischar(vstr) && ischar(mstr) )
			 if ( strcmp(vstr,mstr) || ... % normal match || prefix match
					( mstr(end)=='*' && numel(vstr)>=numel(mstr)-1 && strcmp(vstr(1:numel(mstr)-1),mstr(1:end-1))) ) 
				mi(ei)=true; break; 
			 end;
		  elseif ( isequal(vstr,mstr) )
			 mi(ei)=true; break;
		  end
		end
	 end
  else
	 warning('2:Unrec val-match spec: ignored!');
  end
end
return;
