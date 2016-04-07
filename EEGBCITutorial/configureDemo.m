% guard to prevent running slow path-setup etc. multiple times
if ( ~exist('configRun','var') || isempty(configRun) ) 

% setup the paths
% search for the location of the buffer_bci root
mfiledir=fileparts(mfilename('fullpath'));
bufferdir=mfiledir(1:strfind(mfiledir,'buffer_bci')+numel('buffer_dir'));
if ( exist(fullfile(bufferdir,'utilities/initPaths.m')) ) % in utilities
  run(fullfile(bufferdir,'utilities','initPaths.m'));
else % or matlab/utilities?
  run(fullfile(bufferdir,'matlab','utilities','initPaths.m'));
end

buffhost='localhost';buffport=1972;
% wait for the buffer to return valid header information
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (isfield(hdr,'nchans') && hdr.nchans==0) ) % wait for the buffer to contain valid data
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
configRun=true;
end

%capFile='cap_tmsi_mobita_black';%'1010'; %'emotiv';%cap_tmsi_mobita_im2'; N.B. use 1010 for emotiv so non-eeg are labelled correctly
verb=0;
buffhost='localhost'; buffport=1972;

% Brain response parameters
stimDuration=.15;% the length a row/col is highlighted
interSeqDuration=2;
feedbackDuration=5;
stimRadius=.6;
ssvepFreq = [15 7.5 10 20 30];
isi=1/60;
flickerFreq=[15 20];
ersptrialDuration=8;
baselineDuration=2;
intertrialDuration=2;
ersptrlen_ms=1000;

% general cue color specifications
bgColor=[.2 .2 .2]; % background color (grey)
flashColor=[1 1 1]; % the 'flash' color (white)
tgtColor=[0 1 0]; % the target indication color (green)
fixColor=[1 0 0];
fbColor=[0 0 1]; % feedback color - (blue)

% PTB stuff
windowPos=[];%[0 0 500 500]; % in sub-window set to [] for full screen

% instructions object
instructstr={'Stimulus Type Keys',
             '';
             '1 or v : visual reponse',
             '2 or o : visual oddball',
             sprintf('3 or s : SSVEP (%ghz)',ssvepFreq(1)),
             '4 or p : visual P300',
             sprintf('5 or f : flicker (%g or %ghz)',flickerFreq(1),flickerFreq(2)),
             '6 or l : left cue task',
             '7 or n : no cue task',
             '8 or r : right cue task',
             'a      : auditory oddball',
             'q      : quit'
            };

% speller config options
spnSeq=20;
nRepetitions=5;    % the number of complete row/col stimulus before sequence is finished
nTestRepetitions=7;% the number of complete row/col stim for test phase
cueDuration=2;
stimDuration=.15; % the length a row/col is highlighted
dataDuration=.6;  % amount of data used for classifier
%interSeqDuration=2;
feedbackDuration=5;
% the set of options the user will pick from
symbols={'1' '2' '3';...
         '4' '5' '6';...
         '7' '8' '9'}';
spInstruct={'Concentrate on the Green Number.','Click to begin'};
symbSize=.1;
sptrlen_ms=dataDuration*1000;

% IM config options
nSymbs=2;
imnSeq=30;
imtrialDuration=3;
baselineDuration=2;
intertrialDuration=2;
%feedbackDuration=1;
moveScale = .1;
imtrlen_ms = imtrialDuration*1000;
imInstruct={'Perform the task as indicated.','Green symbol is the target.','Blue symbol is the prediction','Click to begin.'};
