% guard to prevent running multiple times
if ( exist('configRun','var') && ~isempty(configRun) ) return; end;
configRun=true;

run ../utilities/initPaths.m;

buffhost='localhost';buffport=1972;
global ft_buff; ft_buff=struct('host',buffhost,'port',buffport);
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
buffhost='localhost';
buffport=1972;
nSymbs=2; % number of points to move towards, need this many classifier predicitons
baselineDuration=3; % initial base-line time
moveScale = .1;
feedbackEventType='alphaLat';

bgColor=[.5 .5 .5];
fixColor=[1 0 0];
tgtColor=[0 1 0];
fbColor=[0 0 1];

% Neurofeedback smoothing
% how large a time window to use to compute the spectral power
% N.B. frequency resolution = 1/width_ms
width_ms=500; 
freqs=fftBins([],width_ms/1000,hdr.fSample,1);
step_ms =100; % how often to compute the average output, 100ms=10x / s
% parameters to use for feedback
%  freqband = specifies te frequency range to use.
%  electrodes = specifies the set of electrodes to use. One of:
%     [] - empty means average over all electrodes
%     [nElect x 1] - gives a weighting over electrodes
%     {'str'} - gives a list of electrode names to sum together
%               N.B. use -Cz to negate before summing, 
%                  e.g. to feedback on the lateralisation between C3 and C4 use: {'C3' '-C4'}
% 1) frontal alpha lateralisation
feedback = struct('label','alphaLat',...
                  'freqband',[8 12],...
                  'electrodes',{{'FP1' '-FP2'}}); % don't forget double cell for struct
% 2) EMG (= high freq power) + eye (=low freq power)
feedback(2) = struct('label','badness',...
                     'freqband',mkFilter(freqs,[0 0 4 4])*5 + mkFilter(freqs,[15 45]),...
                     'electrodes',{{'FP1' 'FP2'}}); 

% set smoothing rate for the estimated spectral powers
expSmoothFactor = log(2)/log(10); %exp(log(.5)/10)
