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
	 if ( ~isempty(strmatch('qthandles',available_graphics_toolkits())) )
		graphics_toolkit('qthandles'); 
	 elseif ( ~isempty(strmatch('qt',available_graphics_toolkits())) )
		graphics_toolkit('qt'); 
	 elseif ( ~isempty(strmatch('fltk',available_graphics_toolkits())) )
		graphics_toolkit('fltk'); % use fast rendering library
	 end
  end

  % One-time configuration has successfully completed
  configRun=true;
end

%----------------------------------------------------------------------
% Application specific config
verb         =1; % verbosity level for debug messages, 1=default, 0=quiet, 2=very verbose
buffhost     ='localhost';
buffport     =1972;

% N.B. start's on **RIGHT** (3 o'clock=East) and runs anti-clock-wise for *EVEN* numbers of targets
%      start on **TOP** (12 o'clock=North) and run anti-clockwise for *ODD* numbers targets
% 3-[N,SW,SE], 4-[E,N,W,S], 6-[E,NE,NW,W,SW,SE], 8-[E,NE,N,NW,W,SW,S,SE]
symbCue      ={'FT' 'LH' 'RH'}; % sybmol cue / class name 
nSymbs       =numel(symbCue); 
baselineClass='99 Rest'; % if set, treat baseline phase as a separate class to classify
rtbClass     ='99 RTB';  % if set, treat post-trial return-to-baseline phase as separate class to classify

nSeq              =20*nSymbs; % 20 examples of each target
epochDuration     =.75;% lots of short (750ms/trial) epochs for training the classifier
trialDuration     =epochDuration*3*2; % = 4.5s trials
baselineDuration  =epochDuration*2; % = 1.5s baseline
intertrialDuration=epochDuration*2; % = 1.5s post-trial
feedbackDuration  =epochDuration*2;
errorDuration     =epochDuration*2*2;%= 3s penalty for mistake
calibrateMaxSeqDuration=120;        %= 2min between wait-for-key-breaks


warpCursor   = 0; % flag if in feedback BCI output sets cursor location or how the cursor moves
moveScale    = .1;
dvCalFactor  = []; % calibration factor to re-scale classifier decsion values to true probabilities
feedbackMagFactor=1;% max factor for feedback in center-out

axLim        =[-1.5 1.5]; % size of the display axes
winColor     =[.0 .0 .0]; % window background color
bgColor      =[.2 .2 .2]; % background/inactive stimuli color
fixColor     =[.8  0  0]; % fixitation/get-ready cue point color
tgtColor     =[0  .7  0]; % target color (N.B. green is perceptually brighter, so lower)
fbColor      =[0   0 .8]; % feedback color = blue
txtColor     =[.9 .9 .9]; % color of the cue text
errorColor   =[.8  0  0]; % error feedback color

animateFix   = true; % do we animate the fixation point during training?
frameDuration= .25; % time between re-draws when animating the fixation point
animateStep  = diff(axLim)*.01; % amount by which to move point per-frame in fix animation

%----------------------------------------------------------------------------------------------
% stimulus type specific configuration
calibrate_instruct ={'When instructed perform the indicated' 'actual movement'};

epochfeedback_instruct={'When instructed perform the indicated' 'actual movement.  When trial is done ' 'classifier prediction with be shown' 'with a blue highlight'};
epochFeedbackTrialDuration=trialDuration;

contfeedback_instruct={'When instructed perform the indicated' 'actual movement.  The fixation point' 'will move to show the systems' 'current prediction'};
contFeedbackTrialDuration =10;

neurofeedback_instruct={'Perform mental tasks as you would like.' 'The fixation point will move to' 'show the systems current prediction'};
neurofeedbackTrialDuration=30;

centerout_instruct={'Complete the indicated tasks as rapidly as possible.' 'The fixation point will move to' 'show the current prediction' 'Trials end when fixation hits the target' 'or time runs out.' 'Hitting the wrong target incurs a time penalty'};
earlyStoppingFilt=[]; % dv-filter to determine when a trial has ended
%earlyStoppingFilt=@(x,s,e) gausOutlierFilt(x,s,2); % dv-filter to determine when a trial has ended

%----------------------------------------------------------------------------------------------
% classifier training configuration
freqband      =[6 8 28 30];
trlen_ms      = max(epochDuration*1000,500); % how much data to take to run the classifier on, min 500ms
calibrateOpts ={};

welch_width_ms=250; % width of welch window => spectral resolution
step_ms=welch_width_ms/2;% N.B. welch defaults=.5 window overlap, use step=width/2 to simulate

epochtrlen_ms =epochFeedbackTrialDuration*1000; % amount of data to apply classifier to in epoch feedback
conttrlen_ms  =welch_width_ms; % amount of data to apply classifier to in continuous feedback

% smoothing parameters for feedback in continuous feedback mode
contFeedbackFiltLen=(trialDuration*1000/step_ms); % accumulate whole trials data before feedback
contFeedbackFiltFactor=exp(log(.5)/contFeedbackFiltLen); % convert to exp-move-ave weighting factor

% paramters for on-line adaption to signal changes
adaptHalfLife_s = 30; %30s amount of data to use for adapting spatialfilter/biasadapt
adaptHalfLife_samp = adaptHalfLife_s * 250; % HL in samples, N.B. assuming 250hz sample rate!
% half-life in number called to apply-clsfr in epoch feedback, for epoch feedback
epochtrialAdaptHL_apply=max(adaptHalfLife_s*1000/epochtrlen_ms,2*nSymbs);  % HL should be enough to include at least 1 example each class
epochtrialAdaptFactor=exp(log(.5)/epochtrialAdaptHL_apply);% convert to exp-move-ave weight factor
% half-life in number of calls to apply clsfr for continuous feedback
conttrialAdaptHL_apply = max(adaptHalfLife_s*1000,contFeedbackTrialDuration*2*nSymbs*1000)/step_ms;         
conttrialAdaptFactor=exp(log(.5)./conttrialAdaptHL_apply) ;% convert to exp-move-ave weighting factor 

%-----------------------------------------------------------
% Classifier training / application options
%trainOpts={'width_ms',welch_width_ms,'badtrrm',0}; % default: 4hz res, stack of independent one-vs-rest classifiers
trainOpts={'width_ms',welch_width_ms,'badtrrm',0,'spatialfilter','car+wht','objFn','mlr_cg','binsp',0,'spMx','1vR'}; % whiten + direct multi-class training
%trainOpts={'width_ms',welch_width_ms,'badtrrm',0,'spatialfilter','car','adaptspatialfiltFn','adaptWhitenFilt','objFn','mlr_cg','binsp',0,'spMx','1vR'}; % adaptive-whiten + direct multi-class training
%trainOpts={'width_ms',welch_width_ms,'badtrrm',0,'spatialfilter','adaptspatialfilt','adaptspatialfiltFn',{'artChRegress',[],{'EOG' 'AFz' 'EMG' 'AF3' 'FP1' 'FPz' 'FP2' 'AF4' '1/f'}},'objFn','mlr_cg','binsp',0,'spMx','1vR'}; % eog-removal + direct multi-class training
%trainOpts={'width_ms',welch_width_ms,'badtrrm',0,'spatialfilter','adaptspatialfilt','adaptspatialfiltFn',{'rmEMGFilt',[]},'objFn','mlr_cg','binsp',0,'spMx','1vR'}; % emg-removal + direct multi-class training
%trainOpts={'width_ms',welch_width_ms,'badtrrm',0,'spatialfilter','adaptspatialfilt','adaptspatialfiltFn',{'filtPipeline' {'rmEMGFilt' []} {'artChRegress',[],{'EOG' 'AFz' 'EMG' 'AF3' 'FP1' 'FPz' 'FP2' 'AF4' '1/f'}}},'objFn','mlr_cg','binsp',0,'spMx','1vR'}; % (emg-removal->eog-removal) + direct multi-class training
%trainOpts = {'spType',{{1 3} {2 4}}}; % train 2 classifiers, 1=N vs S, 2=E vs W

%-----------------------------------------------------------
% Epoch feedback opts
%%0) Use exactly the same classification window for feedback as for training, but
%%   but also include a bias adaption system to cope with train->test transfer
earlyStopping = false;
epochFeedbackOpts={'trlen_ms',epochtrlen_ms}; % raw output, from whole trials data
epochFeedbackOpts={'trlen_ms',epochtrlen_ms,'predFilt',@(x,s,e) biasFilt(x,s,epochtrialAdaptFactor)}; % bias-adaption

