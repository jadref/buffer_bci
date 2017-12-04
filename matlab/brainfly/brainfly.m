if ( ~exist('preConfigured','var') || ~isequal(preConfigured,true) )  configureGame; end
        
%% Game Parameters:
% Game canvas size:
gameCanvasYLims         = [0 800];
gameCanvasXLims         = [0 500];
maxCannonShotsPerSecond = 1;               % RPS of cannon
autoFireMode            = 1;               % auto-fire or fire key?
useBuffer               = 1;
timeBeforeNextAlien     = 5;               % seconds
killFlashTime           = 0;              % duration of the red-you've-been-killed flash
predictionMargin=0;
warpCursor = true; % cannon position is directly classifier output
p300Flashing = false; % whether we do the p300 flashing or not

                                % make a sequence of alien spawn locations
% make the target sequence
tgtSeq=mkStimSeqRand(2,gameDuration*2./timeBeforeNextAlien);
lrSeq =tgtSeq(1,:)+(rand(1,size(tgtSeq,2))-.5)*.0; % l/r with a little noise
lrSeq =max(0,min(1,lrSeq)); % bounds check

%% Generate Figure:
                                % Make the game window:
hFig = figure(2);
set(hFig,'Name','Brainfly!'...
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

                                % Make cannon:
hCannon = Cannon(hAxes);
% make background for p3 stimuli
%hbackground = rectangle('position',[gameCanvasXLims(1),gameCanvasYLims(1),diff(gameCanvasXLims),10]);


        % make a simple odd-ball stimulus sequence, with targets mintti apart
[stimSeq,stimTime,eventSeq] = mkStimSeqP300(1,gameDuration*2,isi,mintti,oddballp);
stimColors = [p3tgtColor;stdColor;rtColor]; % [targetFlash, standardFlash, reactionTimeFlash]

                                % add in the rt events
rtTimes=[];rtTime=0; 
while rtTime < stimTime(end)
  rtTime = rtTime + rtInterval(1) + rand(1)*(rtInterval(2)-rtInterval(1));
  [ans,rtEi]=min(abs(stimTime-rtTime)); % find nearest stimulus epoch
  rtTime=stimTime(rtEi);
  rtTimes=[rtTimes; rtTime]; % record all planned rt-task times
                                % set a block of 1s to rt stimulus color
  stimSeq(1,rtEi+(0:ceil(rtDuration/isi)))=3; % stim3 = rtColor
end
% stimSeq is now complete with P3 and Rt stim events

                                % make a sequence of alien spawn locations
% make the target sequence
tgtSeq=mkStimSeqRand(2,gameDuration*2./timeBeforeNextAlien);
lrSeq =(tgtSeq(1,:)*.9+.05)+(rand(1,size(tgtSeq,2))-.5)*0; % l/r with a little noise

%% Game Loop:
                                % Set callbacks to manage the key presses:
set(hFig,'KeyPressFcn',@(hObj,evt) set(hObj,'userdata',evt)); %save the key; processKeys(hObj,evt,evt.Key));
                                %  set(hFig,'KeyReleaseFcn',[]);

                                % Initialize game loop variables:
balls        = [];%CannonBall.empty;
newBall      = [];
curBalls     = [];
lastShotTime = [];
score        = struct('shots',0,'hits',0,'bonushits',0,'totalBonusPoss',0,'score',0);

                   % simple scoreing function, top-screen=10, bottom-screen=1
height2score = @(height) round(10*(height-gameCanvasYLims(1))./(gameCanvasYLims(2)-gameCanvasYLims(1)) + 1);
cannonKills = 0;

                         % Initialize buffer-prediction processing variables:
buffstate=[];
predFiltFn='gainFilt'; % additional filter function for the classifier predictions? %-contFeedbackFiltLen; % average full-trials worth of predictions
filtstate=[];
predType =[];

                         % Make text disp (mostly for testing and debugging):
hText = text(gameCanvasXLims(1),gameCanvasYLims(2),genTextStr(score,curBalls,cannonKills),...
             'HorizontalAlignment', 'left', 'VerticalAlignment','top','Color',txtColor);


                       % wait for user to be ready before starting everything
set(hText,'string', {'' 'Click mouse when ready to begin.'}, 'visible', 'on'); drawnow; pause(1);
waitforbuttonpress;
for i=3:-1:0;
   set(hText,'string',sprintf('Starting in: %ds',i),'visible','on');drawnow;
   sleepSec(1);
