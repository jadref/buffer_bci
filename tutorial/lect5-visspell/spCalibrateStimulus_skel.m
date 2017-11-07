try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end

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

verb=0;
nSeq=15;
nRepetitions=5;  % the number of complete row/col stimulus before sequence is finished
cueDuration=2;
stimDuration=.2; % the length a row/col is highlighted
bgCol=[.5 .5 .5]; % background color (grey)
flashCol=[1 1 1]; % the 'flash' color (white)
tgtCol=[0 1 0]; % the target indication color (green)

% the set of options the user will pick from
symbols={'A' 'B' 'C' 'D'};
% ----------------------------------------------------------------------------
%    FILL IN YOUR CODE BELOW HERE
% ----------------------------------------------------------------------------

% useful functions 
% make the stimulus, h matrix of handles to matlab graphical text objects
[h,symbs]=initGrid(symbols);
tgtIdx=1;
flashIdx=1;
set(h(flashIdx),'color',tgtCol);% change the color of the top left one of the text objects

% get current sample time, so can send 2 events refering to the *same* time-point
stimSamp=buffer('get_samp'); % get current sample time, for event time-stamps
sendEvent('stimulus.flash',symbols{flashIdx},stimSamp); % indicate this row is 'flashed'
sendEvent('stimulus.tgtFlash',flashIdx==tgtIdx,stimSamp); % logical indicating if target flash or not
