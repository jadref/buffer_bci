function []=startSigProcBuffer(varargin)
% buffer controlled execution of the different signal processing phases.
%
% Trigger events: (type,value)
%  (startPhase.cmd,capfitting) -- show capfitting
%  (startPhase.cmd,eegviewer)  -- show the live signal viewer
%  (startPhase.cmd,erpviewer)  -- show a running event-locked average viewer
%                                 N.B. the event type used to lock to is given in the option:
%                                    erpEventType
%  (startPhase.cmd,calibrate)  -- start calibration phase processing (i.e. cat data)
%                                 Specifically for each epoch the specified block of data will be
%                                 saved and labelled with the value of this event.
%                                 N.B. the event type used to define an epoch is given in the option:
%                                        epochEventType
%  (startPhase.cmd,erpviewcalibrate)  -- start calibration phase processing with simultaneous 
%                                        erp viewing
%  (calibrate,end)             -- end calibration phase
%  (startPhase.cmd,train)      -- train a classifier based on the saved calibration data
%  (startPhase.cmd,trainerp)   -- train a classifier based on the saved calibration data - force ERP (time-domain) classifier
%  (startPhase.cmd,trainersp)  -- train a classifier based on the saved calibration data - force ERsP (frequency-domain) classifier
%  (startPhase.cmd,testing)    -- start test phase, i.e. on-line prediction generation
%                                 This type of testing will generate 1 prediction event for each 
%                                 epoch event.  
%                                 NB. The event to predict for is given in option: testepochEventType
%                                  (FYI: this uses the function event_applyClsfr)
%  (startPhase.cmd,contfeedback) -- start continuous feedback phase,
%                                     i.e. prediction event generated every trlen_ms/2 milliseconds
%                                  (FYI: this uses the function cont_applyClsfr)
%  (testing,end)               -- end testing phase
%  (startPhase.cmd,exit)       -- stop everything
%
% Prediction Events
%  During the testing phase the classifier will send predictions with the type
%  (classifier.prediction,val)  -- classifier prediction events.  
%                                 val is the classifier decision value where 
%                                      <0 = negative class, >0 = positive class
%
%  []=startSigProcBuffer(varargin)
%
% Options:
%   phaseEventType -- 'str' event type which says start a new phase                 ('startPhase.cmd')
%   epochEventType -- 'str' event type which indicates start of calibration epoch.  ('stimulus.target')
%                     This event's value is used as the class label
%   testepochEventType -- 'str' event type which start of data to generate a prediction for.  ('classifier.apply')
%   clsfr_type     -- 'str' the type of classifier to train.  One of: 
%                        'erp'  - train a time-locked response (evoked response) classifier
%                        'ersp' - train a power change (induced response) classifier
%   trlen_ms       -- [int] trial length in milliseconds.  This much data after each  (1000)
%                     epochEvent saved to train the classifier
%   freqband       -- [float 4x1] frequency band to use the the spectral filter during ([.1 .5 10 12])
%                     pre-processing
%
%   erpOpts        -- {cell} cell array of additional options to pass the the erpViewer
%                     SEE: erpViewer for a list of options available
%   trainOpts      -- {cell} cell array of additional options to pass to the classifier trainer, e.g.
%                       'trainOpts',{'width_ms',1000} % sets the welch-window-width to 1000ms
%                     SEE: buffer_train_clsfr for a list of options available
%   epochFeedbackOpts -- {cell} cell array of additional options to pass to the epoch feedback (i.e. 
%                        event triggered) classifier
%                        SEE: event_applyClsfr for a list of options available
%   contFeedbackOpts  -- {cell} cell array of addition options to pass to the continuous feedback 
%                        (i.e. every n-ms triggered) classifier
%                        SEE: cont_applyClsfr for a list of options available   
%
%   capFile        -- [str] filename for the channel positions                         ('1010')
%   verb           -- [int] verbosity level                                            (1)
%   buffhost       -- str, host name on which ft-buffer is running                     ('localhost')
%   buffport       -- int, port number on which ft-buffer is running                   (1972)
%   epochPredFilt  -- [float/str/function_handle] prediction filter for smoothing the 
%                      epoch output classifier.
%   contPredFilt   -- [float/str/function_handle] prediction filter for smoothing the continuous
%                      output classifier.  Defined as for the cont_applyClsfr argument ([])
%                     predFilt=[] - no filtering 
%                     predFilt>=0 - coefficient for exp-decay moving average. f=predFilt*f + (1-predFilt)f_new
%                                N.B. predFilt = exp(log(.5)/halflife)
%                     predFilt<0  - #components to average                    f=mean(f(:,end-predFilt:end),2)
% 
% Examples:
%   startSigProcBuffer(); % run with standard parameters using the GUI to get more info.
%
%  % Run where epoch is any of row/col or target flash and saving 600ms after these events for classifier training
%   startSigProcBuffer('epochEventType',{'stimulus.target','stimulus.rowFlash','stimulus.colFlash'},'trlen_ms',600); 
%  % Run where epoch is target flash and saving 600ms after these events for classifier training
%  %   in testing phase, we generate a prediction for every row/col flash
%   startSigProcBuffer('epochEventType',{'stimulus.target'},'testepochEventType',{'stimulus.rowFlash','stimulus.colFlash'},'trlen_ms',600); 

