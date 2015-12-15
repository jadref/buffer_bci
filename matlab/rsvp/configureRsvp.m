%----------------------------------------------------------------------
% One-Time initialization code
% guard to not run the slow one-time-only config code every time...
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

nSeq = 6;
trainSeqDuration = 20;
testSeqDuration  = 60;
isi              = 1/5; % run at 5hz  (N.B. flash rate is 1/2 this as must turn off...)
mintti           = isi*2*3;   % flash at most every 1/2 second
oddballp         = true;false; % make oddball stim, i.e. 3 levels, [bg=0, std=2, odd/tgt=1]

% Pyschophysics bits
testType         = 'color'; % 'images';
imagesDir        = 'compression';
pcorrect         = .5;   % target correct discrimination rate
hitmissstep      = 1;    % require 2 hits to change the alpha by one

baselineDuration = 2;
targetDuration   = 1;
postTargetDuration=1;
interSeqDuration = 1;

colors=[0  1  0;...   % oddball - green
        .7 .7 .7]';   % std - gray approx iso-luminant
alphas = linspace(0,1,25); % 50 levels of graduation to search in on-line

framebgColor=[0 0 0]; % black
bgColor    = [.5 .5 .5]; % grey - background state
fixColor   = [1 0 0]; % Red   - get-ready/baseline
tgtColor   = [0 1 0]; % Green - target

axlim      = [-1 1; -1 1]'; % axes limits for the main drawing axes [xmin xmax; ymin ymax]
stimRadius = .5; % size of the central dot, in axes units

instructstr={'Look on the central dot.' 'Count how many times it changes color.' '' 'Good luck!'};
