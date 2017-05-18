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
  str=[str sprintf('(sample=%d type=%s value=%s)\n',int32(event.sample),event.type,val)];
end
return
