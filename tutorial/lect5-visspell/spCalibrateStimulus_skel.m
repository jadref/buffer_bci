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
symbols={'1' '2' '3';...
         '4' '5' '6';...
         '7' '8' '9'};
% ----------------------------------------------------------------------------
%    FILL IN YOUR CODE BELOW HERE
% ----------------------------------------------------------------------------

% useful functions 
% make the stimulus, h matrix of handles to matlab graphical text objects
[h,symbs]=initGrid(symbols);
set(h(1,1),'color',tgtCol);% change the color of the top left one of the text objects

% make the target stimulus sequence
[ans,ans,ans,ans,tgtSeq]=mkStimSeqRand(numel(symbols),nSeq);
% make the row/col flash sequence for each sequence
[stimSeqRow]=mkStimSeqRand(size(symbols,1),nRepetitions*size(symbols,1));
[stimSeqCol]=mkStimSeqRand(size(symbols,2),nRepetitions*size(symbols,2));

% get current sample time, so can send 2 events refering to the *same* time-point
stimSamp=buffer('get_samp'); % get current sample time, for event time-stamps
sendEvent('stimulus.rowFlash',stimSeqRow(:,ei),stimSamp); % indicate this row is 'flashed'
sendEvent('stimulus.tgtFlash',stimSeqRow(tgtRow,ei),stimSamp); % indicate if it was a 'target' flash

% convert from single index to 2-d matrix index, useful for converting target index, into a target location
[tgtRow,tgtCol]=ind2sub(size(symbols),tgtSeq(si)); % convert to row/col index
