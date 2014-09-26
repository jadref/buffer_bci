configureDemo;
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

   %--------------------------------------------------------------
   % brain responses
   
   case {'erspvis','erpvis','erpviewer'};
    trialDuration=ersptrialDuration;
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    %try
      evokedDemoERPStimulus;
    %catch
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      % do nothing
    %end
    sendEvent(phaseToRun,'end');    

   case {'erpvisptb'};
    trialDuration=ersptrialDuration;
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    try
      evokedDemoERPStimulusPTB;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    end
    sendEvent(phaseToRun,'end');    
    
    %--------------------------------------------------------------
    % speller    
   case 'sppractice';
    sendEvent('subject',info.subject);
    sendEvent(phaseToRun,'start');
    onSeq=nSeq; nSeq=4; % override sequence number
    onRepetitions=nRepetitions; nRepetitions=3;
    %try
      spCalibrateStimulus;
    %catch
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    %end
    sendEvent(phaseToRun,'end');
    nSeq=onSeq;
    nRepetitions=onRepetitions;
    
   case {'spcalibrate','spcalibration'};
    nSeq=spnSeq;
    trlen_ms=sptrlen_ms;
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    sendEvent(phaseToRun,'start');
    %try
      spCalibrateStimulus;
    %catch
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.training','end');    
    %end
    sendEvent(phaseToRun,'end');

   case {'sptrain','spclassifier'};
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until training is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');
    %buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);  
       
   case {'sptesting','sptest','freespell'};
    trlen_ms=sptrlen_ms;
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    try
      spFeedbackStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    end
    sendEvent('stimulus.test','end');
    sendEvent(phaseToRun,'end');
  
   %---------------------------------------------------------------------------
   % Movement BCI
   case 'impractice';
    sendEvent('subject',info.subject);
    sendEvent(phaseToRun,'start');
    onSeq=nSeq; nSeq=4; % override sequence number
    trialDuration=imtrialDuration;
    try
      imCalibrateStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    end
    sendEvent(phaseToRun,'end');
    nSeq=onSeq;
    
   case {'imcalibrate','imcalibration'};
    nSeq=imnSeq;
    trialDuration=imtrialDuration;
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun)
    sendEvent(phaseToRun,'start');
    try
      imCalibrateStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.training','end');    
    end
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'imtrain','imclassifier'};
    nSeq=imnSeq;
    trialDuration=imtrialDuration;
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until training is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');
    %buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);  

   case {'imtest','imtesting','imepochfeedback','epochfeedback'};
    trialDuration=imtrialDuration;
    trlen_ms=imtrlen_ms;
    nSeq=imnSeq;
    sendEvent('subject',info.subject);
    %sleepSec(.1);
    try
      sendEvent('startPhase.cmd',phaseToRun);
      imEpochFeedbackStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    end
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
%uiwait(msgbox({'Thank you for participating in our experiment.'},'Thanks','modal'),10);
pause(1);
% shut down signal proc
sendEvent('startPhase.cmd','exit');
