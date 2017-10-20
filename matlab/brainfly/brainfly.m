% The main game loop
%
% Control the cannon with the bottom row of keys on the keyboard, and
% space:
%
% Go left, in order of descreasing speed:   'z'  'x'  'c'  'v'  'b'%
%
% Go right, in order of increasing speed:   'n'  'm'  ','  '.'  '/'
%
% Fire: 'Space'
%
%

%% Prepare Workspace:

                                %close all; clc; clear
if ( ~exist('preConfigured','var') || ~isequal(preConfigured,true) )  configureGame; end
        
%% Game Parameters:
% Game canvas size:
gameCanvasYLims         = [0 800];
gameCanvasXLims         = [0 500];
maxCannonShotsPerSecond = 5;               % RPS of cannon
autoFireMode            = 1;               % auto-fire or fire key?
timeBeforeNextAlien     = 3;               % seconds
killFlashTime           = .1;              % duration of the red-you've-been-killed flash
bonusSpawnInterval      = [5 20];          % range in time between bonus alien spawns

predictionMargin=0;
warpCursor = true; % cannon position is directly classifier output


% make a simple odd-ball stimulus sequence, with targets mintti apart
[stimSeq,stimTime,eventSeq] = mkStimSeqP300(3,gameDuration,isi,mintti,oddballp);
stimColors = [bgColor;flashColor]; % map from stim-seq (0,1) to color to use [bg,flash] [nstimState x 3]
% game object UID used for each stimulus sequence, i.e. obj2stim(3)=apply stim seq 3 to game object with UID (stim2obj(3)): [nStim x 1]
stim2obj   = zeros(size(stimSeq,1),1);
stim2obj(1)= 1; % 1st stim seq always mapps to the cannon

                                % make a sequence of alien spawn locations
% make the target sequence
tgtSeq=mkStimSeqRand(2,gameDuration*2./timeBeforeNextAlien);
lrSeq =(tgtSeq(1,:)*.8+.1)+(rand(1,size(tgtSeq,2))-.5)*.4; % l/r with a little noise

%% Generate Figure:
                                % Make the game window:
hFig = figure(2);
set(hFig,'Name','Imagined Movement -- close window to stop.'...
    ,'color',winColor...
    ,'menubar','none'...
    ,'toolbar','none'...
    ,'doublebuffer','on');%...
%,'Position',[gameCanvasXLims(2) 100 gameCanvasXLims(2) gameCanvasYLims(2)]);

                                % Make game axes:
hAxes = axes('position',[0 0 1 1]...
             ,'units','normalized'...
             ,'visible','on','box','on'...
             ,'xtick',[],'xticklabelmode','manual'...
             ,'ytick',[],'yticklabelmode','manual'...
             ,'color',winColor,'nextplot','replacechildren','DrawMode','fast'...
             ,'xlim',gameCanvasXLims,'ylim',gameCanvasYLims,'Ydir','normal');

drawnow;

                                % Make cannon:
hCannon = Cannon(hAxes);


%% Game Loop:

                                % Set callbacks to manage the key presses:
set(hFig,'KeyPressFcn',@(hObj,evt) set(hObj,'userdata',evt)); %save the key; processKeys(hObj,evt,evt.Key));
set(hFig,'KeyReleaseFcn',@(hObj,evt) set(hObj,'userdata','')); % clear on release
                                %  set(hFig,'KeyReleaseFcn',[]);

                                % Initialize game loop variables:
balls        = [];%CannonBall.empty;
newBall      = [];
curBalls     = [];
lastShotTime = [];
score.shots  = 0;
score.hits   = 0;
score.bonushits=0;
                   % simple scoreing function, top-screen=10, bottom-screen=1
height2score = @(height) 10*(height-gameCanvasYLims(1))./(gameCanvasYLims(2)-gameCanvasYLims(1)) + 1
cannonKills = 0;

                         % Initialize buffer-prediction processing variables:
buffstate=[];
predFiltFn=[]; % additional filter function for the classifier predictions? %-contFeedbackFiltLen; % average full-trials worth of predictions
filtstate=[];
predType =[];

                                % Make an alien:
hAliens = Alien(hAxes,hCannon);
Alien.spawnSeq=lrSeq;
                                % list of bonus aliens
hbonusAliens=[];

                         % Make text disp (mostly for testing and debugging):