end
set(hText,'visible', 'off'); drawnow; 

                                % Loop while figure is active:
                                % Make the first Alien
Alien.getsetSpawnSeq(lrSeq);
hAliens = [];
killStartTime=0;
cannonAction=[];cannonTrotFrac=0;
t0=tic; stimi=1; nframe=0;  rtState=0; rtId=1;
ss=stimSeq(:,stimi); % starting stimulus state
while ( toc(t0)<gameDuration && ishandle(hFig))
  nframe       = nframe+1;
  frameTime    = toc(t0);
  frameEndTime = frameTime+gameFrameDuration; % time this frame should end
  frameTimes(nframe)=frameTime;

         %-------------------------------------------------------------------
         % -- get the current user/BCI input
  if ( useBuffer )
    [dv,prob,buffstate,filtstate]=processNewPredictionEvents(buffhost,buffport,buffstate,predType,gameFrameDuration*1000/2,predFiltFn,filtstate,verb-1);
    if( ~isempty(dv) ) fprintf('%d) Pred: dv=[%s]\n',nframe,sprintf('%g,',dv)); end;
    
    if( ~isempty(dv) ) % only if events to process...
      [cannonAction,cannonTrotFrac]=prediction2action(prob,predictionMargin,warpCursor);
    end
  end
  
      %----------------------------------------------------------------------
      % Operate the cannon:
  if( ~isempty(cannonAction) ) % updat the cannon
    if(ischar(cannonAction) )
      fprintf('%d) move %s %g\n',nframe,cannonAction,cannonTrotFrac);
    else
      fprintf('%d) warp %g\n',nframe,cannonAction);
    end
    hCannon.move(cannonAction,cannonTrotFrac);      
  end

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
  if isempty(hAliens)
    hAliens = Alien(hAxes,hCannon);
  elseif toc(hAliens(end).alienSpawnTime)>timeBeforeNextAlien;
    hAliens(length(hAliens)+1) = Alien(hAxes,hCannon);
  end


         %-------------------------------------------------------------------
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
	  score.score = score.score + height2score(hits(ai));
      score.hits = score.hits + 1;
    end
  end

            %----------------------------------------------------------------
            % Update aliens:
  if ~isempty(hAliens)
    [hAliens, newKills] = Alien.updateAliens(hAliens);
  end

            % ---------------------------------------------------------------
            % update Cannon
            % Die animation (currently doesn't pause the aliens' descent):
  if killFlashTime>0 && newKills~=0
    set(hAxes,'Color','r');
    killStartTime=frameTime;
  end
  if ( killStartTime>0 && killFlashTime>0 && frameTime>killStartTime+killFlashTime ) % end kill-flash
    set(hAxes,'Color','k');
    killStartTime=0;
  end
  cannonKills = cannonKills + newKills;


       %----------------------------- do the P300 type flashing -------------
       % get the position in the stim-sequence for this time.
       % Note: stimulus rate may be slower than the display rate...
  % Note: stimTime(stimi) is time this stimulus **finish** being on screen
  newstimState=false;
  if( p300Flashing && stimTime(stimi)<frameTime ) % end of this stimulus, move on to next one
    stimi=stimi+1; % next stimulus frame
    if( stimi>=numel(stimTime) ) % wrap-arround the end of the stimulus sequence
      stimi=1;
      fprintf('Warning!!!! ran out of stimuli!!!!!');
    else  % find next valid frame, i.e. first event for which stimTime > current time = frameTime
      tmp=stimi;for stimi=tmp:numel(stimTime); if(stimTime(stimi)>frameTime)break;end; end; 
      if ( verb>=0 && stimi-tmp>5 ) % check for frame dropping
        fprintf('%d) Dropped %d Frame(s)!!!\n',nframe,stimi-tmp);
      end;        
    end
    ss=stimSeq(:,stimi); % get the current stimulus state info
	% TODO: only send event when state *really* changes?
	newstimState=true;

                 %fprintf('%d) %g %d=>[%s]\n',nframe,frameTime,stimi,...
                 % sprintf('%d=%d ',[stim2obj(stim2obj>0) ss(stim2obj>0)]'));

                            % flash cannon, N.B. cannon is always stim-seq #1
    set(hCannon.hGraphic,'facecolor',stimColors(ss(1)+1,:));
                                % flash the background
    %set(hbackground,'facecolor',stimColors(ss(2)+1,:));
    %%                             % flash the aliens
    %% alien2stim=zeros(numel(hAliens));
    %% for i=1:numel(hAliens);
    %%   auid=hAliens(i).uid;
    %%   mi  =find(stim2obj==auid);
    %%   if( isempty(mi) ) mi=find(stim2obj==0,1); end % pick an empty stim
    %%                                % update the tracking info
    %%   nstim2obj(mi,1) =auid; % new list of used stimulus, ensure col-vector
    %%   alien2stim(i) =mi;
    %%                             % apply the stimulus
    %%   set(hAliens(i).hGraphic,'facecolor',stimColors(ss(mi)+1,:));
    %% end
  end
    

    % ---------- reaction time task -----------------------
                                % process the reaction time task presses
  if( rtState==0 && rtId<numel(rtTimes) && frameTime > rtTimes(rtId) )
    rtStart = frameTime;
    rtState = 1; % waiting for key-press state
    set(hCannon.hGraphic,'facecolor',stimColors(3,:)); % set as rt color
    score.totalBonusPoss = score.totalBonusPoss+1;
    %drawnow;
    sendEvent('stimulus.rtTask',1);
    fprintf('%d) t=%g rt frame',nframe,frameTime);
  end
  curKeyLocal    = get(hFig,'userdata');
  curCharacter   = [];
  if ( ~isempty(curKeyLocal) )
     curCharacter=curKeyLocal.Character;
     %if(verb>0) 
       fprintf('%d) key="%s"\n',nframe,curCharacter);
     %end
     [cannonAction,cannonTrotFrac]=key2action(curCharacter);
     set(hFig,'userdata',[]);
  end
  if( rtState==1 && strcmpi(curCharacter,'a') ) % fast enough for RT task
    if( useBuffer ) sendEvent('response.rtTask',curCharacter); end;
    %set(hText,'string',sprintf('You got it!\n%4.2fs',frameTime-rtStart),'color','g','visible','on'); drawnow;
    set(hCannon.hGraphic,'facecolor',tgtColor); % set as rt color
    score.bonushits=score.bonushits+1;
    rtState=2; % post button press state
  end
  if ( rtState==1 && frameTime > rtStart + rtMax ) % end-rt window no button
    %set(hText,'string',sprintf('Tooo sloooow!\n%4.2fs',frameTime-rtStart),'color','r','visible','on'); drawnow;
    rtState=2; % post-button press state
  end;
  if ( rtState>0 && frameTime > rtStart + 2*rtMax ) % remove feedback
    %set(hText,'string','','visible','off'); drawnow;
    set(hCannon.hGraphic,'facecolor',bgColor); % set as rt color
    rtState=0; % back to non-running state
    rtId   = rtId+1; % set to next rt start time..
  end

                     % Set score disp and loop
                     %fprintf('%s\n',genTextStr(score,curBalls,cannonKills));
  set(hText,'String',genTextStr(score,curBalls,cannonKills),'visible','on');
       % TODO: make this more accurate to take account of display/network lag
  drawnow;
                              % update the stimulus state
  if( useBuffer ) % send event describing the game stimulus state
	if ( p300Flashing && newstimState ) % only send events when the cannon changes color...
		sendEvent('stimulus.stimState',ss); % p3 stim state
		sendEvent('stimulus.tgtFlash',ss(1)); % tgt-flash?
	end
                       % send event saying what task the user should be doing
                       % get the lowest alien, this is the target alien
    if ( ~isempty(hAliens) )
      if( ~exist('tgtAlien','var') ) tgtAlien=[]; end;
      otgtAlien=tgtAlien;
      tgtAlien=hAliens(1);
      for i=2:numel(hAliens);
        if( hAliens(i).y < tgtAlien.y )
          tgtAlien=hAliens(i);
        end
      end                               
      if( ~isequal(tgtAlien,otgtAlien) ) % new target
                                % alien position tells us the target task
        if tgtAlien.x > mean(get(hAxes,'xlim'));     tgtDir=['1 ' symbCue{1}];
        else                                         tgtDir=['2 ' symbCue{2}];
        end
        fprintf('%d) new tgt: %s\n',nframe,tgtDir); 
        sendEvent('stimulus.target',tgtDir);
      end
    end
  end
    
  ttg=frameEndTime-toc(t0);
  if (ttg>0)
    pause(ttg); 
  elseif ( verb > 0 ) 
    fprintf('%d) frame-lagged %gs\n',nframe,ttg);
  end
end
