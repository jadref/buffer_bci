%----------------------------------------------------------------------
% One-Time initialization code
% guard to not run the slow one-time-only config code every time...
if ( ~exist('configRun','var') || isempty(configRun) ) 

  % setup the paths
  run ../utilities/initPaths.m;

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
	 if ( ~isempty(strmatch('qt',available_graphics_toolkits())) )
		graphics_toolkit('qt'); 
	 elseif ( ~isempty(strmatch('qthandles',available_graphics_toolkits())) )
		graphics_toolkit('qthandles'); 
	 elseif ( ~isempty(strmatch('fltk',available_graphics_toolkits())) )
		graphics_toolkit('fltk'); % use fast rendering library
	 end
  end

  % One-time configuration has successfully completed
  configRun=true;
end
%----------------------------------------------------------------------

%----------------------------------------------------------------------
% Application specific config
verb=1;
buffhost='localhost';
buffport=1972;
nSymbs=4; % E,N,S,W  for 2d control
nSeq=20;
trialDuration=3;
baselineDuration=1;
cueDuration=1;
startDelay =.5;
intertrialDuration=2;
feedbackDuration=1;

contFeedbackTrialDuration=10;
neurofeedbackTrialDuration=30;
warpCursor= 0; % flag if in feedback BCI output sets cursor location or how the cursor moves
moveScale = .1;

axLim   =[-1.5 1.5];
bgColor =[.5 .5 .5];
fixColor=[1 0 0];
tgtColor=[0 1 0];
fbColor =[0 0 1];

% classifier training options
trainOpts = {'spType',{{1 3} {2 4}}}; % train 2 classifiers, 1=N vs S, 2=E vs W

% Epoch feedback opts
trlen_ms=trialDuration*1000; % how often to run the classifier
epochFeedbackOpts={'predFilt',@(x,s) biasFilt(x,s,exp(log(.5)/50))};

% different feedback configs (should all give similar results)

%%1) Use exactly the same classification window for feedback as for training, but apply more often
%%   but also include a bias adaption system to cope with train->test transfer
contFeedbackOpts ={'predFilt',@(x,s) biasFilt(x,s,exp(log(.5)/100)),'step_ms',250}; % normal way
stimSmoothFactor= 0; % additional smoothing on the stimulus, not needed with 3s trlen

%%2) Classify every welch-window-width (default 500ms), prediction is average of full trials worth of data, no-bias adaptation
%contFeedbackOpts ={'predFilt',-(trlen_ms/500),'trlen_ms',[]}; % classify every window, prediction is average of last 3s windows
%stimSmoothFactor= 0;% additional smoothing on the stimulus, not needed with equivalent of 3s trlen

%%3) Classify every welch-window-width (default 500ms), 
%contFeedbackOpts ={'predFilt',@(x,s) biasFilt(x,s,exp(log(.5)/400)),'trlen_ms',[]}; % classify every window, bias adapt predictions
%stimSmoothFactor= -(trlen_ms/500);% actual prediction is average of trail-length worth of predictions


%% Center out feedback parameters
centeroutinstruct={'Try to move the cursor to'
						 'the box indicated by the'
						 'green target using the'
						 'calibration mental tasks'
						 ''
						 'Click mouse when ready'};
stimAngle=.5; % percetage of each edge for target
moveStep =.05; % step size for each screen re-draw
%% feedback parameters
centerOutTrialDuration=10;
feedbackMoves=20;
