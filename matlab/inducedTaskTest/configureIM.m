%----------------------------------------------------------------------
% One-Time initialization code
% guard to not run the slow one-time-only config code every time...
if ( ~exist('configRun','var') || isempty(configRun) ) 

  % setup the paths
  run ../utilities/initPaths.m;

  buffhost='localhost';buffport=1972;
  % wait for the buffer to return valid header information
  hdr=[];
  while( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) %wait for the buffer to contain valid data
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
verb         =1; % verbosity level for debug messages, 1=default, 0=quiet, 2=very verbose
buffhost     ='localhost';
buffport     =1972;
nSymbs       =6; % E,NE,NW,W,SW,SE,E for 6 outputs
symbCue      ={'RH' 'Tongue' 'Nav' 'LH' 'Math' 'Feet'};
baselineClass=[]; % 'Rest';if set, treat baseline phase as a separate class to classify
nSeq         =20*nSymbs; % 20 examples of each target

trialDuration=4.5;
baselineDuration=1.5;
cueDuration  =1.5;
startDelay   =.5;
intertrialDuration=0;%3.5
feedbackDuration=1;

contFeedbackTrialDuration =10;
neurofeedbackTrialDuration=30;
warpCursor   = 0; % flag if in feedback BCI output sets cursor location or how the cursor moves
moveScale    = .1;

axLim        =[-1.5 1.5]; % size of the display axes
winColor     =[0 0 0]; % window background color
bgColor      =[.5 .5 .5]; % background/inactive stimuli color
fixColor     =[1 0 0]; % fixitation/get-ready cue point color
tgtColor     =[0 1 0]; % target color
fbColor      =[0 0 1]; % feedback color
txtColor     =[.8 .8 .8]; % text color

% classifier training options
trlen_ms      =trialDuration*1000; % how often to run the classifier
calibrateOpts ={};

welch_width_ms=250; % width of welch window => spectral resolution
%trainOpts={'width_ms',welch_width_ms,'badtrrm',0}; % default: 4hz res, stack of independent one-vs-rest classifiers
trainOpts={'width_ms',welch_width_ms,'badtrrm',0,'spatialfilter','wht','objFn','lr_cg','binsp',1,'spMx','1v1'}; % all-pairwise training

% Epoch feedback opts
%%0) Use exactly the same classification window for feedback as for training, but
%%   but also include a bias adaption system to cope with train->test transfer
epochFeedbackOpts={}; % raw output
%epochFeedbackOpts={'predFilt',@(x,s) biasFilt(x,s,exp(log(.5)/50))}; % bias-apaption

% different feedback configs (should all give similar results)

%%1) Use exactly the same classification window for feedback as for training, but apply more often
%contFeedbackOpts ={'step_ms',welch_width_ms}; % apply classifier more often
%%   but also include a bias adaption system to cope with train->test transfer
%contFeedbackOpts ={'predFilt',@(x,s) biasFilt(x,s,exp(log(.5)/100)),'step_ms',250};
stimSmoothFactor= 0; % additional smoothing on the stimulus, not needed with 3s trlen

%%2) Classify every welch-window-width (default 250ms), prediction is average of full trials worth of data, no-bias adaptation
%% N.B. this is numerically identical to option 1) above, but computationally *much* cheaper 
step_ms=welch_width_ms/2;% N.B. welch defaults=.5 window overlap, use step=width/2 to simulate
contFeedbackOpts ={'predFilt',-(trlen_ms/step_ms),'trlen_ms',welch_width_ms};


%%3) Classify every welch-window-width (default 500ms), with bias-adaptation
%contFeedbackOpts ={'predFilt',@(x,s) biasFilt(x,s,exp(log(.5)/400)),'trlen_ms',[]}; 
%stimSmoothFactor= -(trlen_ms/500);% actual prediction is average of trail-length worth of predictions
