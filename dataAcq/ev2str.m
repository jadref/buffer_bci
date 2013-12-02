function str=ev2str(events)
str='';
for i=1:numel(events);
  event=events(i);
  if ( ~isstruct(event) ) event=struct(event); end;
  val = event.value; 
  if ( isempty(val) ) val='[]';
  elseif( isnumeric(val) ) val=['[' sprintf('%g,',val(1:end-1)) sprintf('%g',val(end)) ']']; 
  end;
  str=[str sprintf('(sample=%d type=%s value=%s)\n',int32(event.sample),event.type,val)];
end
return