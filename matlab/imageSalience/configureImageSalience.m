%----------------------------------------------------------------------
% One-Time initialization code
% guard to not run the slow one-time-only config code every time...
if ( ~exist('configRun','var') || isempty(configRun) ) 

  %% % backup path init code
  %% mfiledir = fileparts(mfilename('fullpath'));
  %% cd(mfiledir)
  %% run ../../utilities/initPaths.m;
  %% cd(mfiledir)

  % setup the paths
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

  if ( exist('OCTAVE_VERSION','builtin') ) 
	 page_output_immediately(1); % prevent buffering output
	 if ( ~isempty(strmatch('qthandles',available_graphics_toolkits())) )
		graphics_toolkit('qthandles'); % use fast rendering library
	 elseif ( ~isempty(strmatch('fltk',available_graphics_toolkits())) )
		graphics_toolkit('fltk'); % use fast rendering library
	 end
  end

  % One-time configuration has successfully completed
  configRun=true;
end
%-------------------------------------------

%==========================================================================
% 2. SET 'GLOBAL' EXPERIMENT VARIABLES
%==========================================================================

verb=1; % verbosity level for debug info

tgtDir ='pictures/targets';
testDir='pictures/test';
distDir='pictures/distractors';
faceDir='pictures/faces';

nSeq = 6;
trainSeqDuration = 20;
testSeqDuration  = 60;
tti              = 5; % average number flashes between target flashes

textDuration=5;
countdownDuration=3;
targetDuration=5;
postTargetDuration=1;
stimDuration=0.10;
whiteSquareDuration=0.10;
interSeqDuration=1;
trainSeqLen= ceil(trainSeqDuration/(stimDuration+whiteSquareDuration)); 
testSeqLen = ceil(testSeqDuration/(stimDuration+whiteSquareDuration));  


framebgColor     = [0 0 0];
whiteSquareColor = [1 1 1];
axlim            = [0 1; 0 1]'; % axes limits for the main drawing axes [xmin xmax; ymin ymax]
pieceLocation    = [0 0 1 1]; % rectangle saying where the image should be
