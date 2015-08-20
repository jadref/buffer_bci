configureIM;
% create the control window and execute the phase selection loop
if ( exist('OCTAVE_VERSION','builtin') ) 
  contFig=figure(1);
  set(contFig,'name','BCI Controller : close to quit','color',[0 0 0]);
  axes('position',[0 0 1 1],'visible','off','xlim',[0 1],'ylim',[0 1],'nextplot','add');
  set(contFig,'Units','pixel');wSize=get(contFig,'position');
  fontSize = .05*wSize(4);
  instructStr={'1) EEG'; 
					'2) Practice';
               '3) Calibrate';
               '4) Train Classifier';
					'5) Epoch Feedback';
					'6) Cont/Neuro feedback'};
  txth=text(.25,.7,instructStr,'fontunits','pixel','fontsize',.05*wSize(4),...
				'HorizontalAlignment','left','color',[1 1 1]);
  ph=plot(1,0,'b'); % BODGE: point to move around to update the plot to force key processing
  % install listener for key-press mode change
  set(contFig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
  set(contFig,'userdata',[]);
  drawnow; % make sure the figure is visible
else
  contFig=controller(); info=guidata(contFig); 
end
subject='test';

while (ishandle(contFig))
  set(contFig,'visible','on');
  if ( ~ishandle(contFig) ) break; end;

  phaseToRun=[];
  if ( ~exist('OCTAVE_VERSION','builtin') ) 
	 uiwait(contFig); % CPU hog on ver 7.4
	 info=guidata(contFig); 
	 subject=info.subject;
	 phaseToRun=lower(info.phaseToRun);
  else % give time to process the key presses
	 % BODGE: move point to force key-processing
	 fprintf('.');set(ph,'ydata',rand(1)*.01); drawnow; pause(.1);  
	 if ( ~ishandle(contFig) ) break; end;
  end

  % process any key-presses
  modekey=get(contFig,'userdata'); 
  if ( ~isempty(modekey) ) 	 
	 fprintf('key=%s\n',modekey);
    switch ( modekey(1) );
     case {'1','e'}; phaseToRun='eegviewer';
     case {'2','p'}; phaseToRun='practice';
     case {'3','c'}; phaseToRun='calibrate';
     case {'4','t'}; phaseToRun='train';
     case {'5','e'}; phaseToRun='epochfeedback';
	  case {'6','n'}; phaseToRun='contfeedback';
     otherwise;    phaseToRun=[];
    end;
    set(contFig,'userdata',[]);
  end

  if ( isempty(phaseToRun) ) continue; end;

  fprintf('Start phase : %s\n',phaseToRun);  
  set(contFig,'visible','off');
  switch phaseToRun;
    
   %---------------------------------------------------------------------------
   case 'capfitting';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until capFitting is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');
    %buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);       

   %---------------------------------------------------------------------------
   case 'eegviewer';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until capFitting is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');
    %buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);           
    
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
    try
      imCalibrateStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('training','end');    
    end
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'train','classifier'};
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until training is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');
    %buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);  

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
        
  end
  if ( ~ishandle(contFig) && ~exist('OCTAVE_VERSION','builtin') ) 
    oinfo=info; % store old info
    contFig=controller(); % make new figure
    info=guidata(contFig); % get new info
                           % re-place old info
    info.phasesCompleted=oinfo.phasesCompleted;
    info.phaseToRun=oinfo.phaseToRun;
    info.subject=oinfo.subject; set(info.subjectName,'String',subject);
    guidata(contFig,info);
  end;
end
uiwait(msgbox({'Thankyou for participating in our experiment.'},'Thanks','modal'),10);
pause(1);
% shut down signal proc
sendEvent('startPhase.cmd','exit');
