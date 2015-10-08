% guard to prevent running multiple times
if ( exist('spConfig','var') && ~isempty(spConfig) ) return; end;
run ../utilities/initPaths.m;
run ../utilities/initPTBPaths.m;
spConfig=true;

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

if ( exist('OCTAVE_VERSION','builtin') ) 
  page_output_immediately(1); % prevent buffering output
  if ( ~isempty(strmatch('qthandles',available_graphics_toolkits())) )
    graphics_toolkit('qthandles'); % use fast rendering library
  elseif ( ~isempty(strmatch('fltk',available_graphics_toolkits())) )
    graphics_toolkit('fltk'); % use fast rendering library
  end
end


% set the real-time-clock to use
initgetwTime;
initsleepSec;

verb=1;
nSeq=5;%15;%
nRepetitions=5;  % the number of complete row/col stimulus before sequence is finished
cueDuration=2;
isi         =.15;% inter stimulus duration
stimDuration=isi; %.15; % the length a row/col is highlighted
tti         =.6;% minium time between target letter highlights
interSeqDuration=2;
feedbackDuration=5;
bgColor=[.1 .1 .1]; % background color (grey)
flashColor=[1 1 1]; % the 'flash' color (white)
tgtColor=[0 1 0]; % the target indication color (green)

% the set of options the user will pick from
symbols={'1' '2' '3';...
         '4' '5' '6';...
         '7' '8' '9'}';
vnRows=max(size(symbols,1),ceil(tti/isi));
vnCols=max(size(symbols,2),ceil(tti/isi));     
symbSize=.1;

trlen_ms=600;

% PTB stuff
windowPos=[0 0 500 500]; % in sub-window set to [] for full screen
