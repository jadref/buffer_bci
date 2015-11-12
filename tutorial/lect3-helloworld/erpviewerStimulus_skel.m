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

% useful constants
interSeqDuration=3;
interEpochDuration=1;

% make the stimulus
clf;
set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
set(gca,'visible','off','color',[0 0 0]); % black axes
h=rectangle('curvature',[1 1],'position',[.25 .25 .5 .5],'facecolor',[.5 .5 .5]); % fixitation point
set(h,'visible','off');

% make the target sequence
[ans,ans,ans,ans,stimCode]=mkStimSeqRand(2,nEpoch,[],0);

      
% reset the cue and fixation point to indicate trial has finished  
set(h,'visible','off'); 
drawnow;
  
% make the cue visible again to indicate trial start
set(h,'visible','on');
drawnow;

% change the cue's color as needed
if ( epoch==1 ) 
  set(h,'facecolor',[1 1 1]);
else
  set(h,'facecolor',[.5 .5 .5]);
end
drawnow;
  
% wait for a key press -- N.B. many alternative ways to do this, e.g.
waitforbuttonpress;
% OR
kbhit
% OR
msg=msgbox({'Press OK to continue'},'Continue?');while ishandle(msg); pause(.2); end;
