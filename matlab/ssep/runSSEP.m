configureSSEP;

% create the control window and execute the phase selection loop
contFig=figure(1);
set(contFig,'name','BCI Controller : close to quit','color',[0 0 0]);
axes('position',[0 0 1 1],'visible','off','xlim',[0 1],'ylim',[0 1],'nextplot','add');
set(contFig,'Units','pixel');wSize=get(contFig,'position');fontSize = .05*wSize(4);
%        Instruct String          Phase-name
menustr={'0) EEG'                 'eegviewer';
         '1) Practice'            'practice';
			'2) Calibrate'           'calibrate'; 
         '3) Calibrate (Psychtoolbox)'        'calibrateptb'; 
			'4) Train Classifier'    'trainersp';
		   '5) Feedback'            'epochfeedback';
			'6) Feedback (Psychtoolbox)'         'epochfeedbackptb';
			'q) quit'                'quit';
};
txth=text(.25,.5,menustr(:,1),'fontunits','pixel','fontsize',.05*wSize(4),...
			  'HorizontalAlignment','left','color',[1 1 1]);
	 % BODGE: point to move around to update the plot to force key processing
ph=[];if ( exist('OCTAVE_VERSION') ) ph=plot(1,0,'k'); end
										  % install listener for key-press mode change
set(contFig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
set(contFig,'userdata',[]);
drawnow; % make sure the figure is visible
subject='test';

sendEvent('experiment.ssep','start');
while (ishandle(contFig))
  set(contFig,'visible','on');

  phaseToRun=[];
  if ( exist('OCTAVE_VERSION','builtin') ) 
	 % BODGE: move point to force key-processing
	 if ( ~isempty(ph) ) fprintf('.');set(ph,'ydata',rand(1)*.01); end
  end
  drawnow;
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
		end
	 end
    set(contFig,'userdata',[]);
  end

  if ( isempty(phaseToRun) ) pause(.3); continue; end;

  fprintf('Start phase : %s\n',phaseToRun);
  set(contFig,'visible','off');
  
  switch phaseToRun;
    
   %---------------------------------------------------------------------------
   case 'capfitting';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun); % tell sig-proc what to do
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end'); % wait until finished	  
     
   %---------------------------------------------------------------------------
   case 'eegviewer';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun); % tell sig-proc what to do
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end'); % wait until finished
	  
   %---------------------------------------------------------------------------
   case 'practice';
    sendEvent('subject',subject);
    sendEvent(phaseToRun,'start');
    onSeq=nSeq; nSeq=4; % override sequence number
    onRepetitions=nRepetitions; nRepetitions=3;
    %try
      ssepCalibrateStimulus;
    %catch
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    %end
    sendEvent(phaseToRun,'end');
    nSeq=onSeq;
    nRepetitions=onRepetitions;
    
   %---------------------------------------------------------------------------
   case {'calibrate','calibration','calibrateptb','calibrationptb'};
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd','calibrate');
    sendEvent(phaseToRun,'start');
	 %try
	 if ( ~isempty(strfind(lower(phaseToRun),'ptb') ) )
		ssepCalibrateStimulusPTB; % PsychToolBox version
	 else
		ssepCalibrateStimulus;
	 end
    %catch
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    %end
    sendEvent('calibrate','end');    
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'train','classifier','trainerp','trainersp'};
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until training is done
    buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);  
       
   %---------------------------------------------------------------------------
   case {'testing','test','epochfeedback','epochfeedbackptb'};
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    %try
    sendEvent('startPhase.cmd','testing');
	 if ( ~isempty(strfind(lower(phaseToRun),'ptb')) )
		ssepFeedbackStimulusPTB; % PsychToolBox version
	 else
      ssepFeedbackStimulus;
	 end
    %catch
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    %end
    sendEvent('testing','end');
    sendEvent(phaseToRun,'end');
    
   %---------------------------------------------------------------------------
    case {'quit','exit'};
      break;
  end

    
  %for i=1:numel(info.phasesCompleted); % set all run phases to have green text
  %    set(getfield(info,[info.phasesCompleted{i} 'But']),'ForegroundColor',[0 1 0]);
  %end
end
uiwait(msgbox({'Thankyou for participating in our experiment.'},'Thanks','modal'),10);
pause(1);
% shut down signal proc
sendEvent('startPhase.cmd','exit');
sendEvent('experiment.ssep','end');
return;

% offline-analysis code
addpath('../offline');
[data,devents,hdr,events]=sliceraw('jason/140321/2159_24696/raw_buffer/0003','startSet',{'stimulus.target'},'trlen_ms',3000,'offset_ms',[2000 2000]); % N.B. Note the cue offset
[clsfr,X]=buffer_train_ersp_clsfr(data,devents,hdr,'capFile',capFile,'overridechnms',1,'freqband',{[15 20]},'spatialfilter','ssep','spType','1v1','width_ms',1000);

% make the stim-seq
[stimSeq,stimTime,eventSeq,colors]=mkStimSeq_flicker(1:4,trialDuration,isi,periods,false);
times=(0:(1/hdr.Fs):3-1/hdr.Fs)';
% zero out any sequences of high values
ss=stimSeq; ss(ss(:,1:end-1)==ss(:,2:end))=0;
% convert to timed events, N.B. input is [markers x classes]
ref=insertTimedMarkers(stimTime',ss',times); % [samp x classes]
% extract a correctly labelled version
mi=matchEvents(events,'stimulus.stimSeq');
ssY=cat(2,events(mi).value); % [ times x epochs ]
% zero out any sequences of high values
ssY(ssY(:,1:end-1)==ssY(:,2:end))=0;
% convert to sample events
refY=insertTimedMarkers(stimTime',ssY,times); % [samp x epoch]

% pre-process the data
% get the channel positions
di=addPosInfo(hdr.label,'cap_tmsi_mobita_black',1);
iseeg=[di.extra.iseeg]; ch_names=di.vals(iseeg); ch_pos=[di.extra(iseeg).pos2d];
X=cat(3,data.buf); % get 3-d array
X=X([di.extra.iseeg],:,:); % remove non-eeg channels
X=detrend(X,2);   % temporal trend removal
X=repop(X,'-',mean(X,1)); % CAR - spatial mean removal
badch=idOutliers(X,1,3)
X=X(~badch,:,:);

% non-discrim
[U,s,V,Xr,covX,covR]=ccaDeconv(X,[1 2],ref,0:round(hdr.Fs*.5)); % 1/2 second IRF
% discrim
[U,s,V,Xr,covX,covR]=ccaDeconv(X,[1 2],refY,0:round(hdr.Fs*.5)); % 1/2 second IRF

% plot the result
clf;parafacPlot({s(1:6) covX*U V},{'ch','time'},'dispType',{'topoplot' 'mcplot'},'layout',[0 .5 1 .5;0 0 1 .5],'plotOpts',{{} {'center' 0}},'electPos',ch_pos)
