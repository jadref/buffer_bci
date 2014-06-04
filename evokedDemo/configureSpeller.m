% guard to prevent running multiple times
if ( exist('configSpeller','var') && ~isempty(configSepller) ) return; end;
configSpeller=true;

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

verb=0;
nSeq=15;
nRepetitions=5;  % the number of complete row/col stimulus before sequence is finished
cueDuration=2;
stimDuration=.15; % the length a row/col is highlighted
dataDuration=.6;  % amount of data used for classifier
interSeqDuration=2;
feedbackDuration=5;
bgColor=[.5 .5 .5]; % background color (grey)
flashColor=[1 1 1]; % the 'flash' color (white)
tgtColor=[0 1 0]; % the target indication color (green)

% the set of options the user will pick from
symbols={'1' '2' '3';...
         '4' '5' '6';...
         '7' '8' '9'}';
symbSize=.1;

trlen_ms=600;