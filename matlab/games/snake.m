configureGame;

zoomed=false;
%moveInterval=maxMoveInterval;
%nSymbs=4;
fname=snakeLevels{min(end,level)};'snake1.lv';%'level1.lv';% 'race.lv';% 
[map,agents,key]=loadLevel(fname,'snake');
agents=struct('map',agents,'snake',extractSnake(agents,key)); % get the snake info
[nr,nc]=size(map);
% struct representing types moves available, N.B. ensure aligns with the stim order!
%  Also N.B. the y-axis is reversed! so +=down, -=up!
moves=struct('name',{{'none' 'right' 'up' 'left' 'down'}},'dxy',[0 1 0 -1 0;0 0 1 0 -1]);

% make bci stim sequence
[stimSeq,stimTime]=mkStimSeqRand2Color(vnSymbs,ceil(moveInterval/isi/vnSymbs)*vnSymbs*10,isi);
stimSeq(nSymbs+1:end,:)=[];  % remove the extra symbol
%[stimSeq,stimTime]=mkStimSeqRand2Color(nSymbs,nSymbs*300,isi);
% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

% init game display
score=0;
clf;
[arenaax,maph,agentsh,titleax,scoreh,moveh]=...
    initSnakeDisplay([],map,agents.map,key,score);

% init stim display
[pacx,pacy]=find(agents.map==key.snakehead);
arrowcoords=loadPatchCoords('arrow.coords');
[ax,stimh,stimPos,stimPCoords]=initBCIStim(arenaax,pacx,pacy,arrowScale,nSymbs,arrowcoords);
stimState=struct('hdls',stimh,'stimSeq',stimSeq,'stimTime',stimTime,...
    'startTime',[],'curStim',1,'curstimState',zeros(numel(stimh),1),'visibleStim',ones(numel(stimh),1),...
    'bgColor',bgColor,'tgtColor',tgtColor,'tgt2Color',tgt2Color,...
    'stimPos',stimPos,'stimPCoords',stimPCoords,'sizeStim',sizeStim);

% get the only valid movement direction & update to only the valid arrows
dxy = agents.snake(:,1)-agents.snake(:,2);
visibleStim=true(nSymbs,1);
if ( dxy(1)>0  )     visibleStim(3)=false; % left
elseif ( dxy(1)<0 )  visibleStim(1)=false; % right
end;
if ( dxy(2)>0  )     visibleStim(4)=false; % up
elseif ( dxy(2)<0 )  visibleStim(2)=false; % down
end;
stimState.visibleStim=visibleStim;
[ev,stimState]=drawStim(0,stimState,[0;0],1);

% init state
status=buffer('wait_dat',[-1 -1 -1]); % current sample info
nevents=status.nevents; nsamples=status.nsamples;

% zoom display...
if ( zoomed ) 
  tgtxlim = pacx+zoomedLim;     tgtylim=pacy+zoomedLim;
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
  
