configureIM;

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
			  '3) Train Classifier'    'trainersp';
			  '4) Epoch Feedback'      'epochfeedback';
			  '5) Continuous Feedback' 'contfeedback';
			  '6) NeuroFeedback'       'neurofeedback'
			  '7) Center out feedback' 'centerout'
			  'q) exit'                'quit';
        };
txth=text(.25,.5,menustr(:,1),'fontunits','pixel','fontsize',.05*wSize(4),...
          'HorizontalAlignment','left','color',[1 1 1]);
ph=plot(1,0,'k'); % BODGE: point to move around to update the plot to force key processing
                  % install listener for key-press mode change
set(contFig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
set(contFig,'userdata',[]);
drawnow; % make sure the figure is visible
subject='test';

sendEvent('experiment.im','start');
while (ishandle(contFig))
  set(contFig,'visible','on');
  if ( ~ishandle(contFig) ) break; end;

  phaseToRun=[];
  if ( exist('OCTAVE_VERSION','builtin') ) 
	 % BODGE: move point to force key-processing
	 fprintf('.');set(ph,'ydata',rand(1)*.01); drawnow;
  end
  pause(.1);
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

  fprintf('Start phase : %s\n',phaseToRun);  
  set(contFig,'visible','off');drawnow;
  switch phaseToRun;
    
   %---------------------------------------------------------------------------
   case 'capfitting';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun); % tell sig-proc what to do
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end',inf); % wait until finished

   %---------------------------------------------------------------------------
   case 'eegviewer';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun); % tell sig-proc what to do
    % wait until capFitting is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end',inf); % wait until finished
    
   %---------------------------------------------------------------------------
   case 'practice';
    sendEvent('subject',subject);
    sendEvent(phaseToRun,'start');
    onSeq=nSeq; nSeq=4; % override sequence number
    try
      imCalibrateStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    end
    sendEvent(phaseToRun,'end');
    nSeq=onSeq;
    
   %---------------------------------------------------------------------------
   case {'calibrate','calibration'};
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun)
    sendEvent(phaseToRun,'start');
    %try
      imCalibrateStimulus;
      %catch
      %le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      %if ( isfield(le,'stack') ) disp(le.stack(1)), end;
      sendEvent('training','end');    
      %end
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'train','trainersp'};
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun); % tell sig-proc what to do
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end'); % wait until finished

   %---------------------------------------------------------------------------
   case {'epochfeedback'};
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','epochfeedback');
      imEpochFeedbackStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
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
       sleepSec(.1);
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
    end
    sendEvent('contfeedback','end');
    sendEvent('test','end');
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'centerout' 'centeroutfeedback'};
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    %try
      sendEvent('startPhase.cmd','contfeedback');
      imCenteroutStimulus;
      %catch
      %le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      % sleepSec(.1);
      %end
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
