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
instructh=text(min(get(ax,'xlim'))+.15*diff(get(ax,'xlim')),mean(get(ax,'ylim')),instructstr,'HorizontalAlignment','left','VerticalAlignment','middle','color',[0 1 0],'fontunits','pixel','FontSize',fontSize,'visible','off');
 
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

  % now play the selected sequence
  seqStartTime=getwTime(); ei=0; ndropped=0; frametime=zeros(numel(stimTime),4);
  while ( stimTime(end)>=getwTime()-seqStartTime ) % frame-dropping version    
	 ei=min(numel(stimTime),ei+1);
	 frametime(ei,1)=getwTime()-seqStartTime;
	 % find nearest stim-time
	 if ( ei<numel(stimTime) && frametime(ei,1)>=stimTime(min(numel(stimTime),ei+1)) ) 
      oei = ei;
      for ei=ei+1:numel(stimTime); if ( frametime(oei,1)<stimTime(ei) ) break; end; end; % find next valid frame
      if ( verb>=0 ) fprintf('%d) Dropped %d Frame(s)!!!\n',ei,ei-oei); end;
      ndropped=ndropped+(ei-oei);
	 end
	 ss=stimSeq(:,ei);	 
	 set(h(ss<0),'visible','off');  % neg stimSeq codes for invisible stimulus
	 set(h(ss>=0),'visible','on','facecolor',bgColor); % everybody starts as background color
	 if(any(ss==1))set(h(ss==1),'facecolor',colors(:,1)); end% stimSeq codes into a colortable
	 if(any(ss==2))set(h(ss==2),'facecolor',colors(:,min(size(colors,2),2)));end;
	 if(any(ss==3))set(h(ss==3),'facecolor',colors(:,min(size(colors,2),3)));end;
    
	 % sleep until time to update the stimuli the screen
	 if ( verb>1 ) fprintf('%d) Sleep : %gs\n',ei,stimTime(ei)-(getwTime()-seqStartTime)-flipInterval/2); end;
	 sleepSec(max(0,stimTime(ei)-(getwTime()-seqStartTime))); % wait until time to call the draw-now
	 if ( verb>1 ) frametime(ei,2)=getwTime()-seqStartTime; end;
	 drawnow;
	 if(any(ss==-4))if(~isempty(audio{1}))play(audio{1});end;end;
	 if(any(ss==-5))if(~isempty(audio{2}))play(audio{2});end;end; 
	 if ( verb>1 ) 
      frametime(ei,3)=getwTime()-seqStartTime;
      fprintf('%d) dStart=%8.6f dEnd=%8.6f stim=[%s] lag=%g\n',ei,...
				  frametime(ei,2),frametime(ei,3),...
				  sprintf('%d ',stimSeq(:,ei)),stimTime(ei)-(getwTime()-seqStartTime));
	 end
	 % send event saying what the updated display was
	 ev=[];
	 if ( ~isempty(eventSeq) )
		if ( ~isempty(eventSeq{si}) )
        ev=sendEvent(eventSeq{ei}{:});
		end
	 elseif ( any(ss>0) )
		ev=sendEvent('stimulus.stimState',ss);		               % total stimulus state
		sendEvent('stimulus.tgtState',ss(tgtIdx)==1,ev.sample);	% indicate if 'target' flash
	 end
    if (~isempty(ev) && verb>1) fprintf('%d) Event: %s\n',ei,ev2str(ev)); end;
  end

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
sleepSec(interSeqDuration);
end
