configureIM;
% add the generic im experiment directory for the generic stimulus files
addpath('../imaginedMovement');

initgetwTime;
initsleepSec;


                         % Initialize buffer-prediction processing variables:
buffstate=[];
predFiltFn=[]; % additional filter function for the classifier predictions? %-contFeedbackFiltLen; % average full-trials worth of predictions
filtstate=[];
predType =[];

% pre-build the time-line for the whole experiment
tgtSeq=mkStimSeqRand(nSymbs,nSeq);
% insert the rest between tgts to make a complete stim sequence + event seq with times
trlEP   = (trialDuration+baselineDuration+intertrialDuration)./epochDuration;
stimSeq = zeros(size(tgtSeq,1)+1,size(tgtSeq,2)*trlEP);
%zeros(size(tgtSeq,1)+1,size(tgtSeq,2)*(trialDuration+baselineDuration+intertrialDuration)./epochDuration);										  
stimTime=(0:size(stimSeq,2))*epochDuration; % stimulus times										  
eventSeq=true(1,size(stimSeq,2));           % when to send events

										  % the normal trials
stimSeq(1:nSymbs,:)=reshape(repmat(tgtSeq,trlEP,1),size(tgtSeq,1),[]); % tgts
stimSeq(nSymbs+1,:)=0; % add a stimseq for the rest/baseline cue
										  % the baseline phase
for ei=1:ceil(baselineDuration/epochDuration);
  stimSeq(:,ei:trlEP:end)=0; % everybody else is off
  stimSeq(nSymbs+1,ei:trlEP:end)=1; % rest is on
end
			% the RTB phase at end of every trial ends with a RTB = no stimulus & no event
for ei=1:ceil(intertrialDuration/epochDuration);
  stimSeq(:,trlEP+1-ei:trlEP:end)=0;
  if ( isempty(rtbClass) ) 
	 eventSeq(1,trlEP+1-ei:trlEP:end)=false; % don't send event
  end
end

% visible window is just 10s
visDur   = 10;
% number frames store in the visible window, padded with enough extra to not need updating during trial
visFrames= (stimTime(end)+visDur)./frameDuration;  % whole sequence in window
visImg   = zeros(nSymbs,visFrames,3); % rgb image to render
visT0    = 0; % absolute time visible fragement of the image starts
visEnd   = 0; % index of the end of the valid part of the image

										  % render stimSeq into the visImage
  epI=[];
  for fi=visEnd+1:size(visImg,2); % render into the frameBuffer
	 visImg(:,fi,:) = repmat(bgColor,size(visImg,1),1); % start as background color
	 starttfi= visT0+(fi-1)*frameDuration; % start time for the current frame
	 % find which epoch contains this frame
	 if ( isempty(epI) ) 
		epI=find(starttfi>=stimTime,1,'last');
	 else
		if ( starttfi>=stimTime(min(end,epI+1)) ) epI=epI+1; end % move to next epoch of needed
	 end
	 if ( ~isempty(epI) && epI<size(stimSeq,2) )
		ss=stimSeq(:,epI);
		if ( any(ss>0) ) % set target cols
		  if ( ss(end) ) % rest
			 visImg(:,fi,:)             =repmat(fixColor,nSymbs,1);
		  else % tgt
			 visImg(ss(1:nSymbs)>0,fi,:)=repmat(tgtColor,sum(ss(1:nSymbs)>0),1);
		  end
		end
	 end
  end
  visEnd=fi; % update the end valid-data indicator


% make the stimulus
%figure;
fig=figure(2);
set(fig,'Name','Imagined Movement','color',winColor,'menubar','none','toolbar','none','doublebuffer','on');
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',winColor,'DrawMode','fast','nextplot','replacechildren',...
        'xlim',axLim,'xlimmode','manual','ylim',axLim,'ylimmode','manual','Ydir','normal');
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels

clear h;
% setup for the runway: N.B. xdata/ydata are the centers of the pixels!
xdata=[axLim(1)+.3*diff(axLim) axLim(2)]; ydata=axLim;
h(1)=image('xdata',mean(xdata)+diff(xdata)/2*[-1 1]*(visFrames-1)/visFrames,...
			  'ydata',mean(ydata)+diff(ydata)/2*[-1 1]*(nSymbs-1)/nSymbs,'cdata',repmat(shiftdim(bgColor(:),-2),[nSymbs,visFrames,1])); % start 10% into the axes
imgh=h(1);
										  % add labels for each row.
ylim=get(ax,'ylim'); ypos=linspace(ylim(1),ylim(2),nSymbs+2); ypos=ypos(2:end-1);
symbSize_px = .08*wSize(4);
for si=1:nSymbs;
  snm=sprintf('%d',si);
  if ( ~isempty(symbCue) ) snm=sprintf('%d %s',si,symbCue{si}); end;
  h(si+1)=text(axLim(1)+.3*diff(axLim),ypos(si),snm,...
					'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle',...
					'fontunits','pixel','fontsize',symbSize_px,...
					'color',txtColor,'visible','on');
end

										  % clear the display
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

