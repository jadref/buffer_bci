function mi=matchEvents(ev,mtype,mval)
% mi=matchEvents(ev,mtype,mval)
%
% Inputs:
%  ev -- [struct array] set of event structure to match within
%  mtype -- {cell} cell array of possible event types to match
%           N.B. mtype='*' means match everything
%                mtype='prefix*' means match any type which starts with prefix
%  mval  -- {cell} cell array of possible event values to match
%           N.B. mval='*' means match everything
%                mval='prefix*' means match any type which starts with prefix
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
  type ={ev.type}; type=type(:);
  if ( isnumeric(mtype) && isnumeric(type{1}) ) % try to make single type matrix for speed..
	 try;   
       type =cat(1,type{:}); % single type, matrix
	 catch; 
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
          if( mstr(end)=='*' && strncmp(estr,mstr(1:end-1),numel(mstr)-1)) % prefix match
            mi(ei)=true; break;
          elseif ( strcmp(estr,mstr) ) % full-str match
            mi(ei)=true; break;
          end;
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
  value ={ev.value}; value=value(:);
  if ( isnumeric(mval) && isnumeric(value{1}) ) % try to make single type matrix for speed..
	 try;   
       value =cat(1,value{:}); % single type, matrix
	 catch; 
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
          if( mstr(end)=='*' && strncmp(vstr,mstr(1:end-1),numel(mstr)-1)) % prefix match
            mi(ei)=true; break;
          elseif ( strcmp(vstr,mstr) ) % full-str match
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
