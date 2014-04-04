configureSSEP();
sendEvent('experiment.ssep','start');
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
    % run the code directly
    fig=figure(2);clf; % new figure
    capFitting('noiseThresholds',thresh,'badChThreshold',badchThresh,'verb',verb,'showOffset',0,'capFile',capFile,'overridechnms',overridechnms);
    if ( ishandle(fig) ) close(fig); end;
    
   %---------------------------------------------------------------------------
   case 'eegviewer';
    % run the code directly
    fig=figure(2);clf; % new figure
    eegViewer(buffhost,buffport,'capFile',capFile,'overridechnms',overridechnms);
    if ( ishandle(fig) ) close(fig); end;

   %---------------------------------------------------------------------------
   case 'practice';
    sendEvent('subject',info.subject);
    sendEvent(phaseToRun,'start');
    onSeq=nSeq; nSeq=4; % override sequence number
    onRepetitions=nRepetitions; nRepetitions=3;
    %try
      ssepCalibrateStimulus();
    %catch
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    %end
    sendEvent(phaseToRun,'end');
    nSeq=onSeq;
    nRepetitions=onRepetitions;
    
   %---------------------------------------------------------------------------
   case {'calibrate','calibration'};
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    sendEvent(phaseToRun,'start');
    %try
      ssepCalibrateStimulus();
    %catch
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.training','end');    
    %end
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'calibrateptb','calibrationptb'};
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    sendEvent(phaseToRun,'start');
    %try
      ssepCalibrateStimulusPTB();
    %catch
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.training','end');    
    %end
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'train','classifier'};
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until training is done
    buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);  
       
   %---------------------------------------------------------------------------
   case {'testing','test'};
    sendEvent('subject',info.subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    %try
      sendEvent('startPhase.cmd','testing');
      ssepFeedbackStimulus;
    %catch
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.test','end');
    %end
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