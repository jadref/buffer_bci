configureIM;

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
% initial fixation point position
fixPos = stimPos(:,end);
trlStartTime=getwTime();
state=[];
trialDuration = 60*60; % 1hr...
timetogo=trialDuration;
dv = zeros(nSymbs,1);
while (timetogo>0)
  if ( ~ishandle(fig) ) break; end;
  timetogo = trialDuration - (getwTime()-trlStartTime); % time left to run in this trial
  % wait for new prediction events to process *or* end of trial
  [events,state,nsamples,nevents] = buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],min(1000,timetogo*1000));

  % process the prediction events
  if ( ~isempty(events) ) 
    [ans,si]=sort([events.sample],'ascend'); % proc in *temporal* order
    for ei=1:numel(events);
      ev=events(si(ei));% event to process
      pred=ev.value;
      % now do something with the prediction....
      if ( numel(pred)==1 )
        if ( pred>0 && pred<=nSymbs && isinteger(pred) ) % predicted symbol, convert to dv
          tmp=pred; pred=zeros(nSymbs,1); pred(tmp)=1;
        else % binary problem
          pred=[pred -pred];
        end
      end
      dv = expSmoothFactor*dv + pred(:);
      prob = 1./(1+exp(-dv(:))); prob=prob./sum(prob); % convert from dv to normalised probability
      if ( verb>=0 ) 
        fprintf('%d) dv:',ev.sample);fprintf('%5.4f ',pred);fprintf('\t\tProb:');fprintf('%5.4f ',prob);fprintf('\n'); 
      end;
      
      % feedback information... simply move to location indicated by the BCI
      fixPos = stimPos(:,1:end-1)*prob(:); % position is weighted by class probabilties
      set(h(end),'position',[fixPos-stimRadius/2;stimRadius/2*[1;1]]);
    end
  end % if prediction events to processa  
  drawnow; % update the display after all events processed
end % loop over epochs in the sequence

% end training marker
sendEvent('stimulus.testing','end');
