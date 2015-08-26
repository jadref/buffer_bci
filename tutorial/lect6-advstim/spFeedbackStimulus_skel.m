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
symbols={'1' '2' '3';...
         '4' '5' '6';...
         '7' '8' '9'}';
% N.B. Note the transpose, as screen coordinates (x,y) are transposed relative to 
%  matrix coordinates (row,col) we store the symbols such that row=x and col=y

% ----------------------------------------------------------------------------
%    FILL IN YOUR CODE BELOW HERE
% ----------------------------------------------------------------------------

% Usefull functions
% make the a stimulus grid with symbols in it, return the *text* handles
[h,symbs]=initGrid(symbols);

% make the row/col flash sequence for each sequence
[stimSeqRow]=mkStimSeqRand(size(symbols,1),nRepetitions*size(symbols,1));
[stimSeqCol]=mkStimSeqRand(size(symbols,2),nRepetitions*size(symbols,2));

% build a logical version of the flash state at each time point --
%  needed to decode the classifier predictions later
stimSeq=zeros([size(symbols),nRepetitions*numel(symbols)]);
nFlash=0;
for ei=1:numel(stimSeqRow,2);
  nFlash=nFlash+1;
  stimSeq(stimSeqRow(:,ei)>0,:,nFlash)=true;
end
for ei=1:numel(stimSeqCol,2);
  nFlash=nFlash+1;
  stimSeq(:,stimSeqCol(:,ei)>0,nFlash)=true;
end

% given a vector of classifier predictions for each flash clsfrpred=[nFlash x 1]
% compute the inner product (similarity) between classifier predictions
% and each symbols flash state
corr = reshape(stimSeq(:,:,1:nFlash),[numel(symbols) nFlash])*clsfrpred;
% get the predicted target as one with highest correlation
[ans,predTgt] = max(corr); 
