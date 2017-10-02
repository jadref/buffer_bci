% continous feedback over a long duration without and subject cues
%if ( ~exist('preConfigured','var') || ~isequal(preConfigured,true) ) configureIM; end;

fig=figure(2);
set(fig,'Name','Stimulus Display : Neurofeedback -- close window to stop.','color',winColor,'menubar','none','toolbar','none','doublebuffer','on');
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',winColor,'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');
stimPos=[]; h=[]; htxt=[];
stimRadius=diff(axLim)/4;
cursorSize=stimRadius/2;
theta=linspace(0,2*pi,nSymbs+1)+pi/2; % N.B. pos1=N so always left-right symetric
theta=theta(1:end-1);
stimPos=[cos(theta);sin(theta)];
for hi=1:nSymbs; 
  h(hi)=rectangle('curvature',[1 1],'position',[stimPos(:,hi)-stimRadius/2;stimRadius*[1;1]],...
                  'facecolor',bgColor);
  if ( ~isempty(symbCue) ) % cue-text
	 htxt(hi)=text(stimPos(1,hi),stimPos(2,hi),symbCue{hi},...
						'HorizontalAlignment','center',...
						'fontunits','pixel','fontsize',.05*wSize(4),...
						'color',txtColor,'visible','on');
  end  
end;
% add symbol for the center of the screen
stimPos(:,nSymbs+1)=[0 0];
h(nSymbs+1)=rectangle('curvature',[1 1],'position',[stimPos(:,end)-stimRadius/4;stimRadius/2*[1;1]],...
                      'facecolor',bgColor); 
set(gca,'visible','off');

%Create a text object with no text in it, center it, set font and color
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','off');

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'facecolor',bgColor);

% wait for the user to become ready
set(txthdl,'string', {neurofeedback_instruct{:} '' 'Click mouse when ready'}, 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;


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
cursorPos=get(h(end),'position'); cursorPos=cursorPos(:);
fixPos   =cursorPos(1:2)+.5*cursorPos(3:4); % center of the fixatation point
trlStartTime=getwTime();
state=[];
trialDuration = 60*60; % 1hr...
timetogo=trialDuration;
nEpochs=0;
dv  = zeros(nSymbs,1);
prob= ones(nSymbs,1)./nSymbs; % start with equal prob over everything
while (timetogo>0)
  if ( ~ishandle(fig) ) break; end;
  timetogo = trialDuration - (getwTime()-trlStartTime); % time left to run in this trial
					% wait for new prediction events to process *or* end of trial
  [events,state,nsamples,nevents] = buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],min(1500,timetogo*1000));

										  % process the prediction events
  if ( isempty(events) )
	 if ( timetogo>.1 ) fprintf('%d) no predictions!\n',nsamples); drawnow; end;
  else
    [ans,evtsi]=sort([events.sample],'ascend'); % proc in *temporal* order
    for ei=1:numel(events);
		nEpochs=nEpochs+1;

      ev=events(evtsi(ei));% event to process
		pred=ev.value;
										  % now do something with the prediction....
		if ( numel(pred)==1 )
		  if ( pred>0 && pred<=nSymbs && isinteger(pred) ) % predicted symbol, convert to dv
			 tmp=pred; pred=zeros(nSymbs,1); pred(tmp)=1;
		  else % binary problem
			 pred=[pred -pred];
		  end
		end

						  % additional prediction smoothing for display, if wanted
		if ( ~isempty(stimSmoothFactor) && isnumeric(stimSmoothFactor) && stimSmoothFactor>0 )
		  if ( stimSmoothFactor>=0 ) % exp weighted moving average
			 dv=dv*stimSmoothFactor + (1-stimSmoothFactor)*pred(:);
		  else % store predictions in a ring buffer
			 fbuff(:,mod(nEpochs-1,abs(stimSmoothFactor))+1)=pred(:); % store predictions in a ring buffer
			 dv=mean(fbuff,2);
		  end
		else
		  dv=pred;
		end

										  % convert from dv to normalised probability
		prob=exp((dv-max(dv))); prob=prob./sum(prob); % robust soft-max prob computation
		if ( verb>=0 ) 
		  fprintf('%d) dv:[%s]\tPr:[%s]\n',ev.sample,sprintf('%5.4f ',pred),sprintf('%5.4f ',prob));
		end;		
		
% feedback information... compute the updated positino for the cursor
		if ( numel(prob)>=size(stimPos,2)-1 ) % per-target decomposition
        if ( numel(prob)>size(stimPos,2) ) prob=[prob(1:size(stimPos,2)-1);sum(prob(size(stimPos,2):end))];end;
		  dx = stimPos(:,1:numel(prob))*prob(:); % change in position is weighted by class probs
		elseif ( numel(prob)==2 ) % direct 2d decomposition
		  dx = prob;
		elseif ( numel(prob)==1 ) % direct 1d position
		  dx = [prob;0];
		end
		% relative or absolute cursor movement
		if ( warpCursor )
		  fixPos=dx;
		  if(feedbackMagFactor>1) fixPos=(fixPos-stimPos(:,end))*feedbackMagFactor + stimPos(:,end); end;
		else
		  fixPos=fixPos + dx*moveScale;
		end; 
	 end % loop over events to process
		% now re-draw the display
		set(h(end),'position',[fixPos-.5*cursorPos(3:4); cursorPos(3:4)]);
	 drawnow; % update the display after all events processed
  end % events to process  
end % while time to go

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'That ends the training phase.','Thanks for your patience'}, 'color',[0 1 0],'visible', 'on');
pause(3);
end
% end training marker
sendEvent('stimulus.testing','end');
