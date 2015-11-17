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
	 if ( ~isempty(strmatch('qthandles',available_graphics_toolkits())) )
		graphics_toolkit('qthandles'); % use fast rendering library
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
nSymbs=9;
nSeq=45;
trialDuration=3;
baselineDuration=1;
intertrialDuration=2;
feedbackDuration=1;

conditions={
'Right Hand'
'Right Hand + Tongue'
'Tongue'
'Left Hand + Tongue'
'Left Hand'
'Left Hand + Feet'
'Feet'
'Right Hand + Feet'
'Left Hand + Right Hand'
'Rest'
};

warpCursor= 1; % flag if in feedback BCI output sets cursor location or how the cursor moves
moveScale = .1;

bgColor =[.5 .5 .5];
fixColor=[1 0 0];
tgtColor=[0 1 0];
fbColor =[0 0 1];

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
