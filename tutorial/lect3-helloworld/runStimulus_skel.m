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

% make a random sequence of nEpoch long with 2 classes
[ans,ans,ans,stimCode]=mkStimSeqRand(2,nEpoch,[],0);


% make the stimulus, i.e. a big circle in the middle of the axes
clf;
set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
set(gca,'visible','off','color',[0 0 0]); % black axes
h=rectangle('curvature',[1 1],'position',[.25 .25 .5 .5],'facecolor',[.5 .5 .5]);
set(h,'visible','off');
% update the circles color
set(h,'color',[1 1 1],'visible','on'); % make it white and visible
