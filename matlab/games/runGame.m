configureGame;

% create the control window and execute the phase selection loop
%try
%  contFig=gameController(); info=guidata(contFig); 
%catch
  contFig=figure(1);
  set(contFig,'name','Game Controller : close to quit','color',[0 0 0]);
  axes('position',[0 0 1 1],'visible','off','xlim',[0 1],'ylim',[0 1],'nextplot','add');
  set(contFig,'Units','pixel');wSize=get(contFig,'position');
  fontSize = .05*wSize(4);
  %        Instruct String          Phase-name
  menustr={'0) EEG'                 'eegviewer';
			  'a) Artifacts'           'artifact';
           '1) Practice'            'practice';
			  '2) Calibrate'           'calibrate'; 
			  '3) Train Classifier'    'trainerp';
           '' ''
			  's) Snake'               'snake';
			  'p) Pacman'              'pacman'; 
			  'b) Sokoban'             'sokoban';
			  'l) Spelling Letters'    'spelling'; 
			  'q) quit'                'quit';
          };
  txth=text(.25,.5,menustr(:,1),'fontunits','pixel','fontsize',.05*wSize(4),...
				'HorizontalAlignment','left','color',[1 1 1]);
  ph=plot(1,0,'k'); % BODGE: point to move around to update the plot to force key processing
  % install listener for key-press mode change
  set(contFig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
  set(contFig,'userdata',[]);
  drawnow; % make sure the figure is visible
%end
subject='test';
level=1;
speed=6;
while (ishandle(contFig))


  set(contFig,'visible','on');
  if ( ~ishandle(contFig) ) break; end;

  phaseToRun=[];
  if ( ~exist('OCTAVE_VERSION','builtin') && ~isempty(get(contFig,'tag')) )  % using the gui-figure-window
	 uiwait(contFig);
    if ( ~ishandle(contFig) ) break; end;    
	 info=guidata(contFig); 
	 subject=info.subject;
	 level  =info.level;
	 speed  =info.speed;  
	 phaseToRun=lower(info.phaseToRun);
  else % give time to process the key presses
	 % BODGE: move point to force key-processing
	 fprintf('.');set(ph,'ydata',rand(1)*.01); drawnow;
	 if ( ~ishandle(contFig) ) break; end;
  end

  % process any key-presses
  modekey=get(contFig,'userdata'); 
  if ( ~isempty(modekey) ) 	 
	 fprintf('key=%s\n',modekey);
	 phaseToRun=[];
	 if ( ischar(modekey(1)) )
		ri = strncmpi(modekey(1),menustr(:,1),1); % get the row in the instructions
		if ( any(ri) ) 
		  phaseToRun = menustr{find(ri,1),2};
		elseif ( any(strcmp(modekey(1),{'q','Q'})) )
		  break;
		end
	 end
    set(contFig,'userdata',[]);
  end

  if ( isempty(phaseToRun) ) pause(.3); continue; end;
  moveInterval = ceil(speed/isi)*isi;
  moveInterval = min(maxMoveInterval,moveInterval);

  fprintf('Start phase : %s\n',phaseToRun);  
  set(contFig,'visible','off'); drawnow;
  switch phaseToRun;
    
    %---------------------------------------------------------------------------
   case 'capfitting';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until viewer is done
    while (true) % N.B. use a loop as safer and matlab still responds on windows...
       [devents]=buffer_newevents(buffhost,buffport,[],phaseToRun,'end',1000); % wait until finished
       drawnow;
       if ( ~isempty(devents) ) break; end;
    end
    
    %---------------------------------------------------------------------------
   case 'eegviewer';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until viewer is done
    while (true) % N.B. use a loop as safer and matlab still responds on windows...
       [devents]=buffer_newevents(buffhost,buffport,[],phaseToRun,'end',1000); % wait until finished
       drawnow;
       if ( ~isempty(devents) ) break; end;
    end

   %---------------------------------------------------------------------------
   case 'artifact';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun); % tell sig-proc what to do
														  % wait until capFitting is done
	 try;
		artifactCalibrationStimulus;
	catch
       fprintf('Error in : %s',phaseToRun);
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
	  	 msgbox({sprintf('Error in : %s',phaseToRun) 'OK to continue!'},'Error');
       sendEvent(phaseToRun,'end');    
    end
    
    %---------------------------------------------------------------------------
   case {'calibrate','practice'};
    sendEvent('subject',subject);
	  if ( ~isempty(strfind(phaseToRun,'calibrat')) ) % tell the sig-proc to go if real run
		 sendEvent('startPhase.cmd',phaseToRun)
	  end
    sendEvent(phaseToRun,'start');
    try
      gameCalibrateStimulus
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
      sendEvent('stimulus.training','end');    
    end
    sendEvent(phaseToRun,'end');

    %---------------------------------------------------------------------------
   case {'train','trainerp'};
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until training is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end',inf);
    %buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);  
    
    %---------------------------------------------------------------------------
   case 'snake';
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','testing');
      snake;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
      sendEvent('stimulus.test','end');
    end
    sendEvent(phaseToRun,'end');
    
    %---------------------------------------------------------------------------
   case 'sokoban';
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try;
      sendEvent('startPhase.cmd','testing');
      sokoban;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
      sendEvent('stimulus.test','end');
    end
    sendEvent(phaseToRun,'end');
    
    %---------------------------------------------------------------------------
   case 'pacman';
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','testing');
      pacman;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
      sendEvent('stimulus.test','end');
    end
    sendEvent(phaseToRun,'end');

    %---------------------------------------------------------------------------    
   case {'contfeedback','spelling'};
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent('spelling','start');
    try
      sendEvent('startPhase.cmd','contfeedback');
      spContFeedbackStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
      sendEvent('stimulus.test','end');
    end
    sendEvent('spelling','end');    

    %---------------------------------------------------------------------------
   case {'quit','exit'};
    break;

  end
end
uiwait(msgbox({'Thankyou for participating in our experiment.'},'Thanks','modal'),10);
pause(1);
% shut down signal proc
sendEvent('startPhase.cmd','exit');