hText = text(gameCanvasXLims(1),gameCanvasYLims(2),genTextStr(score,curBalls,cannonKills),...
             'HorizontalAlignment', 'left', 'VerticalAlignment','top','Color',txtColor);


                       % wait for user to be ready before starting everything
set(hText,'string', {'' 'Click mouse when ready to begin.'}, 'visible', 'on'); drawnow;
waitforbuttonpress;
set(hText,'visible', 'off'); drawnow; 
sleepSec(5);

                                % Loop while figure is active:
killStartTime=0;
bonusSpawnTime=bonusSpawnInterval(1)+rand(1)*diff(bonusSpawnInterval); % time-at which next bonus show occur
cannonAction=[];cannonTrotFrac=0;
t0=tic; stimi=1; nframe=0;
while ( toc(t0)<gameDuration && ishandle(hFig))
  nframe       = nframe+1;
  frameTime    = toc(t0);
  frameEndTime = frameTime+gameFrameDuration; % time this frame should end
  frameTimes(nframe)=frameTime;

                 % get the position in the stim-sequence for this time.
                 % Note: stimulus rate may be slower than the display rate...
% Note: stimTime(stimi) is the time this stimulus should **first** be on the screen
  if( frameTime > stimTime(stimi) ) % next stimulus state
    stimi=stimi+1; % next stimulus frame
    if( stimi>=numel(stimTime) ) % wrap-arround the end of the stimulus sequence
      stimi=1;
    else
                                % find next valid frame
      tmp = stimi;for stimi=tmp:numel(stimTime); if ( frameTime<stimTime(stimi) ) break; end; end; 
      if ( verb>=0 && stimi-tmp>5 ) % check for frame dropping
        fprintf('%d) Dropped %d Frame(s)!!!\n',nframe,stimi-tmp);
      end;        
    end
    ss=stimSeq(:,stimi); % get the current stimulus state info
    nstim2obj=zeros(size(stim2obj)); % updated mapping between game-objects and stimulus sequences    
    fprintf('%d) %g %d=>[%s]\n',nframe,frameTime,stimi,sprintf('%d=%d ',[stim2obj(stim2obj>0) ss(stim2obj>0)]'));

    % -- get the current user/BCI input
    curCharacter=[];
    if ( useKeyboard )
      curKeyLocal    = get(hFig,'userdata');
      if ( ~isempty(curKeyLocal) )
        curCharacter=curKeyLocal.Character;
        fprintf('%d) key="%s"\n',nframe,curCharacter);
        [cannonAction,cannonTrotFrac]=key2action(curCharacter);
      end
    end
    if ( useBuffer )
      [dv,prob,buffstate,filtstate]=processNewPredictionEvents(buffhost,buffport,buffstate,predType,gameFrameDuration*1000/2,predFiltFn,filtstate,verb-1);
      curKeyLocal = get(hFig,'userdata');
      prob = [prob;0];
      
      %checks if shooting key is pressed
      if ~isempty(curKeyLocal)
          curCharacter = curKeyLocal.Character;
          if curCharacter == 'k'
            prob(3) = 100;
          end
      end
      if( ~isempty(dv) ) % only if events to process...
        [cannonAction,cannonTrotFrac]=prediction2action(prob,predictionMargin);
      end
    end
    if( ~isempty(dv) ) % only if events to process...
      [cannonAction,cannonTrotFrac]=prediction2action(prob,predictionMargin,warpCursor);
    end
  end
  
      %----------------------------------------------------------------------
      % Operate the cannon:
  if( ~isempty(cannonAction) ) % updat the cannon
    fprintf('%d) move %s %g\n',nframe,cannonAction,cannonTrotFrac);
    hCannon.move(cannonAction,cannonTrotFrac);      
  end
  
  % flash cannon, N.B. cannon is always stim-seq #1
  nstim2obj(1)=hCannon.uid; % mark this stim-seq as used
  set(hCannon.hGraphic,'facecolor',stimColors(ss(1)+1,:)); % set the cannon color based on stim-state.
  if ( strcmp(cannonAction,'fire') ||  autoFireMode>0 ) % Shoot cannonball if enough time has elapsed.
    if isempty(lastShotTime)||toc(lastShotTime)>=(1/maxCannonShotsPerSecond)
      newBall = CannonBall(hAxes,hCannon);
      score.shots = score.shots + 1;
      lastShotTime = tic;
    end
    
  end
  
  %----------------------------------------------------------------------
  % Make a new alien if there are no aliens, or if it is time to spawn a
  % new one:
  if isempty(hAliens) || toc(hAliens(end).alienSpawnTime)>timeBeforeNextAlien;
    hAliens(length(hAliens)+1) = Alien(hAxes,hCannon);
  end

  %----------------------------------------------------------------------
  % make new bonus alien if it's time.
  if( isempty(hbonusAliens) && frameTime > bonusSpawnTime )
    hbonusAliens=BonusAlien(hAxes,hCannon);
    if( useBuffer ) sendEvent('stimulus.bonusAlien',hbonusAliens.uid); end;
    bonusSpawnTime = frameTime + bonusSpawnInterval(1)+rand(1)*diff(bonusSpawnInterval); % time-at which next bonus show occur
  end

  
%----------------------------------------------------------------------        
% Update cannonballs:
  if( isempty(balls) ) 
    curBalls=newBall; 
  elseif( isempty(newBall) ) 
    curBalls=balls; 
  else 
    curBalls=balls; curBalls(end+1)=newBall; 
  end;
  if ~isempty(curBalls)
    [balls, hits] = CannonBall.updateBalls(curBalls,hAliens);
    if( useBuffer && ~isempty(hits) ) sendEvent('stimulus.hit',numel(hits)); end;
        % update the score, with higher score for aliens higher up the screen
    for ai=1:numel(hits)
      score.hits = score.hits + height2score(hits(ai));
    end
  end
  
%----------------------------------------------------------------------        
% Update aliens:
  if ~isempty(hAliens)
    [hAliens, newKills] = Alien.updateAliens(hAliens);

                                % add the p3 code to the aliens
                                % find the stim-seq to use for each alien
    alien2stim=zeros(numel(hAliens));
    for i=1:numel(hAliens);
      auid=hAliens(i).uid;
      mi  =find(stim2obj==auid);
      if( isempty(mi) ) mi=find(stim2obj==0,1); end % pick an empty stim
                                   % update the tracking info
      nstim2obj(mi) =auid; % new list of used stimulus
      alien2stim(i) =mi;
                                % apply the stimulus
      set(hAliens(i).hGraphic,'facecolor',stimColors(ss(mi)+1,:));
    end
    
%----------------------------------------------------------------------        
% Update bonus aliens
    if ( ~isempty(hbonusAliens) )
      hbonusAliens = BonusAlien.update(hbonusAliens);
      if( any(strcmpi(curCharacter,{'a'})) ) % got the bonus alien
        fprintf('%d) Got the bonus alien!\n',nframe) 
        for hi=1:numel(hbonusAliens);
          score.bonushits=score.bonushits+1;
          hbonusAliens(hi).deleteAlien();
        end;
      end
    end

            % ---------------------------------------------------------------
            % update Cannon
            % Die animation (currently doesn't pause the aliens' descent):
    if newKills~=0
      set(hAxes,'Color','r');
      killStartTime=frameTime;
    end
    if ( killStartTime>0 && frameTime>killStartTime+killFlashTime ) % end kill-flash
      set(hAxes,'Color','k');
      killStartTime=0;
    end
    
    cannonKills = cannonKills + newKills;
  end
  
                                % Set score disp and loop:
  fprintf('%s\n',genTextStr(score,curBalls,cannonKills));							
  set(hText,'String',genTextStr(score,curBalls,cannonKills),'visible','on');
       % TODO: make this more accurate to take account of display/network lag
  drawnow;
                                % update the stimulus state
  stim2obj=nstim2obj;
  if( useBuffer ) % send event describing the game stimulus state
    usedStim=nstim2obj>0;
    objstim=[stim2obj(usedStim) ss(usedStim)]'; % mapping from objid to current stim-state [2 x nstimObj]
    sendEvent('stimulus.stimState',objstim(:)); % event sequence of (uid,stimstate) pairs

                       % send event saying what task the user should be doing
    % get the lowest alien, this is the target alien
    tgtAlien=hAliens(1);
    for i=2:numel(hAliens);
      if( hAliens(i).y < tgtAlien.y )
        tgtAlien=hAliens(i);
      end
    end
    % alien position tells us the target task
    if tgtAlien.x > .5
      sendEvent('stimulus.target',symbCue{1});
    else
      sendEvent('stimulus.target',symbCue{2});
    end
  end

  ttg=frameEndTime-toc(t0);
  if (ttg>0) pause(ttg); 
  else 
    fprintf('%d) frame-lagged %gs\n',nframe,ttg);
  end;
  
end



