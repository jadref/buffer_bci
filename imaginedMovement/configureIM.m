% guard to prevent running multiple times
if ( exist('imConfig','var') && ~isempty(imConfig) ) return; end;
imConfig=true;

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
initgetwTime();
initsleepSec();

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
nSymbs=3;
nSeq=20;
nBlock=2;%10; % number of stim blocks to use
trialDuration=3;
baselineDuration=1;
intertrialDuration=2;
feedbackDuration=1;
moveScale = .1;
bgColor=[.5 .5 .5];
fixColor=[1 0 0];
tgtColor=[0 1 0];
fbColor=[0 0 1];

% Neurofeedback smoothing
trlen_ms=3000; % how often to run the classifier
trlen_ms_ol=trlen_ms;
expSmoothFactor = log(2)/log(10); % smooth the last 10...