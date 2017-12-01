function str=ev2str(events)
str='';
for i=1:numel(events);
  event=events(i);
  if ( ~isstruct(event) ) event=struct(event); end;
  if ( ~isfield(event,'value') ) continue; end;
  val = event.value; 
  if ( isempty(val) ) val='[]';
  elseif( isnumeric(val) || islogical(val) ) 
    vstr=sprintf('%g',val(1));
    if ( numel(val)>1) vstr=['[' vstr sprintf(' %g',val(2:end)) ']']; end;
    val=vstr;
  end;
  if(i>1) str=[str sprintf('\n')]; end;
  str=[str sprintf('{s:%d t:%s v:%s}',int32(event.sample),event.type,val)];
end
return
