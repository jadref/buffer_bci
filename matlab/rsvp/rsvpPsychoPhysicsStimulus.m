%==========================================================================
% Initialize the display
%==========================================================================
%Set the frame size for the stimulus frame, make axes invisible, 
%remove menubar and toolbar. Also set the background color for the frame.
stimfig = figure(2);
clf;
set(stimfig,'Name','Experiment - Training',...
    'color',framebgColor,'menubar','none','toolbar','none',...
    'renderer','painters','doublebuffer','on','Interruptible','off');

ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',axlim(:,1),'ylim',axlim(:,2),'Ydir','normal');
stimPos=[]; h=[];
% center block only
h(1) =rectangle('curvature',[1 1],'position',[[0;0]-stimRadius/2;stimRadius*[1;1]],'facecolor',bgColor); 
    
% add symbol for the center of the screen
set(gca,'visible','off');
set(stimfig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:))));
set(stimfig,'userdata',[]); % clear any old key info

set(stimfig,'Units','pixel');wSize=get(stimfig,'position');fontSize = .05*wSize(4);
instructh=text(min(get(ax,'xlim'))+.25*diff(get(ax,'xlim')),mean(get(ax,'ylim')),instructstr,'HorizontalAlignment','left','VerticalAlignment','middle','color',[0 1 0],'fontunits','pixel','FontSize',fontSize,'visible','off');

% add a 2nd figure for the detection curve?
detectfig=figure(3);set(detectfig,'Name','Detection curve');clf;
barh=bar(alphas,zeros(size(alphas)));set(gca,'xlim',[alphas(1)-diff(alphas(1:2)) alphas(end)+diff(alphas(end-1:end))]);
% ensure the stimulus figure is in the front
figure(2);

%==========================================================================
% 2. START STIMULUS PRESENTATION AND THE ACTUAL DISPLAY OF THINGS
%==========================================================================

%Change text object and display start-up texts
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'visible','off'); % make them all invisible
set(h(:),'facecolor',bgColor);
set(instructh,'visible','on');
waitforbuttonpress;
set(instructh,'visible', 'off');

%Send a start of training event
sendEvent('stimulus.training', 'start');