lives=1; % Lives
nMoves=0; nframe=0;
curdir=1; dv=zeros(nSymbs,1); ndv=0;
gameState=struct('dead',false,'score',0,'grow',0,'pelletMoves',0);
startTime=getwTime(); 
ftime=startTime;
stimState.startTime=startTime; stimState.curStim=1; pred=[]; 
frametime=[]; drawTime=ftime; moveTime=ftime; speedupTime=ftime;
sendEvent('stimulus.test','start'); % mark start play
while ( lives && nMoves<max_moves )
  while( ~gameState.dead && nMoves<max_moves )
    nframe=nframe+1;
    ftime=getwTime();
    frametime(nframe,1)=ftime;

    if ( ftime-speedupTime > speedupInterval )
      speedupTime  = ftime;
      moveInterval = max(moveInterval-isi,ceil(minMoveInterval/isi)*isi);
    end
    
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
        [dv,predevIdx]=procPredEvents(events,{{'stimulus.prediction'}},dv,predAlpha,verb+1);
        nevents = status.nevents;
      end
      % convert to valid direction
      curdir=0;
      if ( all(visibleStim) )
        [ans,curdir]=max(dv); % get max prob symb            
      else
        vsi = find(visibleStim);
        [ans,curdir]=max(dv(vsi)); % get max prob symb
        curdir = vsi(curdir); % best from the visible set
      end
      if ( keyboardControl )
        k=get(gcf,'currentcharacter');
        if ( ~isequal(k,' ') && ~isempty(k) ) k=get(gcf,'currentkey'); end;
        switch (k)
         case {'d','rightarrow'}; curdir=1;
         case {'w','uparrow'};    curdir=2;
         case {'a','leftarrow'};  curdir=3;
         case {'s','downarrow'};  curdir=4;
         otherwise ;
        end
        set(gcf,'currentcharacter',' '); % mark as key processed
      end
      curdir=curdir+1;
      % reset classifier
      dv(:)=0; 
      
      dxy  = validateSnakeMove(map,agents,key,dxy,moves.dxy(:,curdir));

      if ( sum(agents.map(:)==key.pellet | agents.map(:)==key.powerpellet)<2 && nMoves-gameState.pelletMoves > pelletInterval )        
        x=randi(size(map,1)-2)+1; y=randi(size(map,2)-2)+1;
        if ( agents.map(x,y)==key.empty )
          if ( rand(1)>.9 ) 
            agents.map(x,y)  =key.pellet;
          else
            agents.map(x,y)  =key.powerpellet;
          end
          agentsh(x,y) =mkSnakeSprite(arenaax,x,y,agents.map(x,y),key);
          gameState.pelletMoves=nMoves;
        end
      end
      
      [map,maph,agents,agentsh,dxy,gameState]=...
          moveSnake(arenaax,map,maph,agents,agentsh,key,dxy,gameState,zoomed);
      % update the set of arrows we make visible
      visibleStim(:)=true;
      if ( dxy(1)>0  )     visibleStim(3)=false; % left
      elseif ( dxy(1)<0 )  visibleStim(1)=false; % right
      end;
      if ( dxy(2)>0  )     visibleStim(4)=false; % up
      elseif ( dxy(2)<0 )  visibleStim(2)=false; % down
      end;
      stimState.visibleStim=visibleStim;
      
      % ensure the arrows are at the top of the drawing order
      ch=get(arenaax,'children');
      stimI=false(numel(ch),1); for si=1:numel(stimh); stimI(ch==stimh(si))=true; end;
      set(arenaax,'children',[stimh(:);ch(~stimI)]);
      
      drawDisplay(map,maph,agents,agentsh,gameState.score,scoreh,nMoves,moveh);       

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
      if (verb>0) sec=buffer('poll'); fprintf('%d) Event: %s\n',sec.nSamples,ev2str(ev)); end;
    end;

    % wait for prediction events
    status=buffer('wait_dat',[-1 -1 -1],buffhost,buffport); % get current state
    stime =getwTime();     frametime(nframe,5)=stime;
    if ( status.nevents > nevents ) % new events to process
      if ( nevents< status.nevents-50 ) nevents=status.nevents-50; end;
      events=buffer('get_evt',[nevents status.nevents-1],buffhost,buffport);
      [dv,predevIdx]=procPredEvents(events,{{'stimulus.prediction'}},dv,predAlpha,verb);
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
  tgtxlim =[.5 size(map,2)+.5];  tgtylim=[.5 size(map,1)+.5];
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
text(mean(get(arenaax,'xlim')),mean(get(arenaax,'ylim')),{'GAME' 'OVER'},'HorizontalAlignment','center','color',[1 0 0],'fontunits','normalized','FontSize',.15);
pause(5);

return;
% close all;clf;subplot(211); plot(diff(frametime,[],2)*1000);set(gca,'ylim',[0 300]);title('proc time');subplot(212);plot(diff(frametime,[],1)*1000);set(gca,'ylim',[0 300]); title('inter frame');legend('drawing','framewait','expose','waitdata','procevents');


