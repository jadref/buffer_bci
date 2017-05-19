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
  timeBeforeNextAlien     = 2;               % seconds


  %% Generate Figure:

                                % Make the game window:
  hFig = figure(2);
  set(hFig,'Name','Imagined Movement -- close window to stop.'...
      ,'color',winColor...
      ,'menubar','none'...
      ,'toolbar','none'...
      ,'doublebuffer','on'...
      ,'Position',[0.5*gameCanvasXLims(2) 0.5*gameCanvasYLims(2) gameCanvasXLims(2) gameCanvasYLims(2)]);

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
%  set(hFig,'KeyReleaseFcn',@(hObj,evt) set(hObj,'userdata','')); % clear on release
  set(hFig,'KeyReleaseFcn',[]);

                                % Initialize game loop variables:
  balls        = [];%CannonBall.empty;
  curBalls     = [];
  lastShotTime = [];
  score.shots  = 0;
  score.hits   = 0;
  cannonKills = 0;

                         % Initialize buffer-prediction processing variables:
  buffstate=[];
  predFiltFn=[]; % additional filter function for the classifier predictions? %-contFeedbackFiltLen; % average full-trials worth of predictions
  filtstate=[];
  predType =[];

                                % Make an alien:
  hAliens = Alien(hAxes,hCannon);

                         % Make text disp (mostly for testing and debugging):
  hText = text(gameCanvasXLims(1),gameCanvasYLims(2)-5,genTextStr(score,curBalls,cannonKills)...
               ,'Color',txtColor);

  
                                % Loop while figure is active:
  cannonAction=[];cannonTrotFrac=0;
  t0=tic;
  while ( toc(t0)<gameDuration && ishandle(hFig))
    newBall = [];
    
    if ( useKeyboard )
      curKeyLocal    = get(hFig,'userdata');
      if ( ~isempty(curKeyLocal) ) 
        fprintf('%g) key="%s"',toc(t0),curKeyLocal.Character);
        [cannonAction,cannonTrotFrac]=key2action(curKeyLocal.Character);
      end
    end
    if ( useBuffer )
      [dv,prob,buffstate,filtstate]=processNewPredictionEvents(buffhost,buffport,buffstate,predType,isi*1000/2,predFiltFn,filtstate,verb);
      if( ~isempty(dv) ) % only if events to process...
        [cannonAction,cannonTrotFrac]=prediction2action(dv,prob);
      end
    end
    
      %----------------------------------------------------------------------
      %----------------------------------------------------------------------
    
    
                                % Operate the cannon:
    if ~isempty(cannonAction)&& ~isempty(cannonTrotFrac)
                                % Move cannon.
      fprintf('%g) move %s %g\n',toc(t0),cannonAction,cannonTrotFrac);
      hCannon.move(cannonAction,cannonTrotFrac);
    elseif strcmp(cannonAction,'fire')
      
                               % Shoot cannonball if enough time has elapsed.
      if isempty(lastShotTime)||toc(lastShotTime)>=(1/maxCannonShotsPerSecond)
        newBall = CannonBall(hAxes,hCannon);
        score.shots = score.shots + 1;
        lastShotTime = tic;
      end
      
    end
    
       % Make a new alien if there are no aliens, or if it is time to spawn a
       % new one:
    if isempty(hAliens) || toc(hAliens(end).alienSpawnTime)>timeBeforeNextAlien;
      hAliens(length(hAliens)+1) = Alien(hAxes,hCannon);
    end
    
                                % Update cannonballs:
    if( isempty(balls) ) curBalls=newBall; elseif( isempty(newBall) ) curBalls=balls; else curBalls = [balls newBall]; end;
    if ~isempty(curBalls)
      [balls, hits] = CannonBall.updateBalls(curBalls,hAliens);
      score.hits = score.hits + hits;
    end
    
                                % Update aliens:
    if ~isempty(hAliens)
      [hAliens, newKills] = Alien.updateAliens(hAliens);
      
               % Die animation (currently doesn't pause the aliens' descent):
      if newKills~=0
        hAxes.Color = 'r';
        pause(0.05);
        hAxes.Color = 'k';
      end
      
      cannonKills = cannonKills + newKills;
    end
    
                                % Set score disp and loop:
    set(hText,'String',genTextStr(score,curBalls,cannonKills));
               % TODO: make this more accurate to take account of display lag
    pause(isi);
    
  end



## %==========================================================================
## function processKeys(hObj,evt,key)
##   set(hObj,'userdata',key);  
## end



