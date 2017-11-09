configureSpeller;
% create the control window and execute the phase selection loop

contFig=figure(1);
set(contFig,'name','BCI Controller : close to quit','color',[0 0 0]);
axes('position',[0 0 1 1],'visible','off','xlim',[0 1],'ylim',[0 1],'nextplot','add');
set(contFig,'Units','pixel');wSize=get(contFig,'position');
fontSize = .05*wSize(4);
%        Instruct String          Phase-name
menustr={'0) EEG'                 'eegviewer';
         '1) Practice'            'practice';
         '2) Calibrate'           'calibrate'; 
         '3) Train Classifier'    'trainerp';
         '4) Feedback'            'eventseqfeedback';
         '5) Feedback (continuous)' 'eventfeedback';
         '' '';
         'q) quit'                'quit';
        };
txth=text(.25,.5,menustr(:,1),'fontunits','pixel','fontsize',.05*wSize(4),...
          'HorizontalAlignment','left','color',[1 1 1]);
ph=plot(1,0,'k'); % BODGE: point to move around to update the plot to force key processing
                  % install listener for key-press mode change
set(contFig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
set(contFig,'userdata',[]);
drawnow; % make sure the figure is visible
subject='test';

% execute the phase selection loop
sendEvent('experiment.matrixSpeller','start');
while (ishandle(contFig))
  set(contFig,'visible','on');
  if ( ~ishandle(contFig) ) break; end;

  phaseToRun=[];
  % BODGE: move point to force key-processing
  fprintf('.');set(ph,'ydata',rand(1)*.01); drawnow;
  if ( ~ishandle(contFig) ) break; end;
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
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until capFitting is done
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
   case {'calibrate','calibration'};
    sendEvent('subject',subject);
    if( ~strcmp(lower(phaseToRun),'practice') ) % only tell sig-proc if actual run
       sendEvent('startPhase.cmd',phaseToRun)
    end
    sendEvent(phaseToRun,'start');
    try
      spCalibrateStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.training','end');    
    end
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case 'trainerp';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until training is done
    while (true) % N.B. use a loop as safer and matlab still responds on windows...
       [devents]=buffer_newevents(buffhost,buffport,[],phaseToRun,'end',1000); % wait until finished
       drawnow;
       if ( ~isempty(devents) ) break; end;
    end
        
   %---------------------------------------------------------------------------
   case 'eventseqfeedback';
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd',phaseToRun);
      spFeedbackStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.test','end');
    end
    sendEvent('stimulus.test','end');
    sendEvent(phaseToRun,'end');
    
   %---------------------------------------------------------------------------
   case 'eventfeedback';
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd',phaseToRun);
      spContFeedbackStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.test','end');
    end
    sendEvent('stimulus.test','end');
    sendEvent(phaseToRun,'end');

   case 'quit';
	break;
    
  end
end
% shut down signal proc
sendEvent('startPhase.cmd','exit');
% thank subject
uiwait(msgbox({'Thankyou for participating in our experiment.'},'Thanks','modal'),10);
