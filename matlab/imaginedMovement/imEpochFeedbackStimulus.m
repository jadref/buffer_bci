% per-epoch feedback when using an event triggered classifier
%if ( ~exist('preConfigured','var') || ~isequal(preConfigured,true) ) configureIM; end;
if ( ~exist('epochFeedbackTrialDuration') || isempty(epochFeedbackTrialDuration) ) 
   epochFeedbackTrialDuration=trialDuration; 
end;

% make the target sequence
if ( baselineClass ) % with rest targets
  tgtSeq=mkStimSeqRand(nSymbs+1,nSeq);
else
  tgtSeq=mkStimSeqRand(nSymbs,nSeq);
end

% make the stimulus display
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

                                % mapping from class order to screen order
% % TODO [] : remove the auto number prefix from calibrate so this is needed? 
cls2tgt=[];
%if ( ~isempty(symbCue) ) % given cue-text
%  % compute inverse mapping from class-name-order -> input class order=display order
%  cls2tgt=1:nSymbs; [ss,si]=sort(symbCue,'ascend'); cls2tgt(si)=1:numel(si);
%end
  
%Create a text object with no text in it, center it, set font and color
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','off');
% text object for the experiment progress bar
progresshdl=text(axLim(1),axLim(2),sprintf('%2d/%2d +%02d -%02d (%02d)',0,nSeq,0,0,0),...
				  'HorizontalAlignment', 'left', 'VerticalAlignment', 'top',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','on');

set(txthdl,'string', {epochfeedback_instruct{:} '' 'Click mouse when ready'}, 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow; sleepSec(intertrialDuration);

% play the stimulus
set(h(:),'facecolor',bgColor);
sendEvent('stimulus.testing','start');
% initialize the state so don't miss classifier prediction events
state=[]; 
endTesting=false; dvs=[];
nWrong=0; nMissed=0; nCorrect=0; % performance recording
waitforkeyTime=getwTime()+calibrateMaxSeqDuration;
for si=1:nSeq;

  if ( ~ishandle(fig) || endTesting ) break; end;

  % Give user a break if too much time has passed
  if ( getwTime() > waitforkeyTime )
	 set(txthdl,'string', {'Break between blocks.' 'Click mouse when ready to continue.'}, 'visible', 'on');
	 drawnow;
	 waitforbuttonpress;
	 set(txthdl,'visible', 'off');
	 drawnow;	 
	 waitforkeyTime=getwTime()+calibrateMaxSeqDuration;
	 if ( 1.5*calibrateMaxSeqDuration > ...  % close to end of expt = don't wait again
			(nSeq-si)*(baselineDuration+epochFeedbackTrialDuration+intertrialDuration) ) 
		waitforkeyTime=inf;
	 end;
	 sleepSec(intertrialDuration);
  end
  
  % show the screen to alert the subject to trial start
  set(h(:),'faceColor',bgColor);
  set(h(end),'facecolor',fixColor); % red fixation indicates trial about to start/baseline
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  if ( ~isempty(baselineClass) ) % treat baseline as a special class
	 sendEvent('stimulus.target',baselineClass);
  end
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');

  % show the target
  tgtIdx=find(tgtSeq(:,si)>0);
  set(h(tgtSeq(:,si)>0),'facecolor',tgtColor);
  set(h(tgtSeq(:,si)<=0),'facecolor',bgColor);
  %green fixation indicates trial running, if its not actually the target
  if ( size(tgtSeq,1)<=nSymbs || tgtSeq(nSymbs+1,si)<=0 )
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
  ev=sendEvent('stimulus.target',tgtNm);
  sendEvent('stimulus.trial','start');
  if ( earlyStopping )
	 % cont-classifier, so tell it to clear the prediction filter for start new trial
	 sendEvent('classifier.reset','now',ev.sample); 
  else
	 % event-classifier, so send the event which triggers to classify this data-block
	 sendEvent('classifier.apply','now',ev.sample); % tell the classifier to apply from now
  end
  trlStartTime=getwTime();
  sendEvent('stimulus.trial','start',ev.sample);
  state=buffer('poll'); % Ensure we ignore any predictions before the trial start  
  if( verb>0 )
	 fprintf(1,'Waiting for predictions after: (%d samp, %d evt)\n',...
				state.nSamples,state.nEvents);
  end;
  devents=[];
  for eti=1:epochDuration:epochFeedbackTrialDuration;
    % send target event every epochDuration s
    ttg=min(epochDuration,epochFeedbackTrialDuration-eti);
    ev=sendEvent('stimulus.target',tgtNm);
    if ( earlyStopping )
	        % wait for new prediction events to process *or* end of trial time
	   [devents,state,nevents,nsamples]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],ttg);
      if( ~isempty(devents) ) break; end;
    else
      sleepSec(ttg); 
    end
  end
  if( isempty(devents) ) 	                             % wait for classifier prediction event
    [devents,state,nevents,nsamples]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],2000);
  end
  trlEndTime=getwTime();
  
  % do something with the prediction (if there is one), i.e. give feedback
  if( isempty(devents) ) % extract the decision value
    fprintf(1,'Error! no predictions after %gs, continuing (%d samp, %d evt)\n',trlEndTime-trlStartTime,state.nSamples,state.nEvents);
    set(h(:),'facecolor',bgColor);
    drawnow;
    nMissed=nMissed+1;
  else
	 fprintf(1,'Prediction after %gs : %s',trlEndTime-trlStartTime,ev2str(devents(end)));
    dv = devents(end).value;
    % predicted symbol, convert to dv equivalent
    if ( numel(dv)==1 && isinteger(dv) && dv>0 && dv<=nSymbs ) 
       tmp=dv; dv=zeros(nSymbs,1); dv(tmp)=1;
    end    
    % give the feedback on the predicted class
    if( numel(dv)==1 ) dv=[dv -dv]; end; % ensure min 1 decision values..
    % map from class order to display / target order
    if(~isempty(cls2tgt)) dv(1:numel(cls2tgt))=dv(cls2tgt); end;

    prob=exp(dv-max(dv)); prob=prob./sum(prob); % robust soft-max prob computation
    if ( verb>=0 ) 
		fprintf('%d) dv:[%s]\tPr:[%s]\n',ev.sample,sprintf('%5.4f ',dv),sprintf('%5.4f ',prob));
    end;  
    [ans,predTgt]=max(dv); % prediction is max classifier output
    set(h(:),'facecolor',bgColor);
    set(h(min(numel(h),predTgt)),'facecolor',fbColor);

    fprintf('tgtIdx=%d predTgt=%d\n',tgtIdx,predTgt);
    if ( predTgt>nSymbs )         nMissed = nMissed+1; fprintf('missed!');
    elseif(~any(predTgt==tgtIdx)) nWrong  = nWrong+1;  fprintf('wrong!'); % wrong (and not 'rest') .... do the penalty
    elseif(any(predTgt==tgtIdx))  nCorrect= nCorrect+1;fprintf('right!'); % correct
    end
    sendEvent('stimulus.predTgt',predTgt);
  end % if classifier prediction
  
  % update progress bar
  set(progresshdl,'string',sprintf('%2d/%2d +%02d -%02d (%02d)',si,nSeq,nCorrect,nWrong,nMissed));
  drawnow; % re-draw display
  sleepSec(feedbackDuration);
  
  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'facecolor',bgColor);
  if ( ~isempty(symbCue) ) set(txthdl,'visible','off'); end
  % also reset the position of the fixation point
  drawnow;
  sendEvent('stimulus.trial','end');

  if ( ~isempty(rtbClass) ) % treat post-trial return-to-baseline as a special class
	 if ( ischar(rtbClass) && strcmp(rtbClass,'trialClass') ) % label as part of the trial
		sendEvent('stimulus.target',tgtNm);
	 elseif ( ischar(rtbClass) && strcmp(rtbClass,'trialClass+rtb')) %return-to-base ver of trial class
		sendEvent('stimulus.target',[tgtNm '_rtb']);		
	 else
		sendEvent('stimulus.target',rtbClass);
	 end
  end
  sleepSec(intertrialDuration);
  
end % loop over sequences in the experiment
% end training marker
sendEvent('stimulus.testing','end');

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'That ends the testing phase.','Thanks for your patience'}, 'visible', 'on', 'color',[0 1 0]);
pause(3);
end
