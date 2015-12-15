configureRsvp;

% create the control window and execute the phase selection loop
contFig=figure(1); 
clf;
set(contFig,'name','BCI Controller : close to quit','color',[0 0 0]);
axes('position',[0 0 1 1],'visible','off','xlim',[0 1],'ylim',[0 1],'nextplot','add');
set(contFig,'Units','pixel');wSize=get(contFig,'position');
fontSize = .05*wSize(4);
%        Instruct String          Phase-name
menustr={'0) EEG'                 'eegviewer';
         '1) Practice'            'practice';
			'2) Calibrate'           'erpviewcalibrate'; 
         '3) Train Classifier'    'train';
			'4) PsychoPhysics - color'       'psycho-color';
			'5) PsychoPhysics - compression' 'psycho-images';
			'q) quit'                'quit';
          };
txth=text(.25,.5,menustr(:,1),'fontunits','pixel','fontsize',.05*wSize(4),...
			 'HorizontalAlignment','left','color',[1 1 1]);
% BODGE: point to move around to update the plot to force key processing in OCTAVE
ph=[]; if ( exist('OCTAVE_VERSION','builtin') ) ph=plot(1,0,'k'); end
% install listener for key-press mode change
set(contFig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
set(contFig,'userdata',[]);
drawnow; % make sure the figure is visible

subject='test';
phaseToRun=[];
while (ishandle(contFig) && ~strcmp(phaseToRun,'quit') )
  set(contFig,'visible','on');
  if ( ~ishandle(contFig) ) break; end;

  phaseToRun=[];
  % BODGE: move point to force key-processing
  if ( ~isempty(ph) ) fprintf('.');set(ph,'ydata',rand(1)*.01); end;
  drawnow; pause(.1); 
  if ( ~ishandle(contFig) ) break; end;

  % process any key-presses
  modekey=get(contFig,'userdata'); 
  if ( ~isempty(modekey) ) 	 
	 fprintf('key=%s\n',modekey);
	 phaseToRun=[];
	 if ( isstr(modekey(1)) )
		ri = int32(modekey(1)-'0')+1; % get the row in the instructions
		if ( ri>0 && ri<size(menustr,1))
		  phaseToRun = menustr{ri,2};
		elseif ( any(strcmp(modekey(1),{'q','Q','esc'})) )
		  phaseToRun  = 'quit';	  
		end
	 end
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
	 seqDuration=trainSeqDuration;
    onSeq=nSeq; nSeq=1; % override sequence number
    try
      rsvpCalibrateStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  if(~isempty(le.stack)) fprintf('%s>%s : %d\n',le.stack(1).file,le.stack(1).name,le.stack(1).line);end
    end
    sendEvent(phaseToRun,'end');
    nSeq=onSeq;
    
   %---------------------------------------------------------------------------
   case {'calibrate','calibration','erpviewcalibrate'};
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun);
    sendEvent(phaseToRun,'start');
	 seqDuration=trainSeqDuration;
    try
      rsvpCalibrateStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  if ( ~isempty(le.stack) ) fprintf('%s>%s : %d',le.stack(1).file,le.stack(1).name,le.stack(1).line);end
      sendEvent('training','end');    
    end
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'train','classifier'};
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until sig-processor says training is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'test','testing','epochfeedback','psycho-color','psycho-images'};
	 testType='color';
	 if (strcmp(phaseToRun,'psycho-images') ) testType='images'; end;
    sendEvent('subject',subject);
    %sleepSec(.1);
	 seqDuration=testSeqDuration;
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','epochfeedback');
      rsvpPsychoPhysicsStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  if ( ~isempty(le.stack) ) fprintf('%s>%s : %d',le.stack(1).file,le.stack(1).name,le.stack(1).line);end
    end
    sendEvent('test','end');
    sendEvent(phaseToRun,'end');
   
	case 'quit';
	  break;
      
	case 'quit';
	  break;

   %---------------------------------------------------------------------------
   otherwise;
	  fprintf('Huh I didnt understand the option you choose: %s\n',phaseToRun);
        
  end
end
% display thanks
if ( ishandle(contFig) )
   cla;
   text(.25,.5,{'Thankyou for participating in our experiment.'},...
        'fontunits','pixel','fontsize',.05*wSize(4),...
        'HorizontalAlignment','left','color',[1 1 1]);
   drawnow;
   pause(2);
end
% shut down signal proc
sendEvent('startPhase.cmd','exit');
