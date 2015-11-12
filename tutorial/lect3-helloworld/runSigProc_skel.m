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


% useful functions
% get cap layout info
di = addPosInfo(hdr.channel_names,'1010'); % for a 1010 cap name set
ch_pos=cat(2,di.extra.pos2d); ch_names=di.vals; iseeg=[di.extra.iseeg]; % extract pos and channels names

% make a template figure window with the channels in the positions as specified in the capfile
clf;
hdls=image3d(erp,1,'plotPos',ch_pos,'xlabel','ch','Xvals',ch_names,'zlabel','class','disptype','plot','ticklabs','sw');
% update the info displayed above (without making new axes -- FASTER)
hdls=image3d(erp,1,'handles',hdls,'xlabel','ch','Xvals',ch_names,'zlabel','class','disptype','plot','ticklabs','sw');


% block until we've got new events which match 'startSet' and 'trlen_samp' data for each of these events
%  OR
%  until we've got an event matching 'exitSet'
% N.B. keep the state around to track what's been processed in subsequent calls
[data,devents,state]=buffer_waitData([],[],state,'startSet',{'stimulus.epoch'},'trlen_samp',trlen_samp,'exitSet',{'data' 'stimulus.sequences' 'end'});