% setup the paths if needed
wb=which('buffer'); 
mdir=fileparts(mfilename('fullpath'));
if ( isempty(wb) || isempty(strfind('dataAcq',wb)) ) 
  run(fullfile(mdir,'../utilities/initPaths.m')); 
  % set the real-time-clock to use
  initgetwTime;
  initsleepSec;
end;
opts=struct('phaseEventType','startPhase.cmd',...
				'epochEventType',[],'testepochEventType',[],...
            'erpEventType',[],'erpMaxEvents',[],'erpOpts',{{}},...
				'clsfr_type','erp','trlen_ms',1000,'freqband',[.1 .5 10 12],...
				'trainOpts',{{}},...
            'epochPredFilt',[],'epochFeedbackOpts',{{}},...
				'contPredFilt',[],'contFeedbackOpts',{{}},...
				'capFile',[],...
				'subject','test','verb',1,'buffhost',[],'buffport',[],'useGUI',1,'timeout_ms',500);
opts=parseOpts(opts,varargin);
if ( ~iscell(opts.erpOpts) ) opts.erpOpts={opts.erpOpts}; end;
if ( ~iscell(opts.trainOpts))opts.trainOpts={opts.trainOpts}; end;

thresh=[.5 3];  badchThresh=.5;   overridechnms=0;
capFile=opts.capFile;
if( isempty(capFile) ) 
  [fn,pth]=uigetfile(fullfile(mdir,'../utilities/caps/*.txt'),'Pick cap-file'); 
  if ( isequal(fn,0) || isequal(pth,0) ) capFile='1010.txt'; 
  else                                   capFile=fullfile(pth,fn);
  end; % 1010 default if not selected
end
if ( ~isempty(strfind(capFile,'1010.txt')) ) overridechnms=0; else overridechnms=1; end; % force default override
if ( ~isempty(strfind(capFile,'tmsi')) ) thresh=[.0 .1 .2 5]; badchThresh=1e-4; end;

if ( isempty(opts.epochEventType) && opts.useGUI )
  try
	 optsFig=bufferSignalProcOpts();
  catch
	 optsFig=[];
  end
  if ( ~isempty(optsFig) && ishandle(optsFig) ) 
	 uiwait(optsFig); 
	 info=guidata(optsFig);
	 if ( info.ok )
		% use the input for the options names
		fn=fieldnames(info.opts); for fi=1:numel(fn); opts.(fn{fi})=info.opts.(fn{fi}); end;
		% add additional information to the freqbands arguments
		if ( opts.freqband(1)<0 ) opts.freqband(1)=max(0,opts.freqband(2)-1); end;
		if ( opts.freqband(2)<0 ) opts.freqband(2)=max(8,opts.freqband(1)+1); end;
		if ( opts.freqband(3)<0 ) opts.freqband(3)=max(28,opts.freqband(2)+10); end;
		if ( opts.freqband(4)<0 ) opts.freqband(4)=min(inf,opts.freqband(3)+1); end;    
	 else
		error('User cancelled the run');
	 end
  end
end
if ( isempty(opts.epochEventType) )     opts.epochEventType='stimulus.target'; end;
if ( isempty(opts.testepochEventType) ) opts.testepochEventType='classifier.apply'; end;
if ( isempty(opts.erpEventType) )       opts.erpEventType=opts.epochEventType; end;

