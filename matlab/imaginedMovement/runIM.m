configureIM;
% create the control window and execute the phase selection loop
% try
%   contFig=controller(); info=guidata(contFig); 
% catch
  contFig=figure(1);clf;
  set(contFig,'name','BCI Controller : close to quit','color',[0 0 0]);
  axes('position',[0 0 1 1],'visible','off','xlim',[0 1],'ylim',[0 1],'nextplot','add');
  set(contFig,'Units','pixel');wSize=get(contFig,'position');
  fontSize = .05*wSize(4);
  %        Instruct String             Phase-name
  menustr={'0) EEG'                    'eegviewer';
			  'a) Artifacts'              'artifact';
           '1) Practice'               'practice';
			  '2) Calibrate'              'calibrate'; 
			  '3) Train Classifier'       'trainersp';
			  '4) Epoch Feedback'         'epochfeedback';
			  '5) Continuous Feedback'    'contfeedback';
           '6) Center-out Training'    'centerout';
			  '7) NeuroFeedback Training' 'neurofeedback';
			  'q) quit'                   'quit';
          };
  txth=text(.25,.5,menustr(:,1),'fontunits','pixel','fontsize',.05*wSize(4),...
				'HorizontalAlignment','left','color',[1 1 1]);
  ph=plot(1,0,'k'); % BODGE: point to move around to update the plot to force key processing
  % install listener for key-press mode change
  set(contFig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
  set(contFig,'userdata',[]);
  drawnow; % make sure the figure is visible
% end
subject='test';

sendEvent('experiment.im','start');
while (ishandle(contFig))
  set(contFig,'visible','on');
  if ( ~ishandle(contFig) ) break; end;

  phaseToRun=[];
  if ( ~exist('OCTAVE_VERSION','builtin') && ~isempty(get(contFig,'tag')) ) % using the gui-figure-window
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

  fprintf('Start phase : %s\n',phaseToRun);  
  set(contFig,'visible','off');drawnow;
  switch phaseToRun;
    
   %---------------------------------------------------------------------------
   case 'capfitting';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun); % tell sig-proc what to do
    while (true) % N.B. use a loop as safer and matlab still responds on windows...
       [devents]=buffer_newevents(buffhost,buffport,[],phaseToRun,'end',1000); % wait until finished
       drawnow;
       if ( ~isempty(devents) ) break; end;
    end

   %---------------------------------------------------------------------------
   case 'eegviewer';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun); % tell sig-proc what to do
    % wait until capFitting is done
    while (true) % N.B. use a loop as safer and matlab still responds on windows...
       [devents]=buffer_newevents(buffhost,buffport,[],phaseToRun,'end',1000); % wait until finished
       drawnow;
       if ( ~isempty(devents) ) break; end;
    end
    
   %---------------------------------------------------------------------------
   case 'artifact';
    sendEvent('subject',subject);
    sendEvent(phaseToRun,'start');
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
	 sendEvent(phaseToRun,'end');
    
   %---------------------------------------------------------------------------
   case {'calibrate','calibration','practice'};
     sendEvent('subject',subject);
	  if ( ~isempty(strfind(phaseToRun,'calibrat')) ) % tell the sig-proc to go if real run
		 sendEvent('startPhase.cmd','calibrate')
	  end
    sendEvent(phaseToRun,'start');
    try
      imCalibrateStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
    end
    if ( ~isempty(strfind(phaseToRun,'calibrat')) ) sendEvent('calibrate','end'); end   
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'train','trainersp'};
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun); % tell sig-proc what to do
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end',inf); % wait until finished

   %---------------------------------------------------------------------------
   case {'epochfeedback'};
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
		if ( earlyStopping ) % use the user-defined command
		  sendEvent('startPhase.cmd',userFeedbackTable{1});
		else
        sendEvent('startPhase.cmd','epochfeedback');
		end
      imEpochFeedbackStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
    end
    sendEvent('test','end');
    sendEvent(phaseToRun,'end');
   
   %---------------------------------------------------------------------------
   case {'contfeedback'};
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','contfeedback');
      imContFeedbackStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
    end
    sendEvent('test','end');
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'neurofeedback'};
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','contfeedback');
      imNeuroFeedbackStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
    end
    sendEvent('contfeedback','end');
    sendEvent('test','end');
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'centerout' 'centeroutfeedback'};
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','contfeedback');
      imCenterOutTrainingStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
    end
    sendEvent('contfeedback','end');
    sendEvent('test','end');
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'quit','exit'};
    break;
    
  end
end
% shut down signal proc
sendEvent('startPhase.cmd','exit');
% give thanks
uiwait(msgbox({'Thankyou for participating in our experiment.'},'Thanks','modal'),10);
