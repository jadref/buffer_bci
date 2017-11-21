% continous feedback within a cued trial based structure
%if ( ~exist('preConfigured','var') || ~isequal(preConfigured,true) ) configureIM; end;
if ( ~exist('contFeedbackTrialDuration') || isempty(contFeedbackTrialDuration) ) contFeedbackTrialDuration=trialDuration; end;
if ( ~exist('dvFilt','var') ) dvFilt=[]; end; % additional filtering of the decison values for display/feedback
if ( ~exist('dvCalFactor','var') ) dvCalFactor=[]; end;
if ( ~exist('warpCursor','var') ) warpCursor=true; end;
if ( ~exist('moveScale','var') ) moveScale=1; end;
if ( ~exist('twoDPred','var') ) twoDPred=0; end;

% make the target sequence
if ( baselineClass ) % with rest targets
  tgtSeq=mkStimSeqRand(nSymbs+1,nSeq);
else
  tgtSeq=mkStimSeqRand(nSymbs,nSeq);
end

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
% text object for the experiment progress bar
progresshdl=text(axLim(1),axLim(2),sprintf('%2d/%2d +%02d -%02d (%02d)',0,nSeq,0,0,0),...
				  'HorizontalAlignment', 'left', 'VerticalAlignment', 'top',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','on');


% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'facecolor',bgColor);

