if ( exist('OCTAVE_VERSION','builtin') ) debug_on_error(1); else dbstop if error; end;
% guard to prevent running multiple times
if ( exist('cursorConfig','var') && ~isempty(cursorConfig) ) return; end;
cursorConfig=true;

run ../utilities/initPaths.m;

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

if ( exist('OCTAVE_VERSION','builtin') ) 
  page_output_immediately(1); % prevent buffering output
  if ( ~isempty(strmatch('qthandles',available_graphics_toolkits())) )
    graphics_toolkit('qthandles'); % use fast rendering library
  elseif ( ~isempty(strmatch('fltk',available_graphics_toolkits())) )
    graphics_toolkit('fltk'); % use fast rendering library
  end
end

verb=1;
nSeq=15;
nRepetitions=5;  % the number of complete row/col stimulus before sequence is finished
cueDuration=2;
seqDuration=10;   % duration of 1 stimulus sequence for calibration
stimDuration=.15; % the length a row/col is highlighted
dataDuration=.6;  % amount of data used for classifier
startDelay=2;     % delay after cue goes away before starting the stimulus
interSeqDuration=2;
feedbackMoveDuration=5;
feedbackMoves=20;
predAlpha=[]; % exp smoothing factor for the predictions, [] means just sum

% BCI Stim Props
nSymbs=4;
stimType ='ssvep'; %'pseudorand';% 
isi      = 1/6;
tti=.5; % target to target interval
vnSymbs=max(nSymbs,round(tti/isi)); % number virtual symbs used to generate the stim seq... adds occasional gaps
arrowScale=[.4 1.0];
sizeStim = 1.5;
bgColor=[.5 .5 .5]; % background color (grey)
flashColor=[1 1 1]; % the 'flash' color (white)
tgtColor=[0 1 0]; % the target indication color (green)
tgt2Color= [1 0 0];
edgeColor=[1 1 1];
axLim=[-4 4];

classifierType={'erp' 'ersp'}; % use both classifier types
trlen_ms=750; % longer to allow for movement/blink signature
