run ../utilities/initPaths;
buffhost='localhost'; buffport=1972;
% wait for valid header
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
  try 
    hdr=buffer('get_hdr',[],buffhost,buffport); 
  catch
    hdr=[];
    fprintf('Invalid header info... waiting.\n');
  end;
  pause(1);
end;

nevents=[];
while ( true )
  [events,nevents]=buffer_newevents([],[],nevents,buffhost,buffport);
  if ( ~isempty(events) ) 
    fprintf('%s\n',ev2str(events));
  end
  fprintf(1,'.');
  pause(1);
end