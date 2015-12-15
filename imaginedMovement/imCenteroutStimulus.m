configureIM;
if ( ~exist('centerOutTrialDuration') || isempty(centerOutTrialDuration) ) 
   centerOutTrialDuration=trialDuration; 
end;
% OVERRIDE number of symbols......
nSymbs=4;

% make the stimulus
%figure;
fig=figure(2);
clf;
set(fig,...%'units','normalized','position',[0 0 1 1],...
    'Name','BCI Cursor control','toolbar','none','menubar','none','color',[0 0 0],...
    'renderer','painters');
ax=axes('position',[0.025 0.05 .95 .9],'units','normalized','visible','off','box','off',...
         'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
         'color',[0 0 0],'drawmode','fast',...
         'xlim',axLim,'ylim',axLim,'Ydir','reverse');%,'DataAspectRatio',[1 1 1]);

stimRadius=diff(axLim)/8;
cursorSize=stimRadius/2;

% left block
wdth=diff(axLim); hght=diff(axLim);
h(1) =rectangle('curvature',[0 0],'position',[[axLim(1);-hght/2*stimAngle];[stimRadius;stimAngle*hght]],'facecolor',bgColor); 
% top block
h(2) =rectangle('curvature',[0 0],'position',[[-wdth/2*stimAngle;axLim(1)];[stimAngle*wdth;stimRadius]],'facecolor',bgColor); 
% right block
h(3) =rectangle('curvature',[0 0],'position',[[axLim(2)-stimRadius;-hght/2*stimAngle];[stimRadius;stimAngle*hght]],'facecolor',bgColor);
% bottom block
h(4) =rectangle('curvature',[0 0],'position',[[-wdth/2*stimAngle;axLim(2)-stimRadius];[stimAngle*wdth;stimRadius]],'facecolor',bgColor);  
% get stimulus positions
stimPos = get(h(1:4),'position'); stimPos=cat(1,stimPos{:})'; stimPos=stimPos(1:2,:);
% cursor
initCursorPos=[[0;0]-cursorSize/2;[1;1]*cursorSize]';
h(5) =rectangle('curvature',[1 1],'position',initCursorPos,'facecolor',bgColor); 
% add symbol for the center of the screen
set(gca,'visible','off');

%Create a text object with no text in it, center it, set font and color
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',[0.75 0.75 0.75],'visible','off');


% show the instructions
set(h,'visible','off');
set(txthdl,'string',centeroutinstruct,'visible','on');drawnow;
waitforbuttonpress;
set(txthdl,'visible','off');
set(h,'visible','on');
drawnow;

% play the stimulus
sendEvent('stimulus.centerout','start');

% make the target sequence for this block
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

frametime=[]; nframe=0;
for si=1:nSeq;

  if ( ~ishandle(fig) ) break; end;
  
  % show the target  
  fprintf('%d) tgt=%d : ',si,find(tgtSeq(:,si)>0));
  set(h(tgtSeq(:,si)>0),'facecolor',tgtColor);
  set(h(tgtSeq(:,si)<=0),'facecolor',bgColor);
  set(h(end),'position',initCursorPos); % reset fixatation position
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  tgtId=find(tgtSeq(:,si)>0);
  ev=sendEvent('stimulus.target',tgtId);
  if ( verb>1 ) fprintf('Sending target : %s\n',ev2str(ev)); end;
  sleepSec(cueDuration);
  set(h(:),'facecolor',bgColor);
  drawnow;
  sleepSec(startDelay);
  
  % play the stimulus
  set(h(end),'facecolor',tgtColor); % green cursor indicates trial running
  tgtPos  = get(h(tgtId),'position'); tgtPos=tgtPos(:);
  tgtxy   = tgtPos(1:2)+tgtPos(3:4)/2;
  state   = [];
  trlStartTime=getwTime();
  drawTime=trlStartTime;
  timetogo=centerOutTrialDuration;
  while ( timetogo > 0 ) 
    timetogo = trialDuration - (getwTime()-trlStartTime); % time left to run in this trial

    dx = []; % start with no change
	 % wait for new prediction events or out of time
    [events,state,nsamples,nevents] = buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],min(1000,timetogo*1000));
    if ( ~isempty(events) ) 
      [ans,si]=sort([events.sample],'ascend'); % proc in *temporal* order
      for ei=1:numel(events);
        ev=events(si(ei));% event to process
		  pred=ev.value; % event value is x then y output
		  if ( numel(pred)==1 ) pred=[pred(:);0]; end; % map 1-d => x-coord
		  % simply accumulate the predictions if more than 1
		  if ( isempty(dx) ) dx = pred(:) ; else dx = dx + pred(:); end;
	   end
		  if ( verb>0 ) fprintf('dx=[%d %d]\n',dx(1:2));end
	 end	 
		
	 if ( numel(dx)==size(stimPos,2)-1 ) % per-target decomposition
		dx = stimPos(:,1:end-1)*dx(:); % convert into x,y change
	 end
    if ( ~ishandle(fig) ) break; end; % exit cleanly if exit event
    cursorPos=get(h(end),'position'); cursorPos=cursorPos(:);
	 fixPos   =cursorPos(1:2)+cursorPos(3:4)/2; % pos of the center of the ball
	 if ( ~isempty(dx) ) % update cursor position
		if ( warpCursor ) fixPos=dx; else fixPos=fixPos+dx*moveScale; end; %rel or abs cursor position
	 end
	 set(h(end),'position',[fixPos(:)-cursorPos(3:4)/2;cursorPos(3:4)]);
	 sendEvent('stimulus.cursorPos',fixPos);
    drawnow; 

	 % tgt collision test
	 cursorPos=get(h(end),'position'); cursorxy=cursorPos(1:2)+cursorPos(3:4)/2;
	 if ( cursorxy(1) > tgtPos(1) && cursorxy(1)<tgtPos(1)+tgtPos(3) &&...
			cursorxy(2) > tgtPos(2) && cursorxy(2)<tgtPos(2)+tgtPos(4) )
		 break; 
	 end
  end
  fprintf('\n');
  if ( ~ishandle(fig) ) break; end;
  set(h(:),'facecolor',bgColor);
  drawnow;
  sleepSec(intertrialDuration);  
end % sequences

% end training marker
sendEvent('stimulus.centerout','end');
% show the end training message
if ( ishandle(fig) ) 
pause(1);
axes(ax);
text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),{'That ends the training phase.','Thanks for your patience'},'HorizontalAlignment','center','color',[0 1 0],'fontunits','normalized','FontSize',.1);
pause(3);
end
