% Do a simple cursor-on-the-screen neurofeedback stimulus 
% 
% 4 cursor control modes are available:
%   probability -- feedback gives probability for each of the targets which weight together to give cursor position
%   cursor      -- feedback gives probability in x and y directions.
%   cursor-sum  -- feedback gives incrment in x and y directions
configureNF;

clf;
fig=gcf;
set(fig,'Name','Neuro-feedback stimulus -- close window to stop.','menubar','none','toolbar','none','doublebuffer','on');
axes('position',[0.07 0.1 .825 .85],'units','normalized','DrawMode','fast','nextplot','replacechildren',...
     'xlim',[-1 1],'ylim',[-1 1]);%,'DataAspectRatio',[1 1 1]);
stimPos=[]; h=[];
stimRadius=.5;
if ( strcmp(lower(controlMode),'probability') )
  set(fig,'color',[0 0 0]);
  set(gca,'visible','off','box','off',...
       'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
       'color',[0 0 0]);
  theta=linspace(0,pi,nSymbs); stimPos=[cos(theta);sin(theta)];
  for hi=1:nSymbs; 
    h(hi)=rectangle('curvature',[1 1],'position',[stimPos(:,hi)-stimRadius/2;stimRadius*[1;1]],...
                  'facecolor',bgColor); 
  end;
  set(gca,'visible','off');
end
% add symbol for the center of the screen
stimPos(:,end+1)=[0 0];
h(size(stimPos,2))=rectangle('curvature',[1 1],'position',[stimPos(:,end)-stimRadius/4;stimRadius/2*[1;1]],...
                             'facecolor',bgColor); 

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
  [events,state,nsamples,nevents] = buffer_newevents(buffhost,buffport,state,feedbackEventType,[],min(1000,timetogo*1000));
  if ( isempty(events) && verb>=0 ) fprintf('%d) Prediction timeout!\n',nsamples); end;
  
  % process the prediction events
  if ( ~isempty(events) ) 
    [ans,si]=sort([events.sample],'ascend'); % proc in *temporal* order
    for ei=1:numel(events);
      ev=events(si(ei));% event to process
      pred=ev.value;
      if ( numel(pred)==1 && nSymbs==2 ) pred(end+1)=1-pred; end;
      % now do something with the prediction....
      dv = stimulusSmoothFactor(1)*dv + (1-stimulusSmoothFactor(1))*pred(:); % apply a further smoothing factor
      prob = 1./(1+exp(-dv(:))); prob=prob./sum(prob); % convert from dv to normalised probability
      if ( verb>=0 ) 
        fprintf('%2d)',ev.sample);
        fprintf('\tdv:'); fprintf('%5.4f ',pred);
        fprintf('\tfilt dv:'); fprintf('%5.4f ',dv);
        fprintf('\tProb:');fprintf('%5.4f ',prob);
        fprintf('\n'); 
      end;
      
      % feedback information... simply move to location indicated by the BCI
      switch lower(controlMode);
       
       case {'cursor','cursor-sum'}; 
        if ( strcmp(lower(controlMode),'cursor') ) % prediction are in the various directions, x,y,z etc...
          fixPos(1:2) = dv(1:2);
        else
          fixPos(1:2)=fixPos(1:2) + dv(1:2);
        end
        % Dynamically scale the axes to keep the point visible
        xl=get(gca,'xlim'); 
        if ( fixPos(1)<xl(1) ) xl(1)=xl(1)-.5*(diff(xl)); set(gca,'xlim',xl); end;
        if ( fixPos(1)>xl(2) ) xl(2)=xl(2)+.5*(diff(xl)); set(gca,'xlim',xl); end;        
        yl=get(gca,'ylim');
        if ( fixPos(2)<yl(1) ) yl(1)=yl(1)-.5*(diff(yl)); set(gca,'ylim',yl); end;
        if ( fixPos(2)>yl(2) ) yl(2)=yl(2)+.5*(diff(yl)); set(gca,'ylim',yl); end;        
               
       case 'probability'; % prediction is the probability of each target
        fixPos = stimPos(:,1:end-1)*prob(:); % position is weighted by class probabilties
       otherwise; error('Unrecognised control mode');
      end
      set(h(end),'position',[fixPos-stimRadius/2;stimRadius/2*[1;1]]);
    end
  end % if prediction events to processa  
  drawnow; % update the display after all events processed
end % loop over epochs in the sequence

% end training marker
sendEvent('stimulus.testing','end');
