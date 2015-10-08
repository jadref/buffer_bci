configureCursor;

% struct representing types moves available, N.B. ensure aligns with the stim order!
%  Also N.B. the y-axis is reversed! so +=down, -=up!
moves=struct('name',{{'none' 'right' 'up' 'left' 'down'}},'dxy',[0 1 0 -1 0;0 0 1 0 -1]);

% make bci stim sequence
[stimSeq,stimTime]=mkStimSeqRand2Color(vnSymbs,ceil(feedbackMoveDuration/isi/vnSymbs)*vnSymbs*10,isi);
stimSeq(nSymbs+1:end,:)=[];  % remove the extra symbol

% make the stimulus
%figure;
clf;
fig=gcf;
set(fig,...%'units','normalized','position',[0 0 1 1],...
    'Name','BCI Cursor control -- close to quit.','toolbar','none','menubar','none','color',[0 0 0],...
    'backingstore','on','renderer','painters');
ax=axes('position',[0.025 0.05 .825 .85],'units','normalized','visible','off','box','off',...
         'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
         'color',[0 0 0],'drawmode','fast',...
         'xlim',axLim,'ylim',axLim,'Ydir','reverse');%,'DataAspectRatio',[1 1 1]);
arrowcoords=loadPatchCoords('arrow.coords');
[ax,h,stimPos,stimPCoords]=initCursorStim(ax,0,0,arrowScale,nSymbs,arrowcoords);
stimDirections=stimPos(:,1:end-1); % N.B. ignore the fix point...
% summary of the stimulus state, used for re-drawing/moving the cursor
state=struct('ax',ax,'hdls',h,'stimSeq',stimSeq,'stimTime',stimTime,...
             'startTime',[],'curStim',1,'curstimState',stimSeq(:,1),...
             'bgColor',bgColor,'tgtColor',tgtColor,'tgt2Color',tgt2Color,...
             'cursorPos',[0;0],'stimPos',stimPos,'stimPCoords',stimPCoords,'sizeStim',sizeStim);


% 5 sec pause to get to the right window
drawnow;
pause(5); % N.B. pause allows to redraw figure window
  
nMoves=0; nframe=0;
curdir=1; dv=zeros(nSymbs,1); ndv=0;
startTime=getwTime(); 
ftime=startTime;
startTime=startTime; curStim=1; pred=[]; 
frametime=[]; drawTime=ftime; moveTime=ftime; speedupTime=ftime;
sendEvent('stimulus.test','start'); % mark start play
state=[];
dxy=zeros(2,1);
while ( nMoves<feedbackMoves)

  if ( ~ishandle(fig) ) break; end;
  
  nframe=nframe+1;
  ftime=getwTime();
  frametime(nframe,1)=ftime;
    
  moveFrame = ( ftime-moveTime > feedbackMoveDuration );
  if ( ~moveFrame )
    dxy(:)=0; % no move
  else
    moveTime=ftime;
    nMoves=nMoves+1;
    
    % get most up-to-date direction prediction
    % send the end sequence event
    sendEvent('stimulus.endSeq',true,-1);
    % now wait for the final prediction -- max of 60ms
    [events,state,nsamples,nevents]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],60);
    % process the predictions we've got
    for ei=1:numel(events);
      pred = events(ei).value;
      pred(end+1:numel(dv))=0;
      if ( ~isempty(alpha) )     dv = alpha*dv(:) + (1-alpha)*pred(1:numel(dv));
      else                       dv =       dv(:) +           pred(1:numel(dv));
      end
    end
    % move direction is the weighted sum of all the symbol directions
    prob = 1./(1+exp(dv)); prob=prob./sum(prob); % convert to valid class probabilities
    dxy  = stimDirections*prob(:);    
    
    if ( verb>=0 ) 
      fprintf('%d) Prob:(%s) -> dxy: (%5.4f,%5.4f)\n',nMoves,sprintf('%3.2f ',prob),dxy); 
    end;
    % clear the accumulated info
    dv(:)=0;
    
    % hack: pause stimulus by setting last stimTime xxx ms later than it should be
    state.startTime = state.startTime + interSeqDuration;
  end  

  %....... move cursor & surrounding stimulus, generate event when stimulus changes
  [ev,state]=drawStimulus(getwTime(),state,dxy);

  frametime(nframe,2)=getwTime();
  odrawTime=drawTime;
  
  % sleep for the rest of the frame and then draw
  sleepSec(max(0,isi-(getwTime()-odrawTime))); % exactly isi ms between calls to drawnow
  drawTime=getwTime();
  frametime(nframe,3)=drawTime;
  drawnow;
  frametime(nframe,4)=getwTime();
  if ( ~isempty(ev) ) 
    ev=sendEvent(ev); 
    if (verb>1) fprintf('Event: %s\n',ev2str(ev)); end;
  end;

  % process and accumulate any prediction events whilst the stimulus is running
  % now wait for the final prediction -- max of 60ms
  [events,state,nsamples,nevents]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],60);
  % process the predictions we've got
  for ei=1:numel(events);
    pred = events(ei).value;
    pred(end+1:numel(dv))=0;
    if ( ~isempty(alpha) )     dv = alpha*dv(:) + (1-alpha)*pred(1:numel(dv));
    else                       dv =       dv(:) +           pred(1:numel(dv));
    end
  end
  frametime(nframe,6)=getwTime();        
end % Move while

sendEvent('stimulus.test','end');

% show the GAME OVER message
if ( ishandle(fig) ) 
  axes(ax);
  text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),{'That ends the feedback phase.','I hope you had fun.'},'HorizontalAlignment','center','color',[0 1 0],'fontunits','normalized','FontSize',.1);
  pause(3);
end
return;