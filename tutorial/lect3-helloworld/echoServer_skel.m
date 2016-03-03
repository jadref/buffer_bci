mfiledir=fileparts(mfilename('fullpath'));
run(fullfile(mfiledir,'../../utilities/initPaths.m'));

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

% wait for new events of a particular type
state=[]; % initial state
[events,state]=buffer_newevents(buffhost,buffport,state,'echo'); % wait for next echo event

% send an ack event with the same value, for each recieved event
for ei=1:numel(events);
  sendEvent('ack',events(ei).value);
end
