try; cd(fileparts(mfilename('fullpath')));catch; end;
run ../../utilities/initPaths.m

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

% ----------------------------------------------------------------------------
%    FILL IN YOUR CODE BELOW HERE
% ----------------------------------------------------------------------------
state=[]; % initial state, use to keep track of which events have been processed so far

% get string from the user to echo
str=input('Enter string to echo:');

% send the echo event
msgev=sendEvent('echo',str);
fprintf('Msg: %s\n',ev2str(msgev));

% wait for acknowledgement event from the server
[events,state]=buffer_newevents(buffhost,buffport,state,'ack'); % wait for next ack event

% for each ack event show it to the user
for ei=1:numel(events);
  fprintf('Resp: %s\n',evstr(events(ei)));
end  
