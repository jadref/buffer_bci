configureGame;

%moveInterval=maxMoveInterval;
zoomed=false; if ( level>2 ) zoomed=true; end;
max_moves=500;
fname=sokobanLevels{min(end,level)};%'soko1.lv';%'level1.lv';% 'race.lv';% 
[map,agents,key]=loadLevel(fname,'sokoban');
[nr,nc]=size(map);
% struct representing types moves available, N.B. ensure aligns with the stim order!
%  Also N.B. the y-axis is reversed! so +=down, -=up!
moves=struct('name',{{'none' 'right' 'up' 'left' 'down'}},'dxy',[0 1 0 -1 0;0 0 1 0 -1]);

% make bci stim sequence
[stimSeq,stimTime]=mkStimSeqRand2Color(vnSymbs,ceil(moveInterval/isi/vnSymbs)*vnSymbs*10,isi);
stimSeq(nSymbs+1:end,:)=[];  % remove the extra symbol
% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

% init game display
score=0;
clf;
mancoords=loadPatchCoords('man.coords');
[arenaax,maph,agentsh,titleax,scoreh,moveh]=initSokobanDisplay([],map,agents,key,score,mancoords);

% init stim display
[manx,many]=find(agents==key.man);
arrowcoords=loadPatchCoords('arrow.coords');
[ax,stimh,stimPos,stimPCoords]=initBCIStim(arenaax,manx,many,arrowScale,nSymbs,arrowcoords);
stimState=struct('hdls',stimh,'stimSeq',stimSeq,'stimTime',stimTime,...
    'startTime',[],'curStim',1,'curstimState',zeros(numel(stimh),1),'visibleStim',ones(numel(stimh),1),...
    'bgColor',bgColor,'tgtColor',tgtColor,'tgt2Color',tgt2Color,...
    'stimPos',stimPos,'stimPCoords',stimPCoords,'sizeStim',sizeStim);
visibleStim=stimState.visibleStim;

% init state
status=buffer('wait_dat',[-1 -1 -1]); % current sample info
nevents=status.nevents; nsamples=status.nsamples;

% zoom display...
if ( zoomed ) 
  tgtxlim = manx+zoomedLim;        tgtylim=many+zoomedLim;
  xlim=get(arenaax,'xlim');     ylim=get(arenaax,'ylim');
  dxlim   =xlim-tgtxlim;        dylim  =ylim-tgtylim;
  for i=linspace(1,0,60);
    set(arenaax,'xlim',tgtxlim+dxlim*i,'ylim',tgtylim+dylim*i);
    sleepSec(1/30);
    if ( ispc() ) drawnow; else drawnow expose; end;
  end
end

% 5 sec pause to get to the right window
drawnow;
pause(5); % N.B. pause allows to redraw figure window

