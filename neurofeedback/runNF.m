configureNF;
% create the control window and execute the phase selection loop
contFig=controller(); info=guidata(contFig); 
while (ishandle(contFig))
  set(contFig,'visible','on');
  uiwait(contFig); % CPU hog on ver 7.4
  if ( ~ishandle(contFig) ) break; end;
  set(contFig,'visible','off');
  info=guidata(contFig); 
  subject=info.subject;
  phaseToRun=lower(info.phaseToRun);
  fprintf('Start phase : %s\n',phaseToRun);
  
  switch phaseToRun;
    
   %---------------------------------------------------------------------------
   case 'capfitting';
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until capFitting is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');

   %---------------------------------------------------------------------------
   case 'eegviewer';
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until capFitting is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');
       
   %---------------------------------------------------------------------------
   case {'neurofeedback'};
    sendEvent('subject',info.subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','contfeedback');
      neurofeedbackStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    end
    sendEvent('neurofeedback','end');
    sendEvent('test','end');
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
end
uiwait(msgbox({'Thankyou for participating in our experiment.'},'Thanks','modal'),10);
pause(1);
% shut down signal proc
sendEvent('startPhase.cmd','exit');
