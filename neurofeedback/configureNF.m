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
moveScale = .1;
bgColor=[.5 .5 .5];
fixColor=[1 0 0];
tgtColor=[0 1 0];
fbColor=[0 0 1];

% Neurofeedback smoothing
% how large a time window to use to compute the spectral power
% N.B. frequency resolution = 1/width_ms
width_ms=500; 
step_ms =100; % how often to compute the average output
% compute the frequencies we have access to for feedback
freqs=fftBins([],width_ms/1000,hdr.fSample,1);
% parameters to use for feedback
%  freqband = specifies te frequency range to use.
%  electrodes = specifies the set of electrodes to use. One of:
%     [] - empty means average over all electrodes
%     [nElect x 1] - gives a weighting over electrodes
%     {'str'} - gives a list of electrode names to sum together
%               N.B. use -Cz to negate before summing, 
%                  e.g. to feedback on the lateralisation between C3 and C4 use: {'C3' '-C4'}
% 1) whole head alpha
feedback(1).freqband = [8 12]; % alpha
feedback(1).electrodes= []; % [] = all electrodes, otherwise
% 2) hand region lateralisation: C3 - C4
feedback(2) = struct('freqband',[10 14],'electrodes',{'C3' '-C4'}); 
% 3) beta power in Cz (central motor strip)
feedback(3) = struct('freqband',[18 24],'electrodes',{'Cz'}); 

% set smoothing rate for the estimated spectral powers
expSmoothFactor = log(2)/log(10); 
