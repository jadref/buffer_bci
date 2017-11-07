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
feedbackDuration=2; % length of time feedback is on the screen
bgCol=[.5 .5 .5]; % background color (grey)
flashCol=[1 1 1]; % the 'flash' color (white)
tgtCol=[0 1 0]; % the target indication color (green)

% the set of options the user will pick from
% this is what they will see on the screen
symbols={'A' 'B' 'C' 'D'};

% ----------------------------------------------------------------------------
%    FILL IN YOUR CODE BELOW HERE
% ----------------------------------------------------------------------------

% Usefull functions
% make the a stimulus grid with symbols in it, return the *text* handles
[h,symbs]=initGrid(symbols);

% initialize the buffer_newevents state so that will catch all predictions after this time
[devents,state]=buffer_newevents(buffhost,buffport,[],'classifier.prediction',[],0);


% build a logical version of the flash state at each time point --
%  needed to decode the classifier predictions later
stimSeq=zeros([size(symbols),nRepetitions*numel(symbols)]);
nFlash=0;

for ei=1:size(stimSeq,2);
  nFlash=nFlash+1;
                                % flash the flashIdx letter
  set(h(flashIdx),'color',flashCol);
  stimSeq(flashIdx,nFlash)=true;
  drawnow;
end

% get all prediction events which have happened since the last time
% we called buffer-new events, i.e. since the start of this sequence
[devents,state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],500);

          % extract the classifer decision values from the predictions events
clsfrpred=cat(2,devents.value);

% given a vector of classifier predictions for each flash clsfrpred=[nFlash x 1]
% compute the inner product (similarity) between classifier predictions
% and each symbols flash state
corr = reshape(stimSeq(:,:,1:nFlash),[numel(symbols) nFlash])*clsfrpred;
% get the predicted target as one with highest correlation
[ans,predTgt] = max(corr); 