% wait for user to become ready
set(txthdl,'string', {contfeedback_instruct{:} '' 'Click mouse when ready'}, 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow; sleepSec(intertrialDuration);

sendEvent('stimulus.testing','start');

nWrong=0; nMissed=0; nCorrect=0; % performance recording
dvstats=[]; % summary stats for the decision values
waitforkeyTime=getwTime()+calibrateMaxSeqDuration;
for si=1:nSeq;

  if ( ~ishandle(fig) ) break; end;
    
  % Give user a break if too much time has passed
  if ( getwTime() > waitforkeyTime )
	 set(txthdl,'string', {'Break between blocks.' 'Click mouse when ready to continue.'}, 'visible', 'on');
	 drawnow;
	 waitforbuttonpress;
	 set(txthdl,'visible', 'off');
	 drawnow;	 
	 waitforkeyTime=getwTime()+calibrateMaxSeqDuration;
	 if ( 1.5*calibrateMaxSeqDuration > ...  % close to end of expt = don't bother
			(nSeq-si)*(baselineDuration+contFeedbackTrialDuration+intertrialDuration) ) 
		waitforkeyTime=inf;
	 end;
	 sleepSec(intertrialDuration);
  end

  %------------------------------- baseline --------------
  % show the screen to alert the subject to trial start
  set(h(:),'faceColor',bgColor);
  set(h(end),'facecolor',fixColor); % red fixation indicates trial about to start/baseline
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  % TODO: [] if using baseline reference then catch predictions during this period to get the baseline...
  if ( ~isempty(baselineClass) ) % treat baseline as a special class
	 for ei=1:ceil(baselineDuration/epochDuration); % send base-line event every epoch duration
		sendEvent('stimulus.target',baselineClass);
		sleepSec(epochDuration);
	 end
  else
	 sleepSec(baselineDuration);
  end
  sendEvent('stimulus.baseline','end');

  %------------------------------- cue --------------
  % show the target
  tgtIdx=find(tgtSeq(:,si)>0);
  set(h(tgtSeq(:,si)>0),'facecolor',tgtColor);
  set(h(tgtSeq(:,si)<=0),'facecolor',bgColor);
  if ( ~isempty(baselineClass) && tgtSeq(nSymbs+1,si)<=0 )% green fixation indicates trial running, if its not actually the target
	 set(h(end),'facecolor',tgtColor);
  end
  if ( ~isempty(symbCue) )
	 if ( all(tgtIdx<=nSymbs) )
		set(txthdl,'string',sprintf('%s ',symbCue{tgtIdx}),'color',txtColor,'visible','on');
		tgtNm = '';
		for ti=1:numel(tgtIdx);
		  if(ti>1) tgtNm=[tgtNm ' + ']; end;
		  tgtNm=sprintf('%s%d %s',tgtNm,tgtIdx,symbCue{tgtIdx});
		end
	 elseif ( tgtIdx==nSymbs+1 ) % rest class
		tgtNm=baselineClass;
		set(txthdl,'string','rest','color',txtColor,'visible','on');
	 end
  else
	 tgtNm = tgtIdx; % human-name is position number
  end
  fprintf('%d) tgt=%10s : ',si,tgtNm);
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.target',tgtNm);
  sendEvent('stimulus.trial','start');
  
  %------------------------------- trial interval --------------
  % for the trial duration update the fixatation point in response to prediction events
  % initial fixation point position
  fixPos = stimPos(:,end);
  state  = [];
  dv     = zeros(nSymbs,1);
  prob   = ones(nSymbs,1)./nSymbs; % start with equal prob over everything
  trlStartTime=getwTime();
  timetogo = contFeedbackTrialDuration;
  nevt=0; nPred=0; sdv=[]; baselinedv=[]; 
  evtTime=trlStartTime+epochDuration; % N.B. already sent the 1st target event
  while (timetogo>0)
	 curTime  = getwTime();
    timetogo = contFeedbackTrialDuration - (curTime-trlStartTime); % time left to run in this trial
	 if ( curTime>evtTime ) % send target type event every epochDuration
		sendEvent('stimulus.target',tgtNm);
		if ( verb>0 ) fprintf(' %d -> %g\n',nevt,evtTime-trlStartTime); end;
		evtTime = evtTime+epochDuration;
		nevt=nevt+1;
	 end
    % wait for new prediction events to process *or* end of trial time
    [events,state,nsamples,nevents] = buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],min([epochDuration,evtTime-curTime,timetogo])*1000);
    if ( isempty(events) ) 
		if ( timetogo>.1 ) fprintf('%d) no predictions!\n',nsamples); end;
    else
		[ans,evtsi]=sort([events.sample],'ascend'); % proc in *temporal* order
      for ei=1:numel(events);
        ev=events(evtsi(ei));% event to process
		  %fprintf('pred-evt=%s\n',ev2str(ev));
        pred=ev.value;
        % now do something with the prediction....
        if ( numel(pred)==1 && isinteger(pred) && pred>0 && pred<=nSymbs ) 
           tmp=pred; pred=zeros(nSymbs,1); pred(tmp)=1;
        end    

		  % additional prediction smoothing for display, if wanted
		  if ( ~isempty(dvFilt) && ~isequal(dvFilt,0) )
           if( isnumeric(dvFilt) )
              if ( dvFilt>=0 ) % exp weighted moving average
                 dv=dv*dvFilt + (1-dvFilt)*pred(:);
              else % store predictions in a ring buffer
                 fbuff(:,mod(nEpochs-1,abs(dvFilt))+1)=pred(:);% store predictions in a ring buffer
                 dv=mean(fbuff,2);
              end
           elseif ( ischar(dvFilt) )
              if( isempty(baselinedv) ) baselinedv=dv; end; % BODGE: seed baseline dv with 1st pred in the trial
              if( strcmp(dvFilt,'absbaseline') )
                 dv = dv-baselinedv;
              elseif ( strcmp(dvFilt,'relbaseline') )
                 dv = dv./baselinedv;
              end
           end
		  else
			 dv=pred;
		  end
                           % accumulate info on the average dv for this trial
        nPred=nPred+1; if(isempty(sdv))sdv=dv; sdv2=dv.*dv; else; sdv=sdv+dv; sdv2=sdv2+dv.*dv; end;
        % update summary stats
        if( isempty(dvstats) ) 
           dvstats=struct('N',1,'sdv',dv,'sdv2',dv.*dv,'dvvar',1); 
        else                   
           dvstats.N    = dvstats.N+1; 
           dvstats.sdv  = dvstats.sdv+dv; 
           dvstats.sdv2 = dvstats.sdv2+dv.*dv;
           dvstats.dvvar= max(0,(dvstats.sdv2-dvstats.sdv.^2./dvstats.N))./dvstats.N; % running variance estimate 
        end
        
										  % convert from dv to normalised probability
        curdv=dv; if( numel(curdv)==1 ) curdv=[curdv -curdv]; end; % ensure min 1 decision values..
		  if(~isempty(dvCalFactor))
           if( isnumeric(dvCalFactor) )
              prob=exp((curdv-max(curdv))*dvCalFactor);
           elseif( ischar(dvCalFactor) && strcmp(dvCalFactor,'auto') )
              calF=.5./sqrt(mean(dvstats.dvvar)); % make range +/- 3
              if(verb>=1)
                 fprintf('N=%g sdv=[%s] sdv2=[%s] calF=[%g]\n',...
                         dvstats.N,sprintf('%g,',dvstats.sdv),sprintf('%g,',dvstats.sdv2),calF);
              end
              if( calF>0 && ~isnan(calF) && ~isinf(calF) ) 
                 prob=exp((curdv-max(curdv))*calF);
              end
           end
		  else                      
           prob=exp((curdv-max(curdv)));
		  end
		  prob=prob./sum(prob); % robust soft-max prob computation
        if ( verb>=0 ) 
			 fprintf('%d) dv:[%s]\tPr:[%s]\n',ev.sample,sprintf('%5.4f ',pred),sprintf('%5.4f ',prob));
        end;
      end

	 end % if prediction events to process
    
    
    % feedback information... simply move in direction detected by the BCI
	 if ( numel(prob)>=size(stimPos,2)-1 ) % per-target decomposition
      if ( numel(prob)>size(stimPos,2) ) prob=[prob(1:size(stimPos,2)-1);sum(prob(size(stimPos,2):end))];end;
		dx = stimPos(:,1:numel(prob))*prob(:); % change in position is weighted by class probs
	 elseif ( twoDPred && numel(prob)==2 ) % direct 2d decomposition
		dx = prob(:);
	 elseif ( numel(prob)==1 )
		dx = [prob;0];
	 end
    cursorPos=get(h(end),'position'); cursorPos=cursorPos(:);
	 fixPos   =cursorPos(1:2)+.5*cursorPos(3:4); % center of the fix-point
	 % relative or absolute cursor movement
	 if ( warpCursor ) % absolute position on the screen
		fixPos=dx;
	 else % relative movement
		fixPos=fixPos + dx*moveScale;
	 end;
	 set(h(end),'position',[fixPos-.5*cursorPos(3:4);cursorPos(3:4)]);
    drawnow; % update the display after all events processed    
  end % while time to go

										  % turn off the text cue
	 set(txthdl,'string','','color',txtColor,'visible','on');

						  %------------------------------- feedback --------------
  % final predicted target is one fixPos is closest to
  tgtDis = repop(stimPos(:,1:end-1),'-',fixPos); tgtDis = sqrt(sum(tgtDis.^2));
  [md,predTgt]=min(tgtDis);
  if ( predTgt>nSymbs )      nMissed = nMissed+1;
  elseif ( predTgt~=tgtIdx ) nWrong  = nWrong+1;  % wrong (and not 'rest') .... do the penalty
  else                       nCorrect= nCorrect+1;% correct
  end


  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'facecolor',bgColor);
  % show the predicted target
  set(h(min(numel(h),predTgt)),'facecolor',fbColor);
  % also reset the position of the fixation point
  set(h(end),'position',[stimPos(:,end)-stimRadius/4;stimRadius/2*[1;1]]);
  % update progress bar
  set(progresshdl,'string',sprintf('%2d/%2d +%02d -%02d  (%02d)',si,nSeq,nCorrect,nWrong,nMissed));
  drawnow;
  sendEvent('stimulus.trial','end');

  %------------------------------- intertrial interval --------------
  if ( ~isempty(rtbClass) ) % treat post-trial return-to-baseline as a special class
	 for ei=1:ceil(intertrialDuration/epochDuration); % loop over sub-trials
		if ( ischar(rtbClass) && strcmp(rtbClass,'trialClass') ) % label as part of the trial
		  sendEvent('stimulus.target',tgtNm);
		elseif ( ischar(rtbClass) && strcmp(rtbClass,'trialClass+rtb')) %return-to-base ver of trial class
		  sendEvent('stimulus.target',[tgtNm '_rtb']);		
		else
		  sendEvent('stimulus.target',rtbClass);
		end
		sleepSec(epochDuration);
	 end
  else
    sleepSec(intertrialDuration);
  end
  
  ftime=getwTime();
  fprintf('\n');
end % loop over sequences in the experiment
% end training marker
sendEvent('stimulus.testing','end');

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'That ends the feedback phase.','Thanks for your patience'},'color',[0 1 0],'visible', 'on');
pause(3);
end
