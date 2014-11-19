run ../../utilities/initPaths.m;

buffhost='localhost';buffport=1972;
% wait for the buffer to return valid header information
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
% set the real-time-clock to use
initgetwTime;
initsleepSec;

% wait for new events of a particular type
state=[]; % initial state
endExpt=false; % until exit event is received
while ( ~endExpt ) 
  [events,state]=buffer_newevents(buffhost,buffport,state); % wait for next echo event
  if ( isempty(events) ) fprintf('Wait timeout\n'); end;
  
  % send an ack event with the same value, for each recieved event
  for ei=1:numel(events);
    evt=events(ei);
    if ( strcmp(evt.type,'echo') ) continue; end;
    if ( strcmp(evt.type,'exit') ) endExpt=true; end;
    fprintf('%s\n',ev2str(evt));
    sendEvent('echo',events(ei).value,-1);
  end  
end