datestr = datevec(now); datestr = sprintf('%02d%02d%02d',datestr(1)-2000,datestr(2:3));
dname='training_data';
cname='clsfr';
testname='testing_data';
subject=opts.subject;

if ( opts.useGUI )
  % create the control window and execute the phase selection loop
  contFig=figure(99); % use figure window number no-one else will use...
  clf;
  set(contFig,'name','Signal Processing Controller : close to quit','color',[.3 .1 .1]);
  axes('position',[0 0 1 1],'visible','off','xlim',[0 1],'ylim',[0 1],'nextplot','add');
  set(contFig,'Units','pixel');wSize=get(contFig,'position');
  fontSize = .05*wSize(4);
  txth=text(.25,.5,{'Waiting for buffer server and data...'},'fontunits','pixel','fontsize',.05*wSize(4),...
				'HorizontalAlignment','left','color',[1 1 1]);
end

% wait for the buffer to return valid header information
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
  try 
    hdr=buffer('get_hdr',[],opts.buffhost,opts.buffport); 
  catch
    hdr=[];
    fprintf('Invalid header info... waiting.\n');
  end;
  pause(1);
end;


if ( opts.useGUI )
  %        Instruct String            Phase-name
  menustr={'0) capfitting'             'capfitting';
           '1) eegviewer'              'eegviewer';
			  '2) Calibrate + ERP Viewer' 'erpviewcalibrate'; 
           '4) Train ERP Classifier'   'trainerp';
           '5) Train ERsP Classifier'  'trainersp';
			  '6) Epoch Feedback'         'epochfeedback';
			  '7) Continuous Feedback'    'contfeedback';
			  'q) exit'                   'quit';
          };
  set(txth,'string',menustr(:,1));
  % BODGE: point to move around to update the plot to force key processing in OCTAVE
  ph=[]; if ( exist('OCTAVE_VERSION','builtin') ) ph=plot(1,0,'k'); end
  % install listener for key-press mode change
  set(contFig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
  set(contFig,'userdata',[]);
  drawnow; % make sure the figure is visible
end

% main loop waiting for commands and then executing them
nevents=hdr.nEvents; nsamples=hdr.nsamples;
state=struct('nevents',nevents,'nsamples',nsamples); 
phaseToRun=[]; clsSubj=[]; trainSubj=[];
while ( true )

  if ( ~isempty(phaseToRun) ) state=[]; end

  if ( opts.useGUI ) % update the key-control window
    % BODGE: move point to force key-processing
    if ( ~isempty(ph) ) fprintf('.');set(ph,'ydata',rand(1)*.01); end;
	 if ( ~ishandle(contFig) ) break; end;
    drawnow; pause(.1);
  
	 % process any key-presses, and convert to phase-control events
	 phaseToRun=[];
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
										  % and convert to phase control events
	 if ( ~isempty(phaseToRun) ) sendEvent(opts.phaseEventType,phaseToRun); phaseToRun=[]; drawnow; pause(1); end;
  else
	 drawnow;
  end

  % wait for a phase control event
  if ( opts.verb>0 ) fprintf('%d) Waiting for phase command\n',nsamples); end;
  [devents,state,nevents,nsamples]=buffer_newevents(opts.buffhost,opts.buffport,state,...
																	 {opts.phaseEventType 'subject'},[],opts.timeout_ms);
  if ( numel(devents)==0 ) 
    continue;
  elseif ( numel(devents)>1 ) 
    % ensure events are processed in *temporal* order
    [ans,eventsorder]=sort([devents.sample],'ascend');
    devents=devents(eventsorder);
  end
  if ( opts.verb>0 ) fprintf('Got Event: %s\n',ev2str(devents)); end;
  
  % process any new buffer events
  phaseToRun=[];
  for di=1:numel(devents);
    % extract the subject info
    if ( strcmp(devents(di).type,'subject') )     
      subject=devents(di).value; 
      if ( opts.verb>0 ) fprintf('Setting subject to : %s\n',subject); end;
      continue; 
    else
      phaseToRun=devents(di).value;
      break;
    end  
  end
  if ( isempty(phaseToRun) ) continue; end;

  fprintf('%d) Starting phase : %s\n',devents(di).sample,phaseToRun);
  if ( opts.verb>0 ) ptime=getwTime(); end;
  sendEvent(lower(phaseToRun),'start'); % mark start/end testing
  % hide controller window while the phase is actually running
  if ( opts.useGUI && ishandle(contFig) ) set(contFig,'visible','off'); end;
  
  switch lower(phaseToRun);
    
    %---------------------------------------------------------------------------------
   case 'capfitting';
    capFitting('buffhost',opts.buffhost,'buffport',opts.buffport,'noiseThresholds',thresh,'badChThreshold',badchThresh,'verb',opts.verb,'showOffset',0,'capFile',capFile,'overridechnms',overridechnms);

    %---------------------------------------------------------------------------------
   case {'eegviewer','sigViewer'};
    eegViewer(opts.buffhost,opts.buffport,'capFile',capFile,'overridechnms',overridechnms);
    
    %---------------------------------------------------------------------------------
   case {'erspvis','erpvis','erpviewer','erpvisptb'};
    erpViewer(opts.buffhost,opts.buffport,'capFile',capFile,'overridechnms',overridechnms,'cuePrefix',opts.erpEventType,'endType',lower(phaseToRun),'trlen_ms',opts.trlen_ms,'freqbands',[.0 .3 45 47],'maxEvents',opts.erpMaxEvents,opts.erpOpts{:});

   %---------------------------------------------------------------------------------
   case {'erpviewcalibrate','erpviewercalibrate','calibrateerp'};
    [traindata,traindevents]=erpViewer(opts.buffhost,opts.buffport,'capFile',capFile,'overridechnms',overridechnms,'cuePrefix',opts.erpEventType,'endType',{{lower(phaseToRun) 'calibrate'} 'end'},'trlen_ms',opts.trlen_ms,'freqbands',[.0 .3 45 47],'maxEvents',opts.erpMaxEvents,opts.erpOpts{:});
    mi=matchEvents(traindevents,{'calibrate' 'calibration'},'end'); traindevents(mi)=[]; traindata(mi)=[];%remove exit event
    fname=[dname '_' subject '_' datestr];
    fprintf('Saving %d epochs to : %s\n',numel(traindevents),fname);save([fname '.mat'],'traindata','traindevents','hdr');
    trainSubj=subject;
	 
   %---------------------------------------------------------------------------------
   case {'calibrate','calibration'};
    [traindata,traindevents,state]=buffer_waitData(opts.buffhost,opts.buffport,[],'startSet',opts.epochEventType,'exitSet',{{'calibrate' 'calibration'} 'end'},'verb',opts.verb,'trlen_ms',opts.trlen_ms);
    mi=matchEvents(traindevents,{'calibrate' 'calibration'},'end'); traindevents(mi)=[]; traindata(mi)=[];%remove exit event
    fname=[dname '_' subject '_' datestr];
    fprintf('Saving %d epochs to : %s\n',numel(traindevents),fname);save([fname '.mat'],'traindata','traindevents','hdr');
    trainSubj=subject;

    %---------------------------------------------------------------------------------
   case {'train','training','trainerp','trainersp'};
    try
      if ( ~isequal(trainSubj,subject) || ~exist('traindata','var') )
        fname=[dname '_' subject '_' datestr];
        fprintf('Loading training data from : %s\n',fname);
        if ( ~(exist([fname '.mat'],'file') || exist(fname,'file')) ) 
          warning(['Couldnt find a classifier to load file: ' fname]);
          break;
        end
        load(fname); 
        trainSubj=subject;
      end;
      if ( opts.verb>0 ) fprintf('%d epochs\n',numel(traindevents)); end;
		
		% get type of classifier to train.
		clsfr_type=opts.clsfr_type;
		% phase command name overrides option if given
		if ( strcmp(phaseToRun,'trainerp') ) clsfr_type='erp';
		elseif ( strcmp(phaseToRun,'trainersp') ) clsfr_type='ersp';
		end

      switch lower(clsfr_type);
       
       case {'erp','evoked'};
         [clsfr,res]=buffer_train_erp_clsfr(traindata,traindevents,hdr,'spatialfilter','car',...
                    'freqband',opts.freqband,'badchrm',1,'badtrrm',1,...
						  'capFile',capFile,'overridechnms',overridechnms,'verb',opts.verb,...
						  opts.trainOpts{:});
       
       case {'ersp','induced'};
         [clsfr,res]=buffer_train_ersp_clsfr(traindata,traindevents,hdr,'spatialfilter','car',...
						   'freqband',opts.freqband,'badchrm',1,'badtrrm',1,...
							'capFile',capFile,'overridechnms',overridechnms,'verb',opts.verb,...
							opts.trainOpts{:});
       
       otherwise;
        error('Unrecognised classifer type');
      end
      clsSubj=subject;
      fname=[cname '_' subject '_' datestr];
      fprintf('Saving classifier to : %s\n',fname);save([fname '.mat'],'-struct','clsfr');
	catch
      msgbox({sprintf('Error in : %s',phaseToRun) 'OK to continue!'},'Error');
	  fprintf('Error in : %s',phaseToRun);
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  if ( ~isempty(le.stack) ) fprintf('%s>%s : %d',le.stack(1).file,le.stack(1).name,le.stack(1).line);end
      sendEvent('training','end');    
    end

    %---------------------------------------------------------------------------------
   case {'test','testing','epochfeedback','eventfeedback'};
    try
    if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) 
      clsfrfile = [cname '_' subject '_' datestr];
      if ( ~(exist([clsfrfile '.mat'],'file') || exist(clsfrfile,'file')) ) 
		  clsfrfile=[cname '_' subject]; 
	  end;
      if(opts.verb>0)fprintf('Loading classifier from file : %s\n',clsfrfile);end;
      clsfr=load(clsfrfile);
      clsSubj = subject;
    end;

    event_applyClsfr(clsfr,'startSet',opts.testepochEventType,...
							'predFilt',opts.epochPredFilt,...
							'endType',{'testing','test','epochfeedback','eventfeedback'},'verb',opts.verb,...
							opts.epochFeedbackOpts{:});
	 catch
      msgbox({sprintf('Error in : %s',phaseToRun) 'OK to continue!'},'Error');
      fprintf('Error in : %s',phaseToRun);
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  if ( ~isempty(le.stack) ) fprintf('%s>%s : %d',le.stack(1).file,le.stack(1).name,le.stack(1).line);end
      sendEvent('training','end');    
    end

   %---------------------------------------------------------------------------------
   case {'contfeedback'};
    try
    if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) 
      clsfrfile = [cname '_' subject '_' datestr];
      if ( ~(exist([clsfrfile '.mat'],'file') || exist(clsfrfile,'file')) ) 
		  clsfrfile=[cname '_' subject]; 
		end;
      if(opts.verb>0)fprintf('Loading classifier from file : %s\n',clsfrfile);end;
      clsfr=load(clsfrfile);
      clsSubj = subject;
    end;

    if ( ~any(strcmp(lower(opts.clsfr_type),{'ersp','induced'})) )
      warning('Trying to use an ERP classifier in continuous application mode.\nAre you sure?');
    end
	 % generate prediction every trlen_ms/2 seconds using trlen_ms data
    cont_applyClsfr(clsfr,'trlen_ms',opts.trlen_ms,'overlap',.5,...
						  'endType',{'testing','test','contfeedback'},...
						  'predFilt',opts.contPredFilt,'verb',opts.verb,...
						  opts.contFeedbackOpts{:});
    catch
      msgbox({sprintf('Error in : %s',phaseToRun) 'OK to continue!'},'Error');
      fprintf('Error in : %s',phaseToRun);
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
		if(~isempty(le.stack))fprintf('%s>%s : %d',le.stack(1).file,le.stack(1).name,le.stack(1).line);end
      sendEvent('training','end');    
    end
      
   case {'quit','exit'};
    break;
    
   otherwise;
    warning(sprintf('Unrecognised experiment phase ignored! : %s',phaseToRun));
    
  end
  if ( opts.verb>0 ) fprintf('Finished : %s @ %5.3fs\n',phaseToRun,getwTime()-ptime); end;
  sendEvent(lower(phaseToRun),'end');    
  % show GUI again when phase has completed
  if ( opts.useGUI && ishandle(contFig) ) set(contFig,'visible','on'); end;
  
end
