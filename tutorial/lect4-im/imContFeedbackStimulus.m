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
initsleepSec;

% constants
nSymbs=3;
nSeq=15;
trialDuration=3;
baselineDuration=1;
intertrialDuration=2;
expSmoothFactor=1; % smoothing factor for combining classifier outputs over time

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

clf;
fig=gcf;
set(fig,'Name','Imagined Movement -- close window to stop.','color',[0 0 0],'menubar','none','toolbar','none','doublebuffer','on');
stimPos=[]; h=[];
stimRadius=.5;
theta=linspace(0,pi,nSymbs); stimPos=[cos(theta);sin(theta)];
for hi=1:nSymbs; 
  h(hi)=rectangle('curvature',[1 1],'position',[stimPos(:,hi)-stimRadius/2;stimRadius*[1;1]],...
                  'facecolor',bgColor); 
end;
% add symbol for the center of the screen
stimPos(:,nSymbs+1)=[0 0];
h(nSymbs+1)=rectangle('curvature',[1 1],'position',[stimPos(:,end)-stimRadius/4;stimRadius/2*[1;1]],...
                      'facecolor',bgColor); 
set(gca,'visible','off');


% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'facecolor',bgColor);
sendEvent('stimulus.testing','start');
  
% show the screen to alert the subject to trial start
set(h(:),'faceColor',bgColor);
set(h(end),'facecolor',fixColor); % red fixation indicates trial about to start/baseline
drawnow;% expose; % N.B. needs a full drawnow for some reason
sendEvent('stimulus.baseline','start');
sleepSec(baselineDuration);
sendEvent('stimulus.baseline','end');
set(h(:),'faceColor',bgColor);
drawnow;% expose; % N.B. needs a full drawnow for some reason

% for the trial duration update the fixatation point in response to prediction events
nevents=hdr.nEvents; nsamples=hdr.nSamples;
state  =[];

for si=1:nSeq;
  if ( ~ishandle(fig) ) break; end;
  
  sleepSec(intertrialDuration);
  % show the screen to alert the subject to trial start
  set(h(end),'facecolor',fixColor); % red fixation indicates trial about to start/baseline
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');
  

  % record information about when the trial started
  trlStartTime=getwTime();
  timetogo=trialDuration;
  dv = zeros(nSymbs,1); % accumulated classifier information
  while (timetogo>0)
    if ( ~ishandle(fig) ) break; end;
    timetogo = trialDuration - (getwTime()-trlStartTime); % time left to run in this trial
    % wait for prediction events to process *or* end of trial
    [predevents,state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],timetogo);
    
    if ( ~isempty(predevents) ) 
      [ans,si]=sort([predevents.sample],'ascend'); % proc in *temporal* order
      for ei=1:numel(predevents);
        ev=predevents(si(ei));% event to process
        pred=ev.value;
        dv = expSmoothFactor*dv + pred(:); % exp-smoothed weighted average of classifier output
        prob = 1./(1+exp(-dv(:))); prob=prob./sum(prob); % convert from dv to normalised probability
        
        % feedback... simply move to location indicated by the BCI
        fixPos = stimPos(:,1:end-1)*prob(:); % position is weighted by class probabilties
        set(h(end),'position',[fixPos-stimRadius/2;stimRadius/2*[1;1]]);
      end
      drawnow; % update the display after all events processed
    end % if prediction events to processa  
  end % trial duration
  
  % reset the cue and fixation point to indicate trial has finished  
  % reset fixation point position
  fixPos = stimPos(:,end);
  set(h(end),'position',[fixPos-stimRadius/2;stimRadius/2*[1;1]]);
  set(h(:),'facecolor',bgColor);
  drawnow;
  sendEvent('stimulus.trial','end');  
end % epochs in the sequence

% end training marker
sendEvent('stimulus.testing','end');
