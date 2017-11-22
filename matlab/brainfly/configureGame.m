useBuffer=true;
useKeyboard=true;

if ( exist('OCTAVE_VERSION') ) debug_on_error(1); else dbstop if error; end;
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

                         % if using the buffer the intialize the connection
if ( useBuffer ...
 && ( ~exist('preConfigured','var') || ~isequal(preConfigured,true) )  ) 
  run ../utilities/initPaths.m;
  % wait for the buffer to return valid header information
  buffhost='localhost'; buffport=1972;
  hdr=[];
  while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
    try 
      hdr=buffer('get_hdr',[],buffhost,buffport); 
    catch
      fprintf('Waiting for header.... Is the amplifier on? Is the buffer-server running?\n');
      hdr=[];
    end;
    pause(1);
  end;
  % set the RTC to use
  initgetwTime;  initsleepSec;
  preConfigured=true;
end

% add path where the standard IM stuff lives
addpath(fullfile(fileparts(mfilename('fullpath')),'..','imaginedMovement'));


verb=0;
buffhost='localhost'; buffport=1972;

% BCI Stim Props
flashColor=[1 1 1]; % the 'flash' color (white)
tgtColor = [.8 .8 .8]; % target cue, light grey
bgColor  = [.5 .5 .5]; % backgroud color, medium grey
cueColor = [0 1 0];
predColor= [0 1 0]; % prediction color
txtColor = [.9 .9 .9]; % color of the cue text
rtColor  = [1 0 0]; % reaction time cue = red
stdColor = [.8 .8 .8]; % standard flash = light-grey
p3tgtColor=[0 0 1]; % p3 target color

rtMax = 2; % max time to react to reaction time task
rtDuration = 1; % time reaction-time stimulus is on the screen
rtInterval = [15 20];% range of times between reaction time tasks

gameFrameDuration = 1/10; % 10hz screen update interval

% how long 1 game level lasts
gameDuration = 90;

% P300 stimulus info
isi   = 1/5;
mintti= [.6 2.0];
oddballp=true; % standard/target type stimulus
stimDuration=isi;

%---------------------------------------------------------------------------------------------------------
% IM calibration config

symbCue      ={'RH' 'LH'}; % sybmol cue in addition to positional one. N.B. start's on **RIGHT** and runs anti-clock-wise
nSymbs       =numel(symbCue); 
baselineClass=[]; % if set, treat baseline phase as a separate class to classify
rtbClass     =[];% if set, treat post-trial return-to-baseline phase as separate class to classify

nSeq              =20*nSymbs; % 20 examples of each target
epochDuration     =.75;% lots of short (750ms/trial) epochs for training the classifier
trialDuration     =epochDuration*3*2; % = 4.5s trials
baselineDuration  =epochDuration*2; % = 1.5s baseline
intertrialDuration=epochDuration*2; % = 1.5s post-trial
feedbackDuration  =epochDuration*2;
errorDuration     =epochDuration*2*2;%= 3s penalty for mistake
calibrateMaxSeqDuration=120;        %= 2min between wait-for-key-breaks

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
dvCalFactor='auto'; % auto-scale the continuous feedback size

%----------------------------------------------------------------------------------------------
% signal-processing configuration
freqband      =[6 8 28 30];
trlen_ms      = max(epochDuration*1000,500); % how much data to take to run the classifier on, min 500ms
calibrateOpts ={};

welch_width_ms=250; % width of welch window => spectral resolution
step_ms=welch_width_ms/2;% N.B. welch defaults=.5 window overlap, use step=width/2 to simulate

epochtrlen_ms =epochFeedbackTrialDuration*1000; % amount of data to apply classifier to in epoch feedback
conttrlen_ms  =welch_width_ms; % amount of data to apply classifier to in continuous feedback

% paramters for on-line adaption to signal changes
adaptHalfLife_ms = 30*1000; %30s amount of data to use for adapting spatialfilter/biasadapt
conttrialAdaptHL =(adaptHalfLife_ms/step_ms); % half-life in number of calls to apply clsfr
epochtrialAdaptHL=(adaptHalfLife_ms/epochtrlen_ms); % half-life in number called to apply-clsfr in epoch feedback
% smoothing parameters for feedback in continuous feedback mode
contFeedbackFiltLen=(trialDuration*1000/step_ms); % accumulate whole trials data before feedback


% global-whiten + direct multi-class training
trainOpts={'width_ms',welch_width_ms,'badtrrm',1,'badchrm',1,'spatialfilter','wht','objFn','mlr_cg','binsp',0,'spMx','1vR'}; 

% adapt-whiten + direct multi-class training
%trainOpts={'width_ms',welch_width_ms,'badtrrm',0,'badchrm',0,'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt' 'covFilt',150},'objFn','mlr_cg','binsp',0,'spMx','1vR'}; 
% Epoch feedback opts
%%0) Use exactly the same classification window for feedback as for training, but include bias adaption system to cope with train->test transfer
earlyStopping = false;
epochFeedbackOpts={'trlen_ms',epochtrlen_ms,'predFilt',@(x,s,e) robustBiasFilt(x,s,epochtrialAdaptHL)}; % bias-adaption
%%2) Classify every welch-window-width (default 250ms), prediction is average of full trials worth of data, bias adaptation on the result
contFeedbackOpts ={'rawpredEventType','classifier.rawprediction','predFilt',@(x,s,e) robustBiasFilt(x,s,[conttrialAdaptHL contFeedbackFiltLen]),'trlen_ms',welch_width_ms};%trlDuration average
