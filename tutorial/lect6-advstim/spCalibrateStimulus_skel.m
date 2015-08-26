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

% init the PTB Paths
run ../utilities/initPTBPaths

% useful functions 
% Open a PTB window, 500x500 pixels, top left of the screen
wPtr=Screen('OpenWindow',0,[0 0 0],[0 0 500 500]);

% make the stimulus
[texels,srcRect,destRect]=mkTextureGrid(wPtr,symbols);

% make 1 row of the texels bright
flashColor = [255;255;255];
bgColor    = [255;255;255]*.5;
highLight=false(size(symbols));
highLight(i,:)=true; % indicate which row to highlight
Screen('DrawTextures',wPtr,texels(highLight),srcRects(:,highLight),destRects(:,highLight),[],[],[],flashColor);
Screen('DrawTextures',wPtr,texels(~highLight),srcRects(:,~highLight),destRects(:,~highLight),[],[],[],bgColor);
% now re-draw the display
Screen('Flip',wPtr);

% N.B. Initially you probably want to start for spCalibrateStimulus from
% last week and just replace the Matlab calls with the PTB versions
