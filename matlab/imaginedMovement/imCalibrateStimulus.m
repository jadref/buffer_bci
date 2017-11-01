% auto-configure if not done?
%if ( ~exist('preConfigured','var') || ~isequal(preConfigured,true) ) configureIM; end;

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

% make the stimulus
%figure;
fig=figure(2);
set(fig,'Name','Stimulus Display','color',winColor,'menubar','none','toolbar','none','doublebuffer','on');
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',winColor,'DrawMode','fast','nextplot','replacechildren',...
        'xlim',axLim,'ylim',axLim,'Ydir','normal');

stimPos=[]; h=[]; htxt=[];
stimRadius=diff(axLim)/4;
cursorSize=stimRadius/2;
theta=linspace(0,2*pi,nSymbs+1);
if ( mod(nSymbs,2)==1 ) theta=theta+pi/2; end; % ensure left-right symetric by making odd 0=up
%theta=linspace(0,2*pi,nSymbs+1)+pi/2; % N.B. pos1=N so always left-right symetric
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
h(nSymbs+1)=rectangle('curvature',[1 1],'position',[stimPos(:,nSymbs+1)-cursorSize/2;cursorSize*[1;1]],...
                      'facecolor',bgColor); 
set(gca,'visible','off');

%Create a text object with no text in it, center it, set font and color
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','off');

% text object for the experiment progress bar
progresshdl=text(axLim(1),axLim(2),sprintf('%2d/%2d',0,nSeq),...
				  'HorizontalAlignment', 'left', 'VerticalAlignment', 'top',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','on');


% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'facecolor',bgColor);
sendEvent('stimulus.training','start');

% wait for user to be ready before starting everything
set(txthdl,'string', {calibrate_instruct{:} '' 'Click mouse when ready'}, 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow; sleepSec(intertrialDuration);

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
	 if ( 1.5*calibrateMaxSeqDuration > ...  % close to end of expt = don't wait again
			(nSeq-si)*(baselineDuration+trialDuration+intertrialDuration) ) 
		waitforkeyTime=inf;
	 end;
	 sleepSec(intertrialDuration);
  end
  
  % show the screen to alert the subject to trial start
  set(h(end),'facecolor',fixColor); % red fixation indicates trial about to start/baseline
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  ev=sendEvent('stimulus.baseline','start');
  for ei=1:ceil(baselineDuration./epochDuration);  % loop over sub-trials in this phase
	 if ( ~isempty(baselineClass) ) % treat baseline as a special class
		sendEvent('stimulus.target',baselineClass);
	 end
	 if ( animateFix )	 
		animateDuration=epochDuration;
		t0  =getwTime();
		timetogo=animateDuration;
		fixPos=[stimPos(:,end)-cursorSize/2;cursorSize*[1;1]];
		while ( timetogo > 0 )
		  dx=randn(2,1)*animateStep;
		  fixPos(1:2) = fixPos(1:2)+dx;
		  set(h(end),'position',fixPos);
		  drawnow;		
		  sleepSec(min(max(0,timetogo),frameDuration));
		  timetogo = animateDuration- (getwTime()-t0); % time left to run in this trial
		end
	 else
		sleepSec(epochDuration);
	 end
  end
  sendEvent('stimulus.baseline','end');  
  if ( animateFix )										  % reset fix pos
		set(h(end),'position',[stimPos(:,end)-cursorSize/2;cursorSize*[1;1]]);
  end
  
  % show the target
  tgtIdx=find(tgtSeq(:,si)>0);
  set(h(tgtSeq(:,si)>0),'facecolor',tgtColor);
  set(h(tgtSeq(:,si)<=0),'facecolor',bgColor);
  % ***WARNING*** Automatically adds position number to the target name!!
  if ( ~isempty(symbCue) ) 
	 set(txthdl,'string',sprintf('%s ',symbCue{tgtIdx}),'color',txtColor,'visible','on');
	 tgtNm = '';
	 for ti=1:numel(tgtIdx);
		if(ti>1) tgtNm=[tgtNm ' + ']; end;
		tgtNm=sprintf('%s%d %s',tgtNm,tgtIdx,symbCue{tgtIdx});
	 end
  else
	 tgtNm = tgtIdx; % human-name is position number
  end
  set(h(end),'facecolor',tgtColor); % green fixation indicates trial running
  fprintf('%d) tgt=%10s : ',si,tgtNm);
  sendEvent('stimulus.trial','start');
  for ei=1:ceil(trialDuration./epochDuration);
	 sendEvent('stimulus.target',tgtNm);
	 if ( animateFix )
		animateDuration=epochDuration;
		t0  =getwTime();
		timetogo=animateDuration;
		fixPos=[stimPos(:,end)-cursorSize/2;cursorSize*[1;1]];
		while ( timetogo > 0 )
		  dx=randn(2,1)*animateStep;
		  fixPos(1:2) = fixPos(1:2)+dx;
		  set(h(end),'position',fixPos);
		  drawnow;		
		  sleepSec(min(max(0,timetogo),frameDuration));
		  timetogo = animateDuration- (getwTime()-t0); % time left to run in this trial
		end
										  % reset fix pos
		set(h(end),'position',[stimPos(:,end)-cursorSize/2;cursorSize*[1;1]]);
	 else
		drawnow;% expose; % N.B. needs a full drawnow for some reason
				  % wait for trial end
		sleepSec(epochDuration);
	 end
  end
  if ( animateFix )										  % reset fix pos
	 set(h(end),'position',[stimPos(:,end)-cursorSize/2;cursorSize*[1;1]]);
  end
		
  % reset the cue and fixation point to indicate trial has finished
  % update progress bar
  set(progresshdl,'string',sprintf('%2d/%2d',si,nSeq));
  % wait for the inter-trial
  set(h(:),'facecolor',bgColor);
  if ( ~isempty(symbCue) ) set(txthdl,'visible','off'); end
  drawnow;
  ev=sendEvent('stimulus.trial','end');
  if ( ~isempty(rtbClass) ) % treat post-trial return-to-baseline as a special class
	 for ei=1:ceil(intertrialDuration/epochDuration); % loop over sub-trials
		if ( ischar(rtbClass) && strcmp(rtbClass,'trialClass') ) % label as part of the trial
		  sendEvent('stimulus.target',tgtNm,ev.sample);
		elseif ( ischar(rtbClass) && strcmp(rtbClass,'trialClass+rtb')) %return-to-base ver of trial class
		  sendEvent('stimulus.target',[tgtNm '_rtb'],ev.sample);		
		else
		  sendEvent('stimulus.target',rtbClass,ev.sample);
		end
		sleepSec(epochDuration);
	 end
  else
    sleepSec(intertrialDuration);
  end

  
  ftime=getwTime();
  fprintf('\n');
end % sequences
% end training marker
sendEvent('stimulus.training','end');

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'That ends the training phase.','Thanks for your patience'}, 'visible', 'on', 'color',[0 1 0]);
pause(3);
end
