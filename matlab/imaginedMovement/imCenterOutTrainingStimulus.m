% continous feedback within a cued trial based structure, with goal to complete the training as fast as possible
configureIM;
if(~exist('centerOutTrialDuration') || isempty(centerOutTrialDuration)) centerOutTrialDuration=trialDuration; end;

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

fig=figure(2);
clf;
set(fig,'Name','Stimulus Display','color',winColor,'menubar','none','toolbar','none','doublebuffer','on');
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',winColor,'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');

stimPos=[]; h=[];
stimRadius=diff(axLim)/4;
cursorSize=stimRadius/2;
theta=linspace(0,2*pi,nSymbs+1);
if ( mod(nSymbs,2)==1 ) theta=theta+pi/2; end; % ensure left-right symetric by making odd 0=up
theta=theta(1:end-1);
stimPos=[cos(theta);sin(theta)];
for hi=1:nSymbs; 
  h(hi)=rectangle('curvature',[1 1],'position',[stimPos(:,hi)-stimRadius/2;stimRadius*[1;1]],...
                  'facecolor',bgColor); 
  if ( ~isempty(symbCue) ) % cue-text on each target location
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
% text object for the experiment progress bar
progresshdl=text(axLim(1),axLim(2),sprintf('%2d/%2d +%02d -%02d',0,nSeq,0,0),...
				  'HorizontalAlignment', 'left', 'VerticalAlignment', 'top',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','on');

% Create a new text object to show the elapsed time.
timehdl = text(axLim(2),axLim(2),sprintf('Time: %4.1f',0),...
				  'HorizontalAlignment', 'right', 'VerticalAlignment', 'top',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','on');


% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'facecolor',bgColor);

% wait for user to become ready
set(txthdl,'string', {centerout_instruct{:} '' 'Click mouse when ready'}, 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;

sendEvent('stimulus.testing','start');

t0=getwTime(); timePen=0; 
nWrong=0; nMissed=0; nCorrect=0; % performance recording
for si=1:nSeq;

  if ( ~ishandle(fig) ) break; end;
  
  % show the target
  tgtIdx=find(tgtSeq(:,si)>0);
  set(h(tgtSeq(:,si)>0),'facecolor',tgtColor);
  set(h(tgtSeq(:,si)<=0),'facecolor',bgColor);
  set(h(end),'facecolor',tgtColor); % green fixation indicates trial running
  if ( ~isempty(symbCue) )
	 tgtNm = '';
	 for ti=1:numel(tgtIdx);
		if(ti>1) tgtNm=[tgtNm ' + ']; end;
		tgtNm=sprintf('%s%d %s ',tgtNm,tgtIdx,symbCue{tgtIdx});
	 end
  else
	 tgtNm = tgtIdx; % human-name is position number
  end
  fprintf('%d) tgt=%10s : ',si,tgtNm);
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.trial','start');
  sendEvent('stimulus.target',tgtNm);
  
  % for the trial duration update the fixatation point in response to prediction events
  % initial fixation point position
  fixPos = stimPos(:,end);
  state  = [];
  dv     = [];
  prob   = ones(nSymbs,1)./nSymbs; % start with equal prob over everything
  targetReached = false;
  filtstate=[];
  trlStartTime=getwTime();
  timetogo = centerOutTrialDuration;
  while (timetogo>0 && ~targetReached )
    timetogo = trialDuration - (getwTime()-trlStartTime); % time left to run in this trial
    % wait for new prediction events to process *or* end of trial time
    % N.B. we use raw predictions as we will do the prediction filtering ourselves....
    [events,state,nsamples,nevents] = buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],min(1000,timetogo*1000));
    if ( isempty(events) ) 
		if ( timetogo>.1 ) fprintf('%d) no predictions!\n',nsamples); end;
    else
		[ans,evtsi]=sort([events.sample],'ascend'); % proc in *temporal* order
      for ei=1:numel(events);
        ev=events(evtsi(ei));% event to process
		  %fprintf('pred-evt=%s\n',ev2str(ev));
        pred=ev.value;
        % now do something with the prediction....
        if ( numel(pred)==1 )
          if ( pred>0 && pred<=nSymbs && isinteger(pred) ) % predicted symbol, convert to dv equivalent
            tmp=pred; pred=zeros(nSymbs,1); pred(tmp)=1;
          else % binary problem
            pred=[pred -pred];
          end
        end

        % accumulate the predictions
        if ( isempty(dv) ) dv=pred; else dv = dv + pred; end;
		  % convert from dv to normalised probability
        prob=exp((dv-max(dv))./contFeedbackFiltLen); prob=prob./sum(prob); % robust soft-max prob computation
        if ( verb>=0 ) 
			 fprintf('%d) dv:[%s]\tPr:[%s]\n',ev.sample,sprintf('%5.4f ',dv),sprintf('%5.4f ',prob));
        end;

        % push the predictions through the given earlyStopping filter
        if ( ~isempty(earlyStoppingFilt) ) 
           [esdv,filtstate]=feval(earlyStoppingFilt,pred,filtstate,ev.sample);
           if ( ~isempty(esdv) ) % we should stop, mark as such
              targetReached=true;
              break;
           end
        end
      end

	 end % if prediction events to process

    % feedback information... simply move in direction detected by the BCI
	 if ( numel(prob)>=size(stimPos,2)-1 ) % per-target decomposition
      if ( numel(prob)>size(stimPos,2) ) prob=[prob(1:size(stimPos,2)-1);sum(prob(size(stimPos,2):end))];end;
		dx = stimPos(:,1:numel(prob))*prob(:); % change in position is weighted by class probs
	 elseif ( numel(prob)==2 ) % direct 2d decomposition
		dx = prob;
	 elseif ( numel(prob)==1 )
		dx = [prob;0];
	 end 
    cursorPos=get(h(end),'position'); cursorPos=cursorPos(:);
    % fixation position is directly based on the current prediction
    fixPos=dx;
    if(feedbackMagFactor>1) fixPos=(fixPos-stimPos(:,end))*feedbackMagFactor + stimPos(:,end); end;

    % update display
    set(h(end),'position',[fixPos-.5*cursorPos(3:4); cursorPos(3:4)]); % for the fixation point    
    set(timehdl,'string',sprintf('Time: %4.1f',getwTime()-t0+timePen)); % for the time-display
    drawnow; % update the display after all events processed

    % early-stopping test(s)
    if ( isempty(earlyStoppingFilt) ) % stop when reach the target position
                                      % compute distance to each stim-pos
       tgtDis = repop(stimPos(:,1:end-1),'-',fixPos); tgtDis = sqrt(sum(tgtDis.^2));
       [md,predTgt]=min(tgtDis);
       if ( md<stimRadius/2 ) 
          targetReached=true; 
       end;
    end

  end % while time to go

  % check for penalties if we made an incorrect prediction
  if ( targetReached ) 
     [ans,predTgt]=max(dv); % get the predicted target
     if ( predTgt>nSymbs ) 
        nMissed=nMissed+1;
     elseif ( predTgt~=tgtIdx ) % wrong (and not 'rest') .... do the penalty
       % show the mistake
       set(h(predTgt),'facecolor',errorColor);
       drawnow;
       % wait for the error penalty time
       sleepSec(errorDuration);
       timePen=timePen+timetogo;
       nWrong = nWrong+1;
     else
        nCorrect=nCorrect+1;
     end
  else
     nMissed=nMissed+1;
  end

  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'facecolor',bgColor);
  % update progress bar
  set(progresshdl,'string',sprintf('%2d/%2d +%02d -%02d',si,nSeq,nCorrect,nWrong));
  % also reset the position of the fixation point
  set(h(end),'position',[stimPos(:,end)-stimRadius/4;stimRadius/2*[1;1]]);
  drawnow;
  sendEvent('stimulus.trial','end');
  
  ftime=getwTime();
  fprintf('\n');
end % loop over sequences in the experiment
% end training marker
sendEvent('stimulus.testing','end');

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'Finished!' 'Your final time was:' get(timehdl,'string') '' 'Well done!'},'color',[0 1 0],'visible', 'on');
pause(3);
end
