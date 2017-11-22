if ( ~exist('preConfigured','var') || ~isequal(preConfigured,true) )  configureGame; end
        
%% Game Parameters:
% Game canvas size:
gameCanvasYLims         = [0 800];
gameCanvasXLims         = [0 500];
useBuffer               = 1;

% make a simple odd-ball stimulus sequence, with targets mintti apart
[stimSeq,stimTime,eventSeq] = mkStimSeqP300(1,gameDuration*2,isi,mintti,oddballp);
stimColors = [p3tgtColor;stdColor;rtColor]; % [targetFlash, standardFlash, reactionTimeFlash]

                                % add in the rt events
rtTime=0; 
while rtTime < stimTime(end)
  rtTime = rtTime + rtInterval(1) + rand(1)*(rtInterval(2)-rtInterval(1));
  [ans,rtEi]=min(abs(stimTime-rtTime)); % find nearest stimulus epoch
  rtTime=stimTime(rtEi);
                                % set a block of 1s to rt stimulus color
  stimSeq(1,rtEi+(0:ceil(rtDuration/isi)))=3; % stim3 = rtColor
end

% stimSeq is now complete with P3 and Rt stim events

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

drawnow;

                                % Make cannon:
hCannon = Cannon(hAxes);
% make background for p3 stimuli
%hbackground = rectangle('position',[gameCanvasXLims(1),gameCanvasYLims(1),diff(gameCanvasXLims),10]);

%% Game Loop:
                         % Make text disp (mostly for testing and debugging):
hText = text(gameCanvasXLims(1),gameCanvasYLims(2),'BrainFly P3','HorizontalAlignment', 'left', 'VerticalAlignment','top','Color',txtColor);

                       % wait for user to be ready before starting everything
set(hText,'string', {'' 'Click mouse when ready to begin.'}, 'visible', 'on'); drawnow;
%waitforbuttonpress;
for i=3:-1:0;
   set(hText,'string',sprintf('Starting in: %ds',i),'visible','on');
   pause(1);
end
set(hText,'visible', 'off'); drawnow; 


                                % Set callbacks to manage the key presses:
set(hFig,'KeyPressFcn',@(hObj,evt) set(hObj,'userdata',evt)); %save the key; processKeys(hObj,evt,evt.Key));
%set(hFig,'KeyReleaseFcn',@(hObj,evt) set(hObj,'userdata','')); % clear on release
                                %  set(hFig,'KeyReleaseFcn',[]);

                                % Loop while figure is active:
t0=getwTime(); stimi=1; nframe=0; rtState=0;
ss=stimSeq(:,stimi); % starting stimulus state
sendEvent('stimilus.brainfly_p3','start');
while ( getwTime()-t0<gameDuration && ishandle(hFig))
  nframe       = nframe+1;
  frameTime    = getwTime()-t0;
  frameEndTime = frameTime+gameFrameDuration; % time this frame should end
  frameTimes(nframe)=frameTime;
  if( verb>0 ) fprintf('%d) t=%g',nframe,frameTime); end

       %----------------------------- do the P300 type flashing -------------
       % get the position in the stim-sequence for this time.
       % Note: stimulus rate may be slower than the display rate...
  % Note: stimTime(stimi) is time this stimulus **finish** being on screen
  newstimState=false;
  if( frameTime>stimTime(stimi) ) % end of this stimulus, move on to next one
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
  end  
  if( verb>0 ) fprintf(' e=%d (%g)\n',stimi,stimTime(stimi)); end;
  % flash cannon, N.B. cannon is always stim-seq #1
  if( ss(1)==0 ) 
     set(hCannon.hGraphic,'facecolor',bgColor);
  else
     set(hCannon.hGraphic,'facecolor',stimColors(ss(1),:));
  end
  drawnow;

                              % update the stimulus state
  if( newstimState && useBuffer && ss(1)>0 ) % send event describing the game stimulus state
	 sendEvent('stimulus.stimState',ss); % raw stimulus sate
	 sendEvent('stimulus.tgtFlash',ss(1)==1); % tgt-flash?
  end
  
  % ---------- reaction time task -----------------------
  curKeyLocal    = get(hFig,'userdata');
  curCharacter   = [];
  if ( ~isempty(curKeyLocal) )
     curCharacter=curKeyLocal.Character;
     %if(verb>0) 
       fprintf('%d) key="%s"\n',nframe,curCharacter);
     %end
     set(hFig,'userdata',[]);
  end
                                % process the reaction time task presses
  if( ss(1)==3 && rtState==0 )
    rtStart = frameTime;
    rtState = 1; % waiting for key-press state
    sendEvent('stimulus.rtTask',1);
    fprintf('%d) t=%g rt frame',nframe,frameTime);
  end
  if( rtState==1 && strcmpi(curCharacter,'a') ) 
    if( useBuffer ) sendEvent('response.rtTask',curCharacter); end;
    set(hText,'string',sprintf('You got it!\n%4.2fs',frameTime-rtStart),'color','g','visible','on');
    drawnow;
    rtState=2; % post button press state
  end
  if ( rtState==1 && frameTime > rtStart + rtMax ) % end-rt window no button
    set(hText,'string',sprintf('Tooo sloooow!\n%4.2fs',frameTime-rtStart),'color','r','visible','on');
    drawnow;
    rtState=2; % post-button press state
  end;
  if ( rtState>0 && frameTime > rtStart + 2*rtMax ) % remove feedback
    set(hText,'string','','visible','off');
    drawnow;
    rtState=0; % non-running state
  end
      
  ttg=frameEndTime-(getwTime()-t0);
  if (ttg>0)
    pause(ttg); 
  elseif ( verb > 0 ) 
    fprintf('%d) frame-lagged %gs\n',nframe,ttg);
  end
end
sendEvent('stimilus.brainfly_p3','end');
