if ( exist('initPaths','file') ) 
  initPaths;
else
  run ../utilities/initPaths;
end

buffhost='localhost';buffport=1972;
global ft_buff; ft_buff=struct('host',buffhost,'port',buffport);
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
initgetwTime();
initsleepSec();
% init the buffer clock alignment
global rtclockrecord rtclockmb;
[rtclockmb rtclockrecord]=buffer_alignrtClock();
clockUpdateTime=getwTime();
clockUpdateInterval=1; %

trlen_ms=600;
% ----------------------------------------------------------------------------
%    FILL IN YOUR CODE BELOW HERE
% ----------------------------------------------------------------------------

% useful functions
buffer_waitData(???)