% uncomment to set into testing mode
global TESTING;TESTING=true

if ( exist('OCTAVE_VERSION','builtin') ) % octave specific
  page_screen_output(0); %prevent paging of output..
  page_output_immediately(1); % prevent buffering output
  debug_on_error(1);
else 
  dbstop if error; 
end
% guard to prevent running multiple times
if ( ~exist('configRun','var') || isempty(configRun) ) 

  run ../utilities/initPaths.m;

  buffhost='localhost';buffport=1972;
  global ft_buff; ft_buff=struct('host',buffhost,'port',buffport);
  % wait for the buffer to return valid header information
  global TESTING;
  if ( ~TESTING ) 
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
  end

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

verb=1;
nSeq=8;
baselineDuration=1;  % duration of the 'get-ready' indicator
cueDuration =1;      % duration the target remains on the screen
seqDuration =6;      % duration of 1 stimulus sequence for calibration
startDelay  =.5;     % delay after cue goes away before starting the stimulus
interSeqDuration=.5; % rest gap between sequences
seqEndDuration  =.6; % pause with stim-on screen at end of sequence

arrowScale=[.4 1.0];
sizeStim = 1.5;
bgColor=[.5 .5 .5]; % background color (grey)
flashColor=[1 1 1]; % the 'flash' color (white)
tgtColor=[0 1 0]; % the target indication color (green)
tgt2Color= [1 0 0];
edgeColor=[1 1 1];
fixColor=[1 0 0];
axLim=[-1 1];

instructstr={'Look at the indicated green circle' 'and count the number of times it changes color.'};

trlen_ms=750; % longer to allow for movement/blink signature

% BCI Stim Props
nSymbs   = 8;
stimType = 'ssvep';%'noise-psk';%'p3-90'; %'pseudorand';%'p3';%'p3-radial';%'p3-90';%'noise-psk';%
isi      = 1/60;
tti      =.5; % target to target interval
% N.B. to get integer num cycles in 3s = freq resolution is 1/3Hz up to .5/isi
%      to get integer period then 1/isi/freq should be integer
ssepFreq = [10 11+2/3 13+1/3 15 10 11+2/3 13+1/3 15];
ssepPhase= 2*pi*[0 0 0 0 .5 .5 .5 .5];