% Epoch feedback with early-stopping, config using the user feedback table
userFeedbackTable={'epochFeedback_es' 'cont' {'predFilt',@(x,s,e) gausOutlierFilt(x,s,2.5*8,trlen_ms./step_ms),'trlen_ms',welch_width_ms}}; 

% different feedback configs (should all give similar results)

%-----------------------------------------------------------
% continuous feedback options
%%1) Use exactly the same classification window for feedback as for training, but apply more often
%contFeedbackOpts ={'step_ms',welch_width_ms}; % apply classifier more often
%%   but also include a bias adaption system to cope with train->test transfer
%contFeedbackOpts ={'predFilt',@(x,s,e) biasFilt(x,s,exp(log(.5)/100)),'step_ms',250};
dvFilt= 0; % additional filtering of the decision value smoothing on the stimulus, not needed with 3s trlen

%%2) Classify every welch-window-width (default 250ms), prediction is average of full trials worth of data, no-bias adaptation
%% N.B. this is numerically identical to option 1) above, but computationally *much* cheaper 
%% Also send all raw predictions out for use in, e.g. center-out training
contFeedbackOpts ={'rawpredEventType','classifier.rawprediction','predFilt',-contFeedbackFiltLen,'trlen_ms',welch_width_ms}; % trlDuration average
% as above but include an additional bias-adaption as well as classifier output smoothing
contFeedbackOpts ={'rawpredEventType','classifier.rawprediction','predFilt',@(x,s,e) robustBiasFilt(x,s,[conttrialAdaptFactor_apply contFeedbackFiltFactor]),'trlen_ms',welch_width_ms}; % trlDuration average

%%3) Classify every welch-window-width (default 500ms), with bias-adaptation
%contFeedbackOpts ={'predFilt',@(x,s,e) biasFilt(x,s,exp(log(.5)/400)),'trlen_ms',[]}; 
%dvFilt= -(trlen_ms/500);% actual prediction is average of trail-length worth of predictions
