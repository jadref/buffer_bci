dbstop if error;
configureGame;

% create the control window and execute the phase selection loop
contFig=gameController(); info=guidata(contFig); 
while (ishandle(contFig))
  set(contFig,'visible','on');
  uiwait(contFig); % CPU hog on ver 7.4
  if ( ~ishandle(contFig) ) break; end;
  set(contFig,'visible','off');
  info=guidata(contFig); 
  subject=info.subject;
  level  =info.level;
  speed  =info.speed;  
  moveInterval = ceil(speed/isi)*isi;
  moveInterval = min(maxMoveInterval,moveInterval);

  phaseToRun=lower(info.phaseToRun);
  switch phaseToRun;
    
   case 'capfitting';
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until capFitting is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');
    %buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);       
    
   case 'eegviewer';
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until capFitting is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');
    %buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);               
    
   case 'practice';
    sendEvent('subject',info.subject);
    sendEvent(phaseToRun,'start');
    onSeq=nSeq; nSeq=4; % override sequence number
    try
      gameCalibrateStimulus()
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      % do nothing
    end
    sendEvent(phaseToRun,'end');
    nSeq=onSeq;
    
   case 'calibrate';
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun)
    sendEvent(phaseToRun,'start');
    try
      gameCalibrateStimulus()
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.training','end');    
    end
    sendEvent(phaseToRun,'end');

   case 'train';
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until training is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');
    %buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);  
    
   case 'snake';
    sendEvent('subject',info.subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','testing');
      snake;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.test','end');
    end
    sendEvent(phaseToRun,'end');
    
   case 'sokoban';
    sendEvent('subject',info.subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try;
      sendEvent('startPhase.cmd','testing');
      sokoban;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.test','end');
    end
    sendEvent(phaseToRun,'end');
    
   case 'pacman';
    sendEvent('subject',info.subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','testing');
      pacman;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.test','end');
    end
    sendEvent(phaseToRun,'end');

    
   case {'contfeedback','spelling'};
    sendEvent('subject',info.subject);
    %sleepSec(.1);
    sendEvent('spelling','start');
    try
      sendEvent('startPhase.cmd','contfeedback');
      spContFeedbackStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.test','end');
    end
    sendEvent('spelling','end');    
    
  end
  info.phasesCompleted={info.phasesCompleted{:} info.phaseToRun};
  if ( ~ishandle(contFig) ) 
    oinfo=info; % store old info
    contFig=gameController(); % make new figure
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
uiwait(msgbox({'Thankyou for participating in our experiment.'},'Thanks','modal'),10);
pause(1);
% shut down signal proc
sendEvent('startPhase.cmd','exit');