% wait for starting button press
set(txthdl,'string', 'Click mouse when ready', 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;

sendEvent('stimulus.training','start');

% play the stimulus
% feedback info
state  = [];
dv     = zeros(nSymbs+1,1);
prob   = ones(nSymbs+1,1)./(nSymbs+1); % start with equal prob over everything
nWrong=0; nMissed=0; nCorrect=0; % performance recording

ofi=-1;
t0=getwTime(); % absolute start time for the experiment
waitforkeyTime=getwTime()+calibrateMaxSeqDuration;
for ei=1:size(stimSeq,2);

  % update progress bar
  set(progresshdl,'string',sprintf('%2d/%2d +%02d -%02d',ei,size(stimSeq,2),nCorrect,nWrong));

  % Give user a break if too much time has passed
  if ( getwTime() > waitforkeyTime && stimSeq(end,ei) ) % only wait in a inter-trial phase
	 b0=getwTime();
	 set(txthdl,'string', {'Break between blocks.' 'Click mouse when ready to continue.'}, 'visible', 'on');
	 drawnow;
	 waitforbuttonpress;
	 set(txthdl,'visible', 'off');
	 drawnow;
	 sleepSec(intertrialDuration);

    % process any events which came in while we were waiting
	 processNewPredictionEvents;

	 waitforkeyTime=getwTime()+calibrateMaxSeqDuration;
	 if ( 1.5*calibrateMaxSeqDuration > (size(stimSeq,2)-ei)*frameDuration  ) % close to end of expt
	 end
    % update the start time, as if started later to compensate for the time spent waiting
	 t0 = t0+getwTime()-b0;;
  end
  
  tgtIdx=find(stimSeq(:,ei)>0);
  % send the epoch events
  if ( ~eventSeq(ei) ) % should we send an event
	 set(txthdl,'string','','color',txtColor,'visible','on');		  
  else
	 if ( stimSeq(end,ei) ) % baseline epoch
		sendEvent('stimulus.baseline','start');
		if ( ~isempty(baselineClass) ) % treat baseline as a special class
		  sendEvent('stimulus.target',baselineClass);
		  if ( verb>1 ) set(txthdl,'string',baselineClass,'color',txtColor,'visible','on'); end;
		else
		  if ( verb>1 ) set(txthdl,'string','rest','color',txtColor,'visible','on'); end;
		end
	 elseif ( any(stimSeq(1:nSymbs,ei)>0) ) % target action epoch
		if ( ~isempty(symbCue) )
		  tgtNm = '';
		  for ti=1:numel(tgtIdx);
			 if(ti>1) tgtNm=[tgtNm ' + ']; end;
			 tgtNm=sprintf('%s%d %s ',tgtNm,tgtIdx,symbCue{tgtIdx});
		  end
		else
		  tgtNm = sprintf('%d',tgtIdx); % human-name is position number
		end
		fprintf('%d) tgt=%10s : \n',ei,tgtNm);
		if ( verb>1 ) set(txthdl,'string',tgtNm,'color',txtColor,'visible','on'); end
		sendEvent('stimulus.target',tgtNm);
	 else % return to base-line phase
		if ( ~isempty(rtbClass) ) % send a special RTB event to mark this up
		  if ( ischar(rtbClass) && strcmp(rtbClass,'trialClass') ) % label as part of the trial
			 sendEvent('stimulus.target',tgtNm);
		  elseif ( ischar(rtbClass) && strcmp(rtbClass,'trialClass+rtb') ) % return-to-base + trial class
			 sendEvent('stimulus.target',[tgtNm '_rtb']);		
		  else
			 sendEvent('stimulus.target',rtbClass);
		  end
		end
	 end
  end

										  % run the animation for this epoch
  et=getwTime()-t0;
  eventWaitTime=frameDuration*.5; % max time to wait for prediction events
  fprintf('%d) Tgt=[%6.2f-%6.2f]\tTrue=%6.2f\tdiff=%g\n',ei,stimTime(ei:ei+1),et,et-stimTime(ei));
  while ( et<stimTime(ei+1) ) % run until next epoch
	 % do other slow stuff/display update in here
	 [dv,prob,buffstate,filtstate]=processNewPredictionEvents([],[],buffstate,predType,eventWaitTime*1000,predFiltFn,filtstate,1);
    if( ~isempty(dv) )
	            % update the feedback display -- change size of the row labels
	   [ans,predTgt]=max(prob);
      for hi=1:nSymbs;
		  set(h(hi+1),'fontSize',symbSize_px*(1+.5*(prob(hi)-1/nSymbs)),'color',txtColor);
		  if(hi==predTgt) set(h(hi+1),'color',fbColor); end;
	   end;	 
    end
    
	 % update the runway display
	 et=getwTime()-t0;
	 ofi=fi;	 fi=max(0,floor(et/frameDuration))+1; % get current frame index
	 if ( fi-ofi>1 )
		fprintf('%d) Dropped frames %d...\n',fi,fi-ofi-1);
	 end
	 set(imgh,'cdata',visImg(:,fi+(0:visDur/frameDuration-1),:)); % update display
										  % sleep until the frame is due
	 sleepSec(max(0,frameDuration*fi-et));
	 drawnow;
	 % get update elapsed time
	 et=getwTime()-t0;
  end
  if ( et < stimTime(ei+1) )
      keyboard;
  end
										  % send the predicted target
  sendEvent('stimulus.predTgt',predTgt);

										  % update the score
  if ( ~isempty(tgtIdx) && any(tgtIdx<=nSymbs) ) 
	 if ( predTgt>nSymbs )          nMissed = nMissed+1; 
	 elseif(~any(predTgt==tgtIdx) ) nWrong  = nWrong+1;  % wrong (and not 'rest') .... do the penalty
	 elseif( any(predTgt==tgtIdx) ) nCorrect= nCorrect+1;% correct
	 end
  end

end
% end training marker
sendEvent('stimulus.training','end');

if ( ishandle(fig) ) % thanks message
  set(h,'visible','off');
set(txthdl,'string',{'That ends the training phase.','Thanks for your patience'}, 'visible', 'on', 'color',[0 1 0]);
pause(3);
end
