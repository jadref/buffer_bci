function gameLoop()
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
configureGame;
 
%% Game Parameters:

% Game canvas size:
gameCanvasYLims         = [0 800];
gameCanvasXLims         = [0 500];
maxCannonShotsPerSecond = 5;               % RPS of cannon
timeBeforeNextAlien     = 2;               % seconds


%% Generate Figure:

% Make the game window:
monitorSize = get(groot,'MonitorPositions');
monitorSize = monitorSize(1,:);
hFig = figure('Name','Imagined Movement -- close window to stop.'...
    ,'color',[1 1 1]...
    ,'menubar','none'...
    ,'toolbar','none'...
    ,'doublebuffer','on'...
    ,'Position',[0.5*monitorSize(3)-0.5*gameCanvasXLims(2)...
    0.5*monitorSize(4)-0.5*gameCanvasYLims(2)...
    gameCanvasXLims(2) gameCanvasYLims(2)]);

% Make game axes:
hAxes = axes('position',[0 0 1 1]...
    ,'units','normalized'...
    ,'visible','on','box','on',...
    'xtick',[],'xticklabelmode','manual'...
    ,'ytick',[],'yticklabelmode','manual'...
    ,'color',[0 0 0],'nextplot','replacechildren'...,'DrawMode','fast'
    ,'xlim',gameCanvasXLims,'ylim',gameCanvasYLims,'Ydir','normal');

drawnow;

% Make cannon:
hCannon = Cannon(hAxes);


%% Game Loop:

% Set callbacks to manage the key presses:
set(hFig,'KeyPressFcn',@(~,evt) processKeys(evt.Key));
set(hFig,'KeyReleaseFcn',@(~,~) processKeys(''));
curKey = '';

% Initialize game loop variables:
balls        = CannonBall.empty;
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
hText = text(gameCanvasXLims(1),gameCanvasYLims(2)-5,genTextStr...
    ,'Color','w');

% Loop while figure is active:
while ishandle(hFig)
    newBall = [];
    
    if ( useKeyboard )
        % Get the current key once, to prevent it from being updated within a
        % game loop teration:
      curKeyLocal    = curKey;
      [cannonAction,cannonTrotFrac]=key2action(curKeyLocal);
    end
    if ( useBuffer )
      [dv,prob,buffstate,filtstate]=processNewPredictionEvents(buffhost,buffport,buffstate,predType,isi*1000/2,predFiltFn,filtstate,verb)      
      [cannonAction,cannonTrotFrac]=prediction2action(dv,prob);
    end
    
    %----------------------------------------------------------------------
    %----------------------------------------------------------------------
    
    
    % Operate the cannon:
    if ~isempty(cannonAction)&& ~isempty(cannonTrotFrac)
        % Move cannon.
        hCannon.move(cannonAction,cannonTrotFrac);
    elseif strcmp(cannonAction,'fire')
        
        % Shoot cannonball if enough time has elapsed.
        if isempty(lastShotTime)||toc(lastShotTime)...
                >=(1/maxCannonShotsPerSecond)
            newBall = CannonBall(hAxes,hCannon);
            score.shots = score.shots + 1;
            lastShotTime = tic;
        end
        
    end
    
    % Make a new alien if there are no aliens, or if it is time to spawn a
    % new one:
    if isempty(hAliens)...
            ||toc(hAliens(end).alienSpawnTime)>timeBeforeNextAlien;
        hAliens(length(hAliens)+1) = Alien(hAxes,hCannon);
    end
    
    % Update cannonballs:
    curBalls = [balls newBall];
    if ~isempty(curBalls)
        [balls, hits] = curBalls.updateBalls(hAliens);
        score.hits = score.hits + hits;
    end
    
    % Update aliens:
    if ~isempty(hAliens)
        [hAliens, newKills] = hAliens.updateAliens;
        
        % Die animation (currently doesn't pause the aliens' descent):
        if newKills~=0
            hAxes.Color = 'r';
            pause(0.05);
            hAxes.Color = 'k';
        end
        
        cannonKills = cannonKills + newKills;
    end
    
    % Set score disp and loop:
    set(hText,'String',genTextStr());
    % TODO: make this more accurate to take account of display lag
    pause(isi);
    
end

%==========================================================================
    function processKeys(key)
        curKey = key;
    end

%==========================================================================
function [cannonAction,cannonTrotFrac]=key2action(curKeyLocal)

    %----------------------------------------------------------------------
    %----------------------------------------------------------------------
    % This section needs to produce two variables: cannonTrotFrac and
    % cannonTrotFrac.
    
    cannonAction   = [];
    cannonTrotFrac = [];
    
    % Determine speed:
    switch curKeyLocal
        
        case {'z','slash'} % super fast!
            cannonTrotFrac = 1;
            
        case {'x','period'} % fast
            cannonTrotFrac = 0.8;
            
        case {'c','comma'} % meh
            cannonTrotFrac = 0.6;
            
        case {'v','m'} % slow
            cannonTrotFrac = 0.4;
            
        case {'b','n'} % slooow
            cannonTrotFrac = 0.2;
    end
    
    % Determine the correct action:
    switch curKeyLocal
        
        case {'z','x','c','v','b'}
            cannonAction = 'left';
            
        case {'n','m','comma','period','slash'}
            cannonAction = 'right';
            
        case 'space'
            cannonAction = 'fire';
    end


    function [cannonAction,cannonTrotFrac]=prediction2action(prob)
                 % assume class order: [left right fire] (if fire is present)      
      margin=.1;
      if( prob(1)>prob(2)+margin ) cannonAction='left'; end;
      if( prob(2)>prob(1)+margin ) cannonAction='right'; end;
      if( numel(prob)>2 && prob(3)>max(prob(1:2)) ) cannonAction='fire'; end;
      cannonTrotFrac=.4; % Meh speed
      



    
%==========================================================================
    function str = genTextStr()
        str = sprintf(['  Shots: %i  |  hits: %i  |  acc.:%.1f%%'...
            '  |  ballsOut: %i  |  Died  %i times.']...
            ,score.shots,score.hits,100*score.hits/score.shots...
            ,length(curBalls),cannonKills);
    end

end
