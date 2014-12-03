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

seqFlashes = ceil(feedbackMoveDuration ./ (stimDuration*nSymbs));
stimSeq=zeros(numel(h)-1,seqFlashes); % to store the actual stimulus state
flash=zeros(1,seqFlashes); % stores the flash times
pred=zeros(2,seqFlashes); % stores the classifier predictions
nFlash=0; nPred=0;
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
    % move direction is the weighted sum of all the symbol directions
    %dv = stimSeq(:,1:min(nPred,nFlash))*pred(2,1:nPred)'; 
    p  = 1./(1+exp(-dv)); p=p./sum(p); % norm letter prob      
    dxy  = stimDirections*p(:);    
    if ( verb>=0 ) 
      fprintf('%d) Prob:(%s) -> dxy: (%5.4f,%5.4f)\n',nMoves,sprintf('%3.2f ',p),dxy); 
    end;
    % clear the accumulated info
    dv(:)=0; nFlash=0; nPred=0;
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
    nFlash=nFlash+1; stimSeq(:,nFlash)=ev.value(:); flash(nFlash)=ev.sample; % record info about what changed
    if (verb>0) fprintf('Event: %s\n',ev2str(ev)); end;
  end;

  % process and accumulate any prediction events whilst the stimulus is running
  [events,state,nsamples,nevents]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],0);
  % process the predictions we've got
  for ei=1:numel(events);
    nPredei = find(flash(1:nFlash)==events(ei).sample); % find the flash this prediction is for
    if ( isempty(nPredei) ) 
      if ( verb>0 ) fprintf('Pred without flash =%d\n',events(ei).value); end;
      continue;
    end
    nPred=max(nPred,nPredei);
    pred(:,nPredei)=[events(ei).sample; events(ei).value];
    if ( verb>0 ) fprintf('%d) samp=%d pred=%g\n',nPredei,pred(:,nPredei)); end;
    dv = stimSeq(:,1:min(nPred,nFlash))*pred(2,1:nPred)'; 
    p  = 1./(1+exp(-dv)); p=p./sum(p); % norm letter prob      
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