configureIM;

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

% make the stimulus display
fig=figure(2);
clf;
set(fig,'Name','Imagined Movement','color',[0 0 0],'menubar','none','toolbar','none','doublebuffer','on');
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');

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
set(h(:),'facecolor',bgColor);
sendEvent('stimulus.testing','start');
drawnow; pause(5); % N.B. pause so fig redraws
% initialize the state so don't miss classifier prediction events
state=buffer('poll'); % get the start time of the stimulus
endTesting=false; dvs=[];
for si=1:nSeq;

  if ( ~ishandle(fig) || endTesting ) break; end;
  
  sleepSec(intertrialDuration);
  % show the screen to alert the subject to trial start
  set(h(:),'faceColor',bgColor);
  set(h(end),'facecolor',fixColor); % red fixation indicates trial about to start/baseline
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');

  % show the target
  fprintf('%d) tgt=%d : ',si,find(tgtSeq(:,si)>0));
  set(h(tgtSeq(:,si)>0),'facecolor',tgtColor);
  set(h(tgtSeq(:,si)<=0),'facecolor',bgColor);
  set(h(end),'facecolor',tgtColor); % green fixation indicates trial running
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  ev=sendEvent('stimulus.target',find(tgtSeq(:,si)>0));
  sendEvent('classifier.apply','now',ev.sample); % tell the classifier to apply from now
  sendEvent('stimulus.trial','start',ev.sample);
  sleepSec(trialDuration); 
  
  % wait for classifier prediction event
  if( verb>0 ) fprintf(1,'Waiting for predictions\n'); end;
  [devents,state,nevents,nsamples]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],500);  

  % do something with the prediction (if there is one), i.e. give feedback
  if( isempty(devents) ) % extract the decision value
    fprintf(1,'Error! no predictions, continuing');
  else
    dv = devents(end).value;
    if ( numel(dv)==1 )
      if ( dv>0 && dv<=nSymbs && isinteger(dv) ) % dvicted symbol, convert to dv equivalent
        tmp=dv; dv=zeros(nSymbs,1); dv(tmp)=1;
      else % binary problem, convert to per-class
        dv=[dv -dv];
      end
    end    
    % give the feedback on the predicted class
    prob=1./(1+exp(-dv)); prob=prob./sum(prob);
    if ( verb>=0 ) 
      fprintf('dv:');fprintf('%5.4f ',dv);fprintf('\t\tProb:');fprintf('%5.4f ',prob);fprintf('\n'); 
    end;  
    [ans,predTgt]=max(dv); % prediction is max classifier output
    set(h(:),'facecolor',bgColor);
    set(h(predTgt),'facecolor',fbColor);
    drawnow;
    sendEvent('stimulus.predTgt',predTgt);
  end % if classifier prediction
  sleepSec(feedbackDuration);
  
  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'facecolor',bgColor);
  % also reset the position of the fixation point
  drawnow;
  sendEvent('stimulus.trial','end');
  
end % loop over sequences in the experiment
% end training marker
sendEvent('stimulus.testing','end');
if ( ishandle(fig) ) % thanks message
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),{'That ends the testing phase.','Thanks for your patience'},'HorizontalAlignment','center','color',[0 1 0],'fontunits','pixel','FontSize',.1*wSize(4));
pause(3);
end