lives=nLives; % Lives
nMoves=0; nframe=0; dxy=[0;0]; 
curdir=1; dv=zeros(nSymbs,1); ndv=0;
startTime=getwTime(); 
ftime=startTime;
stimState.startTime=startTime; stimState.curStim=1; pred=[]; 
frametime=[]; drawTime=ftime; moveTime=ftime;
sendEvent('stimulus.test','start'); % mark start play
goalReached=false;
while( lives && nMoves<max_moves )
  while( nMoves<max_moves && ~goalReached )
    goalReached = all(agents(map(:)==key.goal)==key.block);
    nframe=nframe+1;
    ftime=getwTime();
    frametime(nframe,1)=ftime;
    
    moveFrame = ( ftime-moveTime > moveInterval );
    if ( ~moveFrame )
      dxy(:)=0; % no move
    else
      moveTime=ftime;
      nMoves=nMoves+1;
      
      % get most up-to-date direction prediction
      % send the end sequence event
      sendEvent('stimulus.endSeq',true,-1);
      % now wait for the final prediction
      status=buffer('wait_dat',[-1 -1 60],buffhost,buffport); % get current state
      if ( status.nevents > nevents ) % new events to process
        events=buffer('get_evt',[nevents status.nevents-1],buffhost,buffport);
        [dv,predevIdx]=procPredEvents(events,{{'stimulus.prediction'}},dv,predAlpha,verb);
        nevents = status.nevents;
      end

      curdir=0;
      if ( all(visibleStim) )
        [ans,curdir]=max(dv); % get max prob symb            
      else
        vsi = find(visibleStim);
        [ans,curdir]=max(dv(vsi)); % get max prob symb
        curdir = vsi(curdir); % best from the visible set
      end
      if ( keyboardControl )
        k=get(gcf,'currentkey');%waitkey(gcf);
        switch (k)
         case {'d','rightarrow'}; curdir=1;
         case {'w','uparrow'}; curdir=2;
         case {'a','leftarrow'}; curdir=3;
         case {'s','downarrow'}; curdir=4;
        end
      end
      curdir=curdir+1;
      % reset classifier
      dv(:)=0; 

      %[curdir]=getPacMove(map,agents,moves);
      dxy  = validateSokobanMove(map,agents,key,dxy,moves.dxy(:,curdir));
      
      [map,maph,agents,agentsh]=moveSokoban(arenaax,map,maph,agents,agentsh,key,dxy,zoomed);
      %score=score+scorei;
      drawDisplay(map,maph,agents,agentsh,score,scoreh,nMoves,moveh); 

      % hack: pause stimulus by setting last stimTime xxx ms later than it should be
      stimState.startTime = stimState.startTime + movePause;
    end
    [ev,stimState]=drawStim(getwTime(),stimState,dxy);
    frametime(nframe,2)=getwTime();
    odrawTime=drawTime;
    if ( 0 & ispc() )
      sleepSec(max(0,isi-(getwTime()-odrawTime)-50/1000)); % exactly isi ms between calls to drawnow
      while ( isi-(getwTime()-odrawTime)>0 ); end; % live wait - reduces expose variance?
      drawTime=getwTime();
      frametime(nframe,3)=drawTime;
      drawnow;
    else
      sleepSec(max(0,isi-(getwTime()-odrawTime))); % exactly isi ms between calls to drawnow
      drawTime=getwTime();
      frametime(nframe,3)=drawTime;
      drawnow;
    end
    frametime(nframe,4)=getwTime();
    if ( ~isempty(ev) ) 
      ev=sendEvent(ev); 
      if (verb>1) fprintf('Event: %s\n',ev2str(ev)); end;
    end;

    % wait for move events
    status=buffer('wait_dat',[-1 -1 -1],buffhost,buffport); % get current state
    stime =getwTime();     frametime(nframe,5)=stime;
    if ( status.nevents > nevents ) % new events to process
      if ( nevents< status.nevents-50 ) nevents=status.nevents-50; end;
      events=buffer('get_evt',[nevents status.nevents-1],buffhost,buffport);
      [dv,predevIdx]=procPredEvents(events,{{'stimulus.prediction'}},dv,predAlpha,verb-1);
    end
    nevents=status.nevents; nsamples=status.nsamples;
    frametime(nframe,6)=getwTime();    
    
  end % PAC Move while
  if lives==0,break;end
  lives=lives-1;
end % while alive

fprintf('Moves %i\n',nMoves)
fprintf('Lives %i\n',lives)
fprintf('Time  %gs\n',(getwTime()-startTime));
fprintf('Frame %gms (%g,%g,%g)\n',(getwTime()-startTime)/nframe*1000,min(diff(frametime(:,1)))*1000,max(diff(frametime(:,1)))*1000,std(diff(frametime(:,1)))*1000)

if ( zoomed ) 
  tgtxlim =[.5 size(map,1)+.5];  tgtylim=[.5 size(map,2)+.5];
  xlim=get(arenaax,'xlim');     ylim=get(arenaax,'ylim');
  dxlim   =xlim-tgtxlim;        dylim  =ylim-tgtylim;
  for i=linspace(1,0,60);
    set(arenaax,'xlim',tgtxlim+dxlim*i,'ylim',tgtylim+dylim*i);
    sleepSec(1/30);
    if ( ispc() ) drawnow; else drawnow expose; end;
  end
end
sendEvent('stimulus.test','end');

% show the GAME OVER message
axes(arenaax);
if(goalReached) finText={'You Win!'}; else finText={'GAME' 'OVER'}; end;
text(mean(get(arenaax,'xlim')),mean(get(arenaax,'ylim')),finText,'HorizontalAlignment','center','color',[1 0 0],'fontunits','normalized','FontSize',.15);
pause(5);

return;
% close all;clf;subplot(211); plot(diff(frametime,[],2)*1000);set(gca,'ylim',[0 300]);title('proc time');subplot(212);plot(diff(frametime,[],1)*1000);set(gca,'ylim',[0 300]); title('inter frame');legend('drawing','framewait','expose','waitdata','procevents');


