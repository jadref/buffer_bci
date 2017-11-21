configureIM;
contFig=figure(1);clf;
set(contFig,'name','BCI Controller : close to quit','color',[0 0 0],'menubar','none','toolbar','none');
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
         '' '';
         'S) Slice ftoffline data'   'sliceraw';
         'L) Load training data'     'loadtraining';
			'q) exit'                   'quit';
};
menuh=text(.25,.5,menustr(:,1),'fontunits','pixel','fontsize',.05*wSize(4),...
			 'HorizontalAlignment','left','color',[1 1 1]);
msgh=text(.5,.1,'','fontunits','pixel','fontsize',.08*wSize(4),...
          'HorizontalAlignment','center','color',[1 1 1]);
ph=plot(1,0,'k'); % BODGE: point to move around to update the plot to force key processing
% install listener for key-press mode change
set(contFig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
set(contFig,'userdata',[]);
drawnow; % make sure the figure is visible
subject='test';

sendEvent('experiment.im','start');
while (ishandle(contFig))
  if ( ~ishandle(contFig) ) break; end;
  set(menuh,'color',[1 1 1]);% ensure menu is visible....
  set(msgh,'color',[1 1 1]*.5); % ensure status is grey
  
  phaseToRun=[];
                                % BODGE: move point to force key-processing
  set(contFig,'visible','on');
  fprintf('.');set(ph,'ydata',rand(1)*.01); drawnow;
  if ( ~ishandle(contFig) ) break; end;

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
  set(menuh,'color',[1 1 1]*.5);
  set(msgh,'string',{sprintf('Phase: %s',phaseToRun),'Starting...'},'color',[1 1 1],'visible','on');
  drawnow;
  sendEvent('sigproc.reset','end'); % reset the sig-processor just in case
  sigProcCmd=['sigproc.' lower(phaseToRun)]; 
  state=[]; % reset to ignore anything from before now...
  switch phaseToRun;
    
   %---------------------------------------------------------------------------
   % Simple forward to the sig-processor commands
   %  sig-viewers, data-slicer/loader, classifier training
   case {'capfitting','eegviewer','loadtraining','sliceraw','train','trainersp'};
    sendEvent('subject',subject);
    sendEvent(sigProcCmd,'start'); % tell sig-proc what to do
    [devents,state]=buffer_newevents(buffhost,buffport,[],sigProcCmd,'ack',4000); % wait for start acknowledgement
    % mark as running
    if( isempty(devents) )
      set(msgh,'string',{sprintf('Warning::%s is taking too long to start...',phaseToRun),'did it crash?'},'visible','on');
    else
      set(msgh,'string',{sprintf('Phase: %s',phaseToRun),'Running...'},'visible','on');
    end
    drawnow;
    % wait to finish
    for i=1:20;
      [devents,state]=buffer_newevents(buffhost,buffport,state,sigProcCmd,'end',1000); % wait until finished
      drawnow;
      if ( ~isempty(devents) ) break; end;
    end
    if( isempty(devents) ) % warn if taking too long
      set(msgh,'string',{sprintf('Warning::%s is taking a long time....',phaseToRun),'did it crash?'},'visible','on');
    else
      set(msgh,'string','');
      sigProcCmd='';
    end
    drawnow;
    
   %---------------------------------------------------------------------------
   case 'artifact';
    sendEvent('subject',subject);
    sendEvent(phaseToRun,'start');
    sigProcCmd=''; % mark as no-sig-proc needed
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
      sendEvent(phaseToRun,'end');    
    end
	 sendEvent(phaseToRun,'end');
    
   %---------------------------------------------------------------------------
   case {'calibrate','calibration','practice'};
     sendEvent('subject',subject);
     sigProcCmd=''; % mark as no-sig-proc needed
	  if ( ~isempty(strfind(phaseToRun,'calibrat')) ) % tell the sig-proc to go if real run
       sigProcCmd='sigproc.calibrate';
     end
     if( ~isempty(sigProcCmd) ) % tell sig-proc what to do, if needed
       sendEvent(sigProcCmd,'start'); 
       % wait for sig-processor startup acknowledgement
       [devents,state]=buffer_newevents(buffhost,buffport,[],sigProcCmd,'ack',4000); 
	  end
     if( ~isempty(sigProcCmd) && isempty(devents) ) % mark as taking a long time
       set(msgh,'string',{sprintf('Warning::%s is taking too long to start...',phaseToRun),'did it crash?'},'visible','on');
     else % mark as running
       set(msgh,'string',{sprintf('Phase: %s',phaseToRun),'Running...'},'visible','on');
     end
     drawnow;

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
    if ( ~isempty(strfind(phaseToRun,'calibrat')) )
      sendEvent('calibrate','end');
    end   
    sendEvent(phaseToRun,'end');

     %---------------------------------------------------------------------------
     sigProcCmd=['sigproc.' phaseToRun]; % command to send to the signal processor
     sendEvent(sigProcCmd,'start'); 
     % wait for sig-processor startup acknowledgement
     [devents,state]=buffer_newevents(buffhost,buffport,[],sigProcCmd,'ack',4000); 
     if( ~isempty(sigProcCmd) && isempty(devents) ) % mark as taking a long time
       set(msgh,'string',{sprintf('Warning::%s is taking too long to start...',phaseToRun),'did it crash?'},'visible','on');
     else % mark as running
       set(msgh,'string',{sprintf('Phase: %s',phaseToRun),'Running...'},'visible','on');
     end
             
   %---------------------------------------------------------------------------
   case {'epochfeedback'};
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');

    if ( earlyStopping ) sigProcCmd=['sigproc.' userFeedbackTable{1}]; end;
    sendEvent(sigProcCmd,'start');
                             % wait for sig-processor startup acknowledgement
    [devents,state]=buffer_newevents(buffhost,buffport,[],['sigproc.' phaseToRun],'ack',4000); 
    if( isempty(devents) ) % mark as taking a long time
      set(msgh,'string',{sprintf('Warning::%s is taking too long to start...',phaseToRun),'did it crash?'},'visible','on');
    else % mark as running
      set(msgh,'string',{sprintf('Phase: %s',phaseToRun),'Running...'},'visible','on');
    end
    drawnow;

    try
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
    sendEvent(sigProcCmd,'start'); % tell sig-proc what to do
                             % wait for sig-processor startup acknowledgement
    [devents,state]=buffer_newevents(buffhost,buffport,[],sigProcCmd,'ack',4000); 
    if( isempty(devents) ) % mark as taking a long time
      set(msgh,'string',{sprintf('Warning::%s is taking too long to start...',phaseToRun),'did it crash?'},'visible','on');
    else % mark as running
      set(msgh,'string',{sprintf('Phase: %s',phaseToRun),'Running...'},'visible','on');
    end

    try
       drawnow;
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

    sigProcCmd='sigproc.contfeedback';
    sendEvent(sigProcCmd,'start'); % tell sig-proc what to do
                             % wait for sig-processor startup acknowledgement
    [devents,state]=buffer_newevents(buffhost,buffport,[],sigProcCmd,'ack',4000); 
    if( isempty(devents) ) % mark as taking a long time
      set(msgh,'string',{sprintf('Warning::%s is taking too long to start...',phaseToRun),'did it crash?'},'visible','on');
    else % mark as running
      set(msgh,'string',{sprintf('Phase: %s',phaseToRun),'Running...'},'visible','on');
    end

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

    sigProcCmd='sigproc.contfeedback';
    sendEvent(sigProcCmd,'start'); % tell sig-proc what to do
                             % wait for sig-processor startup acknowledgement
    [devents,state]=buffer_newevents(buffhost,buffport,[],sigProcCmd,'ack',4000); 
    if( isempty(devents) ) % mark as taking a long time
      set(msgh,'string',{sprintf('Warning::%s is taking too long to start...',phaseToRun),'did it crash?'},'visible','on');
    else % mark as running
      set(msgh,'string',{sprintf('Phase: %s',phaseToRun),'Running...'},'visible','on');
    end

    try
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

  if( ~isempty(sigProcCmd) )
                                % check for sig-processor finish
    [devents,state]=buffer_newevents(buffhost,buffport,state,sigProcCmd,'end',4000); % wait until finished
    if( isempty(devents) ) % warn if taking too long
      set(msgh,'string',{sprintf('Warning::%s is taking a long time....',phaseToRun),'did it crash?'},'visible','on'); 
    else
      set(msgh,'string','');
    end
  else
    set(msgh,'string','');
  end
  drawnow;

  
end
% shut down signal proc
sendEvent('startPhase.cmd','exit');
% give thanks
msgbox({'Thankyou for participating in our experiment.'},'Thanks');