%Start the sequences
tgtIdx=1;
alphai=numel(alphas); % start with max difference
hits = zeros(2,numel(alphas));
for seqi = 1:nSeq
	 
  % make a simple odd-ball stimulus sequence, with targets mintti apart
  [stimSeq,stimTime,eventSeq] = mkStimSeqP300(1,seqDuration,isi,mintti,oddballp);
  
  % show the screen to alert the subject to trial start
  set(h(1:end-1),'visible','off');
  set(h(end),'visible','on','facecolor',fixColor); % red fixation indicates trial about to start/baseline
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');

  %Show target image
  set(h(1),'visible','on','facecolor',tgtColor);
  drawnow;
  sendEvent('stimulus.target',1);
  sleepSec(targetDuration);    
  set(h(:), 'visible', 'off','facecolor',bgColor);
  drawnow;
  if ( verb>0 ) fprintf('%d) tgt=%d\t',seqi,1); end;
  sleepSec(postTargetDuration);
  
  %Send an event to indicate that a sequence has started
  sendEvent('stimulus.sequence', 'start');
  % get current events status, i.e. discard all events before this time....
  status=buffer('wait_dat',[-1 -1 -1],buffhost,buffport); nevents=status.nevents;

  % now play the selected sequence
  seqStartTime=getwTime(); framei=0; ndropped=0; frametime=zeros(numel(stimTime),4); 
  nStim=0; nPred=0; % track the stimulus, and prediction state
  while ( stimTime(end)>=getwTime()-seqStartTime ) % frame-dropping version    
	 framei=min(numel(stimTime),framei+1);
	 frametime(framei,1)=getwTime()-seqStartTime;
	 % find nearest stim-time
	 if ( framei<numel(stimTime) && frametime(framei,1)>=stimTime(min(numel(stimTime),framei+1)) ) 
      oframei = framei;
      for framei=framei+1:numel(stimTime); if ( frametime(oframei,1)<stimTime(framei) ) break; end; end; % find next valid frame
      if ( verb>=0 ) fprintf('%d) Dropped %d Frame(s)!!!\n',framei,framei-oframei); end;
      ndropped=ndropped+(framei-oframei);
	 end
	 

	 ss=stimSeq(:,framei);	 
	 set(h(ss<0),'visible','off');  % neg stimSeq codes for invisible stimulus
	 set(h(ss>=0),'visible','on','facecolor',bgColor); % everybody starts as background color
	 if(any(ss==1))
		% compute what color we should use.....
		% alphai is index into the alphas vector saying what alpha we should actually be using
		alpha = alphas(max(1,min(round(alphai),numel(alphas))));
		% interpolate between tgt/bgColor to get the 
		color = colors(:,1) * alpha + colors(:,2)*(1-alpha);
		set(h(ss==1),'facecolor',color); 
		ss(ss==1)= alpha; % update the stim-state with the actual stim parameters
	 end% stimSeq codes into a colortable
	 if(any(ss==2))set(h(ss==2),'facecolor',colors(:,min(size(colors,2),2)));end;
	 if(any(ss==3))set(h(ss==3),'facecolor',colors(:,min(size(colors,2),3)));end;
    
	 % sleep until time to update the stimuli the screen
	 if ( verb>1 ) fprintf('%d) Sleep : %gs\n',framei,stimTime(framei)-(getwTime()-seqStartTime)-flipInterval/2); end;
	 sleepSec(max(0,stimTime(framei)-(getwTime()-seqStartTime))); % wait until time to call the draw-now
	 if ( verb>1 ) frametime(framei,2)=getwTime()-seqStartTime; end;
	 drawnow;
	 if(any(ss==-4))if(~isempty(audio{1}))play(audio{1});end;end;
	 if(any(ss==-5))if(~isempty(audio{2}))play(audio{2});end;end; 
	 if ( verb>1 ) 
      frametime(framei,3)=getwTime()-seqStartTime;
      fprintf('%d) dStart=%8.6f dEnd=%8.6f stim=[%s] lag=%g\n',framei,...
				  frametime(framei,2),frametime(framei,3),...
				  sprintf('%d ',stimSeq(:,framei)),stimTime(framei)-(getwTime()-seqStartTime));
	 end
	 % send event saying what we just showed
	 ev=[];
	 if ( ~isempty(eventSeq) )
		if ( ~isempty(eventSeq{si}) )
        ev=sendEvent(eventSeq{framei}{:});
		end
	 elseif ( any(ss>0) )
		ev=sendEvent('stimulus.stimState',ss);
	 end
    if (~isempty(ev) && verb>1) fprintf('%d) Event: %s\n',framei,ev2str(ev)); end;
	 
	 % record the displayed stimulus state, needed for decoding the classifier predictions later
	 if ( any(ss>0) )
		nStim=nStim+1;
		stimSamp(1,nStim)=ev.sample;  % record sample this event was sent
		dispStimSeq(:,nStim)=ss;   % record the status of the display for this flash
	   % pred(:,nStim)            % record of the classifier predictions for the corrospending events
	   % hits(:,2)                 % record the #times used, and #times hit for each stim
	 end

    % check for new events and collect
    status=buffer('wait_dat',[-1 -1 -1],buffhost,buffport); % non-blocking check for events
    if ( status.nevents > nevents ) % new events to process
      events=buffer('get_evt',[nevents status.nevents-1],buffhost,buffport);
      mi=matchEvents(events,'classifier.prediction');
      % store the predictions
      for ei=find(mi(:)');
        nPredei = find(stimSamp(1:nStim)==events(ei).sample); % find the flash this prediction is for
        if ( isempty(nPredei) ) 
          if ( verb>0 ) fprintf('Pred without flash =%d\n',events(ei).value); end;
          continue;
        end
        nPred=max(nPred,nPredei(1)); % keep track of the number of predictions which are valid
        pred(:,nPredei)=events(ei).value;

		  ishit = pred(tgtIdx,nPredei)>0;
		  % update the hits list
		  [ans,bini]=min(abs(alphas-dispStimSeq(nPredei))); % find the alpha-bin this is in
		  hits(1,bini)=hits(1,bini)+1;      % counts
		  hits(2,bini)=hits(2,bini)+ishit;  % hits

		  % update the alphai, if hit then decrease alpha, is miss then decrease in porption to 
		  % desired target hit rate so at that hit-rate average value remains fixed
		  if ( ishit ) alphai=alphai-hitmissstep*(1-pcorrect); % hit so make harder => decrease
		  else 			alphai=alphai+hitmissstep*pcorrect;     % miss so make easier => increase
		  end;
		  alphai=min(numel(alphas),max(1,alphai)); % limit the range of values...
		  
        if ( verb>0 ) 
			 if ( ishit ) hitmiss='hit'; else hitmiss='miss'; end;
			 fprintf('%d) samp=%d pred=%g (%4s) alphai=%g\n',...
						nStim,stimSamp(nPredei),pred(tgtIdx,nPredei),hitmiss,alphai); 
		  end;
      end

		% update the histogram display as we've got new predictions
		set(barh,'ydata',hits(2,:)./max(1,hits(1,:)));
    end
    nevents=status.nevents; % record which events we've processed

  end % sequence

  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'facecolor',bgColor,'visible','off');
  drawnow;
  sendEvent('stimulus.trial','end');
  sleepSec(interSeqDuration);

  fprintf('\n');
end

%Send an event to indicate that training has ended
sendEvent('stimulus.training', 'end');

%Thank subject and end experiment
if ( ishandle(instructh) ) 
set(instructh,'string', 'Thank you for participating!','visible', 'on');
drawnow;
end
