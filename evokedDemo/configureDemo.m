% guard to prevent running multiple times
%if ( exist('runConfig','var') && ~isempty(runConfig) ) return; end;
%runConfig=true;
run ../utilities/initPaths.m;

buffhost='localhost';buffport=1972;
global ft_buff; ft_buff=struct('host',buffhost,'port',buffport);
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

%capFile='cap_tmsi_mobita_black';%'1010'; %'emotiv';%cap_tmsi_mobita_im2'; N.B. use 1010 for emotiv so non-eeg are labelled correctly
verb=0;
buffhost='localhost'; buffport=1972;

verb=0;
nSeq=15;
nRepetitions=5;  % the number of complete row/col stimulus before sequence is finished
cueDuration=3;
stimDuration=.15;% the length a row/col is highlighted
interSeqDuration=2;
feedbackDuration=5;
stimRadius=.6;

ssvepFreq = [15 7.5 10 20 30];
isi=1/60;
flickerFreq=[15 20];

nSymbs=2;
trialDuration=8;
baselineDuration=2;
intertrialDuration=2;
bgColor=[.1 .1 .1]; % background color (grey)
tgtColor=[0 1 0]; % the target indication color (green)
flashColor=[1 1 1]; % the 'flash' color (white)
fixColor=[1 0 0];
trlen_ms=1000;

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

% the set of options the user will pick from
symbols={'1' '2' '3';...
         '4' '5' '6';...
         '7' '8' '9'}';

% PTB stuff
windowPos=[0 0 500 500]; %[];% in sub-window set to [] for full screen