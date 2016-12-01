configureSpeller;
% create the control window and execute the phase selection loop
if ~( exist('OCTAVE_VERSION','builtin') ) 
  contFig=controller(); info=guidata(contFig); 
else
  contFig=figure(1);
  set(contFig,'name','BCI Controller : close to quit','color',[0 0 0]);
  axes('position',[0 0 1 1],'visible','off','xlim',[0 1],'ylim',[0 1],'nextplot','add');
  set(contFig,'Units','pixel');wSize=get(contFig,'position');
  fontSize = .05*wSize(4);
  %        Instruct String          Phase-name
  menustr={'0) EEG'                 'eegviewer';
           '1) Practice'            'practice';
			  '2) Calibrate'           'calibrate'; 
			  '3) Train Classifier'    'trainersp';
			  '4) copyspelling1'       'copyspell1';
			  '5) copyspelling2'       'copyspell2';
			  '6) freespelling'        'freespell'
			  'q) quit'                'quit';
          };
  txth=text(.25,.5,menustr(:,1),'fontunits','pixel','fontsize',.05*wSize(4),...
				'HorizontalAlignment','left','color',[1 1 1]);
  ph=plot(1,0,'k'); % BODGE: point to move around to update the plot to force key processing
  % install listener for key-press mode change
  set(contFig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
  set(contFig,'userdata',[]);
  drawnow; % make sure the figure is visible
end
subject='test';

% execute the phase selection loop
sendEvent('experiment.matrixSpeller','start');
while (ishandle(contFig))
  set(contFig,'visible','on');
  if ( ~ishandle(contFig) ) break; end;

  phaseToRun=[];
  if ( ~exist('OCTAVE_VERSION','builtin') ) 
	 uiwait(contFig);
    if ( ~ishandle(contFig) ) break; end;
	 info=guidata(contFig); 
	 subject=info.subject;
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
		ri = strmatch(modekey(1),menustr(:,1)); % get the row in the instructions
		if ( ~isempty(ri) ) 
		  phaseToRun = menustr{ri,2};
		elseif ( any(strcmp(modekey(1),{'q','Q'})) )
		  break;
		end
	 end
    set(contFig,'userdata',[]);
  end

  if ( isempty(phaseToRun) ) pause(.3); continue; end;

  fprintf('Starting Phase: %s\n',phaseToRun);
  set(contFig,'visible','off');
  switch phaseToRun;
    
   %---------------------------------------------------------------------------
   case 'capfitting';
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until capFitting is done
    while (true) % N.B. use a loop as safer and matlab still responds on windows...
       [devents]=buffer_newevents(buffhost,buffport,[],phaseToRun,'end',1000); % wait until finished
       drawnow;
       if ( ~isempty(devents) ) break; end;
    end

   %---------------------------------------------------------------------------
   case 'eegviewer';
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until viewer is done
    while (true) % N.B. use a loop as safer and matlab still responds on windows...
       [devents]=buffer_newevents(buffhost,buffport,[],phaseToRun,'end',1000); % wait until finished
       drawnow;
       if ( ~isempty(devents) ) break; end;
    end
    
   %---------------------------------------------------------------------------
   case 'practice';
    sendEvent('subject',info.subject);
    sendEvent(phaseToRun,'start');
    onSeq=nSeq; nSeq=4; % override sequence number
    onRepetitions=nRepetitions; nRepetitions=3;
    try
      spCalibrateStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    end
    sendEvent(phaseToRun,'end');
    nSeq=onSeq;
    nRepetitions=onRepetitions;
    
   %---------------------------------------------------------------------------
   case {'calibrate','calibration'};
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun)
    sendEvent(phaseToRun,'start');
    try
      spCalibrateStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.training','end');    
    end
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'train','classifier'};
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until training is done
    while (true) % N.B. use a loop as safer and matlab still responds on windows...
       [devents]=buffer_newevents(buffhost,buffport,[],phaseToRun,'end',1000); % wait until finished
       drawnow;
       if ( ~isempty(devents) ) break; end;
    end
    
   %---------------------------------------------------------------------------
   case 'copyspell1';
    sendEvent('subject',info.subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','testing');
      spFeedbackStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.test','end');
    end
    sendEvent('stimulus.test','end');
    sendEvent(phaseToRun,'end');
    
   %---------------------------------------------------------------------------
   case 'copyspell2';
    sendEvent('subject',info.subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try;
      sendEvent('startPhase.cmd','testing');
      spFeedbackStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.test','end');
    end
    sendEvent('stimulus.test','end');
    sendEvent(phaseToRun,'end');
    
   %---------------------------------------------------------------------------
   case 'freespell';
    sendEvent('subject',info.subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','testing');
      spFeedbackStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.test','end');
    end
    sendEvent('stimulus.test','end');
    sendEvent(phaseToRun,'end');
    
   %---------------------------------------------------------------------------
   case 'contfeedback';
    sendEvent('subject',info.subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    %try
      sendEvent('startPhase.cmd','contfeedback');
      spContFeedbackStimulus;
    %catch
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.test','end');
    %end
    sendEvent('stimulus.test','end');
    sendEvent(phaseToRun,'end');
    
  end
  info.phasesCompleted={info.phasesCompleted{:} info.phaseToRun};
  if ( ~ishandle(contFig) ) 
    oinfo=info; % store old info
    contFig=controller(); % make new figure
    info=guidata(contFig); % get new info
                           % re-place old info
    info.phasesCompleted=oinfo.phasesCompleted;
    info.phaseToRun=oinfo.phaseToRun;
    info.subject=oinfo.subject; set(info.subjectName,'String',info.subject);
    guidata(contFig,info);
  end;
  %for i=1:numel(info.phasesCompleted); % set all run phases to have green text
  %    set(getfield(info,[info.phasesCompleted{i} 'But']),'ForegroundColor',[0 1 0]);
  %end
end
% shut down signal proc
sendEvent('startPhase.cmd','exit');
% thank subject
uiwait(msgbox({'Thankyou for participating in our experiment.'},'Thanks','modal'),10);
