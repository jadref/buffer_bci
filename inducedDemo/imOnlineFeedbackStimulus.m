if ( ~exist('imConfig','var') || ~imConfig ) configureIM; end;

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

clf;
fig=gcf;
set(fig,'Name','Imagined Movement','color',[0 0 0],'menubar','none','toolbar','none','doublebuffer','on');
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');%,'DataAspectRatio',[1 1 1]);
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
for si=1:nSeq;

  if ( ~ishandle(fig) ) break; end;
  
  sleepSec(intertrialDuration);
  % show the screen to alert the subject to trial start
  set(h(end),'facecolor',fixColor); % red fixation indicates trial about to start/baseline
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');

  % show the target
  fprintf('%d) tgt=%d : ',si,find(tgtSeq(:,si)>0));
  set(h(tgtSeq(:,si)>0),'facecolor',tgtColor);
  set(h(tgtSeq(:,si)<=0),'facecolor',bgColor);
  set(h(end),'facecolor',[0 1 0]); % green fixation indicates trial running
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.target',find(tgtSeq(:,si)>0));
  sendEvent('stimulus.trial','start');
  
  % for the trial duration update the fixatation point in response to prediction events
  status=buffer('wait_dat',[-1 -1 -1],buffhost,buffport); % get current state
  nevents=status.nevents; nsamples=status.nsamples;
  % initial fixation point position
  fixPos = stimPos(:,end);
  trlStartTime=getwTime();
  timetogo = trialDuration;
  while (timetogo>0)
    timetogo = trialDuration - (getwTime()-trlStartTime); % time left to run in this trial
    % wait for events to process *or* end of trial
    status=buffer('wait_dat',[-1 -1 timetogo*1000/4],buffhost,buffport); 
    if ( status.nevents > nevents ) % new events to process
      events=[];
      if (status.nevents>nevents) events=buffer('get_evt',[nevents status.nevents-1],buffhost,buffport); end;
      mi    =matchEvents(events,{'stimulus.prediction'});
      predevents=events(mi);
      % make a random testing event
      if ( 0 ) predevents=struct('type','stimulus.prediction','sample',0,'value',ceil(rand()*nSymbs+eps)); end;
      if ( ~isempty(predevents) ) 
        [ans,si]=sort([predevents.sample],'ascend'); % proc in *temporal* order
        for ei=1:numel(predevents);
          ev=predevents(si(ei));% event to process
          pred=ev.value;
          % now do something with the prediction....
          if ( numel(pred)==1 )
            if ( isinteger(pred) ) % predicted symbol, convert to dv equivalent
              tmp=pred; pred=zeros(nSymbs,1); pred(tmp)=1;
            else % binary class result
              pred=[pred; -pred];
            end
          end
          prob = 1./(1+exp(-pred)); prob=prob./sum(prob); % convert from dv to normalised probability
          if ( verb>0 ) fprintf('Prob:');fprintf('%5.4f ',prob);fprintf('\n'); end;
          
          % feedback information... simply move in direction detected by the BCI
          dx = stimPos(:,1:end-1)*prob(1:nSymbs); % change in position is weighted by class probs
          fixPos = fixPos + dx*moveScale;
          set(h(end),'position',[fixPos-stimRadius/2;stimRadius/2*[1;1]]);
        end
        drawnow; % update the display after all events processed
      end % prediction events to processa  
    end % if feedback events to process
    
  end % loop over epochs in the sequence

  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'facecolor',bgColor);
  % also reset the position of the fixation point
  set(h(end),'position',[stimPos(:,end)-stimRadius/4;stimRadius/2*[1;1]]);
  drawnow;
  sendEvent('stimulus.trial','end');
  
  fprintf('\n');
end % loop over sequences in the experiment
% end training marker
sendEvent('stimulus.testing','end');
% thanks message
text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),{'That ends the testing phase.','Thanks for your patience'},'HorizontalAlignment','center','color',[0 1 0],'fontunits','normalized','FontSize',.1);
pause(3);
