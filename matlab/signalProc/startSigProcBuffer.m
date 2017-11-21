function []=startSigProcBuffer(varargin)
% buffer controlled execution of the different signal processing phases.
%
% Trigger events: (type,value)
%  (startPhase.cmd,capfitting) -- show capfitting
%  (startPhase.cmd,eegviewer)  -- show the live signal viewer
%  (startPhase.cmd,erpviewer)  -- show a running event-locked average viewer
%                                 N.B. the event type used to lock to is given in the option:
%                                    erpEventType
%  (startPhase.cmd,calibrate)  -- start calibration phase processing (i.e. concat data)
%                                 Specifically for each epoch the specified block of data will be
%                                 saved and labelled with the value of this event.
%                                 N.B. the event type used to define an epoch is given in the option:
%                                        epochEventType
%  (startPhase.cmd,erpviewcalibrate)  -- start calibration phase processing with simultaneous 
%                                        erp viewing
%  (calibrate,end)             -- end calibration phase
%  (startPhase.cmd,sliceraw)   -- slice data from raw ftoffline save-file to generate traindata/traindevents for classifier training
%  (startPhase.cmd,loadtraining)  -- load previously saved training data from use selected file
%  (startPhase.cmd,cleartraining) -- clear the saved calibration data
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
%   catchPhases/ignorePhases -- {'str'} cell array of phase name to either explicitly catch or ignore.  ([])
%                        if empty then all phases will be caught
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
%   calibrateOpts  -- {cell} addition options to pass to the calibration routine
%                     SEE: buffer_waitData for information on th options available
%   calibrateExtraPhases -- {'str'} list of additional phases which result in the calibration event catcher being called
%   trainOpts      -- {cell} cell array of additional options to pass to the classifier trainer, e.g.
%                       'trainOpts',{'width_ms',1000} % sets the welch-window-width to 1000ms
%                     SEE: buffer_train_clsfr for a list of options available
%   epochFeedbackOpts -- {cell} cell array of additional options to pass to the epoch feedback (i.e. 
%                        event triggered) classifier
%                        SEE: event_applyClsfr for a list of options available
%   contFeedbackOpts  -- {cell} cell array of addition options to pass to the continuous feedback 
%                        (i.e. every n-ms triggered) classifier
%                        SEE: cont_applyClsfr for a list of options available
%   userFeedbackTable -- {3 x L} table of phase names and feedback method and options to use for user-triggered
%                                feedback options.  Format is:
%                          {'PhaseName' 'FeedbackType' feedbackOptions}
%                         where 'phaseName' is the phase name as found in the value of 'startPhase.cmd'
%                               FeedbackType is the type of feedback function to call, i.e. one-of 'epoch' or 'cont'
%                               feedbackOptions is a cell array of options to pass to the feedback-type function
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
opts=struct('label','sigProc','phaseEventType','startPhase.cmd',...
            'catchPhases',[],'ignorePhases',[],'calibrateExtraPhases',{{}},...
				'epochEventType',[],'testepochEventType',[],'sendPredEventType',[],...
            'erpEventType',[],'erpMaxEvents',[],'erpOpts',{{}},...
				'clsfr_type','erp','trlen_ms',1000,'freqband',[],'freqbanderp',[.5 1 12 16],'freqbandersp',[8 10 28 30],...
				'calibrateOpts',{{}},'trainOpts',{{}},...
            'epochPredFilt',[],'epochFeedbackOpts',{{}},...
				'contPredFilt',[],'contFeedbackOpts',{{}},...
				'userFeedbackTable',{{}},...
				'savetestdata',0,... % save data seen during the test phase (i.e. in cont_applyClsfr)
				'capFile',[],...
				'subject','test','verb',1,'buffhost',[],'buffport',[],'timeout_ms',500,...
				'useGUI',1,'cancelError',0);
opts=parseOpts(opts,varargin);
if ( ~iscell(opts.erpOpts) ) opts.erpOpts={opts.erpOpts}; end;
if ( ~iscell(opts.trainOpts))opts.trainOpts={opts.trainOpts}; end;
if ( ~iscell(opts.calibrateExtraPhases) )
  if(isempty(opts.calibrateExtraPhases))opts.calibrateExtraPhases={};else opts.calibrateExtraPhases={opts.calibrateExtraPhases};end;
end

thresh=[.5 3];  badchThresh=.5;   overridechnms=0;
capFile=opts.capFile;
if( isempty(capFile) ) 
  [fn,pth]=uigetfile(fullfile(mdir,'..','../resources/caps/*.txt'),'Pick cap-file'); 
  if ( isequal(fn,0) || isequal(pth,0) ) capFile='1010.txt';  % 1010 default if not selected
  else                                   capFile=fullfile(pth,fn);
  end; 
end
overridechnms=1; % default cap-file is wire->name+position mapping
if ( ~isempty(strfind(capFile,'1010.txt')) || ~isempty(strfind(capFile,'subset')) ) 
    overridechnms=0; % capFile is just position-info / channel-subset selection
end; 
if ( ~isempty(strfind(capFile,'tmsi')) ) thresh=[.0 .1 .2 5]; badchThresh=1e-4; end;

if ( isempty(opts.epochEventType) && opts.useGUI )
     try
	 optsFig=bufferSignalProcOpts();
    %set(optsFig,'title',opts.label);
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
		if ( opts.cancelError ) 
		  error('User cancelled the run');
		else
		  warning('User cancelled the run');
		end
	 end
  end
end
if ( isempty(opts.epochEventType) )     opts.epochEventType='stimulus.target'; end;
if ( isempty(opts.testepochEventType) ) opts.testepochEventType='classifier.apply'; end;
if ( isempty(opts.erpEventType) )       opts.erpEventType=opts.epochEventType; end;
if ( ~isempty(opts.freqband) )          opts.freqbanderp=opts.freqband; opts.freqbandersp=opts.freqband; end;
userPhaseNames={};
if ( ~isempty(opts.userFeedbackTable) )
  userPhaseNames=opts.userFeedbackTable(:,1);
  for upi=1:numel(userPhaseNames); userPhaseNames{upi}=lower(userPhaseNames{upi});end;
end;


datestr = datevec(now); datestr = sprintf('%02d%02d%02d',datestr(1)-2000,datestr(2:3));
dname='training_data'; traindata=[]; traindevents=[];
cname='clsfr';
testname='testing_data';
subject=opts.subject;
rawsavedir='~/output'; if( ispc() ) rawsavedir='C:\output'; end;


if ( exist('OCTAVE_VERSION','builtin') ) 
	 page_output_immediately(1); % prevent buffering output
	 if ( ~isempty(strmatch('qthandles',available_graphics_toolkits())) )
		graphics_toolkit('qthandles'); 
	 elseif ( ~isempty(strmatch('qt',available_graphics_toolkits())) )
		graphics_toolkit('qt'); 
	 elseif ( ~isempty(strmatch('fltk',available_graphics_toolkits())) )
		graphics_toolkit('fltk'); % use fast rendering library
	 end
end

if ( opts.useGUI )
  % create the control window and execute the phase selection loop
  contFig=figure(99); % use figure window number no-one else will use...
  clf;
  set(contFig,'name',sprintf('%s Controller : close to quit',opts.label),'color',[.3 .1 .1]);
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
           '' '';
           'S) Slice ftoffline data'   'sliceraw';
           'L) Load training data'     'loadtraining';
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
    drawnow; pause(.1);
	 if ( ~ishandle(contFig) ) break; end;
  
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
	 if ( ~isempty(phaseToRun) )
		sendEvent(opts.phaseEventType,phaseToRun); phaseToRun=[]; drawnow; pause(.2);
	 end;
  else
	if ( exist('OCTAVE_VERSION','builtin') ) pause(.1); end;
  drawnow;
  end

  % wait for a phase control event
  if ( opts.verb>0 ) fprintf('%d) Waiting for phase command\n',nsamples); end;
  [devents,state,nevents,nsamples]=buffer_newevents(opts.buffhost,opts.buffport,state,...
																	 {opts.phaseEventType 'subject' 'sigproc.*'},[],opts.timeout_ms);
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
    elseif ( strcmp(devents(di).type,'sigproc.reset') )
           ; % ignore sig-proc reset
    elseif ( strncmp(devents(di).type,'sigproc.',numel('sigproc.')) ) % start phase command
      if ( strcmp(devents(di).value,'start') ) 
        phaseToRun=devents(di).type(numel('sigproc.')+1:end);
      end
    else
      phaseToRun=devents(di).value;
      break;
    end  
  end
                              % only phases we should process are caught here
  % TODO: filter the menustr also...
  catchPhase=true; % default to process everything
  if ( ~isempty(opts.ignorePhases)) catchPhase=~any(strcmpi(phaseToRun,opts.ignorePhases)); end; % override if specific ignore given
  if ( ~isempty(opts.catchPhases) ) % override if specific catch given
    catchPhase= any(strcmpi(phaseToRun,opts.catchPhases)) | any(strcmpi(phaseToRun,{'quit' 'exit'}));
  end;
  if ( ~catchPhase  )
    fprintf('%d) Ignoring non-caught phase: %s\n',devents(di).sample,phaseToRun);
    phaseToRun=[];
  end
  
  if ( isempty(phaseToRun) ) continue; end;

  fprintf('%d) Starting phase : %s\n',devents(di).sample,phaseToRun);
  if ( opts.verb>0 ) ptime=getwTime(); end;
  % hide controller window while the phase is actually running
  if ( opts.useGUI && ishandle(contFig) ) set(contFig,'visible','off'); end;
  
  sendEvent(['sigproc.' lower(phaseToRun)],'ack'); % ack-start cmd recieved
  switch lower(phaseToRun);
    
    %---------------------------------------------------------------------------------
   case 'capfitting';
    capFitting('buffhost',opts.buffhost,'buffport',opts.buffport,'noiseThresholds',thresh,'badChThreshold',badchThresh,'verb',opts.verb,'showOffset',0,'capFile',capFile,'overridechnms',overridechnms);

    %---------------------------------------------------------------------------------
   case {'eegviewer','sigViewer'};
    sigViewer(opts.buffhost,opts.buffport,'capFile',capFile,'overridechnms',overridechnms);
    
    %---------------------------------------------------------------------------------
   case {'erspvis','erpvis','erpviewer','erpvisptb'};
     erpViewer(opts.buffhost,opts.buffport,'capFile',capFile,'overridechnms',overridechnms,'cuePrefix',opts.erpEventType,'endType',{lower(phaseToRun) 'sigproc.reset'},'trlen_ms',opts.trlen_ms,'freqbands',[.0 .3 45 47],'maxEvents',opts.erpMaxEvents,opts.erpOpts{:});

   %---------------------------------------------------------------------------------
   case {'erpviewcalibrate','erpviewercalibrate','calibrateerp'};
    [traindata,traindevents]=erpViewer(opts.buffhost,opts.buffport,'capFile',capFile,'overridechnms',overridechnms,'cuePrefix',opts.erpEventType,'endType',{{lower(phaseToRun) 'calibrate' 'sigproc.reset'} 'end'},'trlen_ms',opts.trlen_ms,'freqbands',[.0 .3 45 47],'maxEvents',opts.erpMaxEvents,opts.erpOpts{:});
    mi=matchEvents(traindevents,{'calibrate' 'calibration'},'end'); traindevents(mi)=[]; traindata(mi)=[];%remove exit event
    fname=[dname '_' subject '_' datestr];
    fprintf('Saving %d epochs to : %s\n',numel(traindevents),fname);
	save([fname '.mat'],'traindata','traindevents','hdr');
    trainSubj=subject;
    fprintf('Saved %d epochs to : %s\n',numel(traindevents),fname);
	 
   %---------------------------------------------------------------------------------
   case {'calibrate','calibration',opts.calibrateExtraPhases{:}};
    [ntraindata,ntraindevents,state]=buffer_waitData(opts.buffhost,opts.buffport,[],'startSet',opts.epochEventType,'exitSet',{{'calibrate' 'calibration' 'sigproc.reset' phaseToRun ['sigproc.' phaseToRun]} 'end'},'verb',opts.verb,'trlen_ms',opts.trlen_ms,opts.calibrateOpts{:});
    mi=matchEvents(ntraindevents,{'calibrate' 'calibration' 'sigproc.reset' phaseToRun ['sigproc.' phaseToRun]},'end'); ntraindevents(mi)=[]; ntraindata(mi)=[];%remove exit event
    if(isempty(traindata))
      traindata=ntraindata;                  traindevents=ntraindevents;
    elseif( ~isempty(ntraindevents) && numel(ntraindata)>0 )
      dsz=size(traindata(1).buf);
      consistent=true;
      for ei=1:numel(ntraindata);
        dszei=size(ntraindata(1).buf);
        if(~isequal(dszei,dsz))
          fprintf('Warning:: data sizes are inconsistent!!!  [%s]~=[%s]\n',sprintf('%d ',dsz),sprintf('%d ',dszei));
          consistent=false;
          break;
        end
      end
      if( consistent )
        traindata=cat(1,traindata,ntraindata); traindevents=cat(1,traindevents,ntraindevents);
      else
        traindata=ntraindata;  traindevents=ntraindevents;
      end
    end
    fname=[dname '_' subject '_' datestr];
    fprintf('Saving %d epochs to : %s\n',numel(traindevents),fname);save([fname '.mat'],'traindata','traindevents','hdr');
    trainSubj=subject;
    fprintf('Saved %d epochs to : %s\n',numel(traindevents),fname);

    %---------------------------------------------------------------------------------
   case {'sliceraw'};
     % extract training data for classifier from previously saved raw ftoffline save file
       [fn,datadir]=uigetfile('header','Pick ftoffline raw savefile header file.'); drawnow;
       try
		                  % slice the saved data-file to load the training data
		   [traindata,traindevents,hdr,allevents]=sliceraw(datadir,'startSet',opts.epochEventType,'trlen_ms',opts.trlen_ms,opts.calibrateOpts{:});
         fprintf('Sliced %d epochs from : %s\n',numel(traindevents),fullfile(datadir,'header'));
         % save the sliced data (like it was on-line)
         fname=[dname '_' subject '_' datestr];
         fprintf('Saving %d epochs to : %s\n',numel(traindevents),fname);save([fname '.mat'],'traindata','traindevents','hdr','allevents');
         trainSubj=subject; % mark this this data is valid for classifier training
       catch
         fprintf('Error in : %s',phaseToRun);
         le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	   if ( ~isempty(le.stack) )
	  	     for i=1:numel(le.stack);
	  		    fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	     end;
	  	   end
	  	   msgbox({sprintf('Error in : %s',phaseToRun) 'OK to continue!'},'Error');
       end
       
    %---------------------------------------------------------------------------------
   case {'loadtraining'};
     % load training data from previously saved training data file
     [fn,pth]=uigetfile([dname '*.mat'],'Pick training data file'); drawnow;
	  if ( ~isequal(fn,0) ); fname=fullfile(pth,fn); end; 
     if ( ~(exist([fname '.mat'],'file') || exist(fname,'file')) ) 
       warning(['Couldnt find a training data file to load file: ' fname]);
       continue;
     else
       fprintf('Loading training data from : %s\n',fname);
     end
     chdr=hdr;
     load(fname);

                                % save the loaded data (like it was on-line)
     fname=[dname '_' subject '_' datestr];
     fprintf('Saving %d epochs to : %s\n',numel(traindevents),fname);save([fname '.mat'],'traindata','traindevents','hdr');
     trainSubj=subject; % mark this this data is valid for classifier training
    fprintf('Saved %d epochs to : %s\n',numel(traindevents),fname);
     
     if( ~isempty(chdr) ) hdr=chdr; end;
     trainSubj=subject;

    %---------------------------------------------------------------------------------
   case {'cleartraining'};
     traindata=[]; traindevents=[];
     
    %---------------------------------------------------------------------------------
   case {'train','training','trainerp','trainersp','train_subset','trainerp_subset','trainersp_subset','train_useropts','trainerp_useropts','trainersp_useropts'};
     %try     
     if ( ~isequal(trainSubj,subject) || ~exist('traindata','var') ) 
       fname=[dname '_' subject '_' datestr];
       if ( ~(exist([fname '.mat'],'file') || exist(fname,'file')) ) 
         warning(['Couldnt find a training data file to load file: ' fname]);
         % Not in default name -- ask user for file to load?
         [fn,pth]=uigetfile([dname '*.mat'],'Pick training data file'); drawnow;
	      if ( ~isequal(fn,0) );
           fname=fullfile(pth,fn);
         else
           continue;
         end; 
       else
         fprintf('Loading training data from : %s\n',fname);
       end
       chdr=hdr;
       load(fname); 
       if( ~isempty(chdr) ) hdr=chdr; end;
       trainSubj=subject;
      end;
      if ( opts.verb>0 ) fprintf('%d epochs\n',numel(traindevents)); end;
		
		% get type of classifier to train.
		clsfr_type=opts.clsfr_type;
		% phase command name overrides option if given
		if ( ~isempty(strfind(phaseToRun,'trainerp')) ) clsfr_type='erp';
		elseif ( ~isempty(strfind(phaseToRun,'trainersp')) ) clsfr_type='ersp';
		end

										% get any additional user specified input arguments if needed
		userOpts={};
		if ( ~isempty(strfind(phaseToRun,'subset')) )
		  if( ischar(traindevents(1).value) ) % string values
			 clsnms = unique({traindevents.value});
		  else % numeric values
			 tmp = unique([traindevents.value]);
			 clsnms={}; for i=1:numel(tmp); clsnms{i}=sprintf(tmp(i)); end;
		  end		  
		  userOpts = inputdlg(sprintf('Enter the sub-set of classes to train with:\nNote: available classes=%s',sprintf('%s,',clsnms{:})),'Specify subset of classes to use as: ''c1'',''c2'',''c3'',... ',2);
		  try;
          tgtClss =eval(['{' userOpts{:} '}']);
		  catch;
			 warning('invlald set of user options, ignored');
			 continue;
		  end
		  % build the spType spec for 1vR from the list of classes
		  spType={};
		  if ( numel(tgtClss)==2 ) 
			 spType=tgtClss;		  % binary special case = 1 sub-problem
		  else
			 for ci=1:numel(tgtClss); spType{ci} = {tgtClss{ci} tgtClss([1:ci-1 ci+1:end])}; end
		  end
		  userOpts={'spMx',spType}; % set the options up
		  
		elseif ( ~isempty(strfind(phaseToRun,'useropts')) )
		  userOpts= inputdlg('Enter additional options for the classifier training\nas valid eval-string','Enter user options');
		  try
			 userOpts=eval(userOpts);
		  catch;
			 warning('invlald set of user options, ignored');
			 continue;
		  end
		end
		
      switch lower(clsfr_type);
       
        case {'erp','evoked'};
         [clsfr,res]=buffer_train_erp_clsfr(traindata,traindevents,hdr,'spatialfilter','car',...
                    'freqband',opts.freqbanderp,'badchrm',1,'badtrrm',1,...
						  'capFile',capFile,'overridechnms',overridechnms,'verb',opts.verb,...
						  opts.trainOpts{:},userOpts{:});
       
       case {'ersp','induced'};
         [clsfr,res]=buffer_train_ersp_clsfr(traindata,traindevents,hdr,'spatialfilter','car',...
						   'freqband',opts.freqbandersp,'badchrm',1,'badtrrm',1,...
							'capFile',capFile,'overridechnms',overridechnms,'verb',opts.verb,...
							opts.trainOpts{:},userOpts{:});
       
       otherwise;
        error('Unrecognised classifer type');
      end
      clsSubj=subject;
      fname=[cname '_' subject '_' datestr];
      fprintf('Saving classifier to : %s\n',fname);save([fname '.mat'],'-struct','clsfr');
	%catch
      % fprintf('Error in : %s',phaseToRun);
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	% if ( ~isempty(le.stack) )
	  	%   for i=1:numel(le.stack);
	  	% 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	%   end;
	  	% end
	  	% msgbox({sprintf('Error in : %s',phaseToRun) 'OK to continue!'},'Error');
      % sendEvent('training','end');    
    %end
    sendEvent(lower(phaseToRun),'end'); % indicate command finished

    %---------------------------------------------------------------------------------
   case {'test','testing','epochfeedback','eventfeedback','eventseqfeedback'};
     try % try to load the classifier from file (in case someone else made it for us)
        clsfrfile = [cname '_' subject '_' datestr];
        if ( ~(exist([clsfrfile '.mat'],'file') || exist(clsfrfile,'file')) ) 
           [fn,pth]=uigetfile([cname '*.mat'],'Pick saved classifier file.'); drawnow;
           if ( ~isequal(fn,0) );
              clsfrfile=fullfile(pth,fn);
           else
              continue;
           end;
        end
        if(opts.verb>0)fprintf('Loading classifier from file : %s\n',clsfrfile);end;
        clsfr=load(clsfrfile);
        if( isfield(clsfr,'clsfr') ) clsfr=clsfr.clsfr; end;
        clsSubj = subject;
     catch
        if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) % can't use the clsfr variable
           fprintf('Error in : %s',phaseToRun);
           le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
           if ( ~isempty(le.stack) )
              for i=1:numel(le.stack);
                 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
              end;
           end
           msgbox({sprintf('%s::ERROR loading classifier, %s',phaseToRun,clsfrfile) 'OK to continue!'},'Error');
           sendEvent('testing','end');    
        end
     end;

     if( strcmp(lower(phaseToRun),'eventseqfeedback') ) % run in sequence prediction mode
        [testdata,testevents]=...
            event_applyClsfr(clsfr,'startSet',opts.testepochEventType,...
                             'predFilt',opts.epochPredFilt,...
                             'sendPredEventType',opts.sendPredEventType,...
                            'endType',{'testing','test','epochfeedback','eventfeedback','sigproc.reset'},...
                             'verb',opts.verb,...
                             'trlen_ms',opts.trlen_ms,...%default to trlen_ms data per prediction
                             opts.epochFeedbackOpts{:}); % allow override with epochFeedbackOpts
     else
        [testdata,testevents]=...
            event_applyClsfr(clsfr,'startSet',opts.testepochEventType,...
                             'predFilt',opts.epochPredFilt,...
                            'endType',{'testing','test','epochfeedback','eventfeedback','sigproc.reset'},...
                             'verb',opts.verb,...
                             'trlen_ms',opts.trlen_ms,...%default to trlen_ms data per prediction
                             opts.epochFeedbackOpts{:}); % allow override with epochFeedbackOpts
     end
% 	  catch
%        fprintf('Error in : %s',phaseToRun);
%        le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
% 	  	if ( ~isempty(le.stack) )
% 	  	  for i=1:numel(le.stack);
% 	  		 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
% 	  	  end;
% 	  	end
%        msgbox({sprintf('Error in : %s',phaseToRun) 'OK to continue!'},'Error');
%        sendEvent('testing','end');    
%      end


   %---------------------------------------------------------------------------------
   case {'contfeedback'};
    try % try to load the classifier from file (in case someone else made it for us)
      clsfrfile = [cname '_' subject '_' datestr];
      if ( ~(exist([clsfrfile '.mat'],'file') || exist(clsfrfile,'file')) ) 
        [fn,pth]=uigetfile([cname '*.mat'],'Pick saved classifier file.'); drawnow;
	      if ( ~isequal(fn,0) );
           clsfrfile=fullfile(pth,fn);
         else
           continue;
         end;
      end
      if(opts.verb>0)fprintf('Loading classifier from file : %s\n',clsfrfile);end;
      clsfr=load(clsfrfile);
      if( isfield(clsfr,'clsfr') ) clsfr=clsfr.clsfr; end;
      clsSubj = subject;
	 catch
		if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) % can't use the clsfr variable
		  fprintf('Error in : %s',phaseToRun);
        le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
		  if ( ~isempty(le.stack) )
			 for i=1:numel(le.stack);
				fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
			 end;
		  end
        msgbox({sprintf('%s::ERROR loading classifier, %s',phaseToRun,clsfrfile) 'OK to continue!'},'Error');
        sendEvent('testing','end');    
		end;
	 end

    if ( ~any(strcmpi(clsfr.type,{'ersp','induced'})) )
      warning('Trying to use an ERP classifier in continuous application mode.\nAre you sure?');
    end
	 try		
	 % generate prediction every trlen_ms/2 seconds using trlen_ms data
	 if ( ~opts.savetestdata )
		cont_applyClsfr(clsfr,...
							 'endType',{'testing','test','contfeedback','sigproc.reset'},...
							 'predFilt',opts.contPredFilt,'verb',opts.verb,...
							 'trlen_ms',opts.trlen_ms,'overlap',.5,... %default to predict every trlen_ms/2 ms
							 opts.contFeedbackOpts{:}); % but override with contFeedbackOpts
	 else
		[testdata,testdevents]=...
		cont_applyClsfr(clsfr,...
							 'endType',{'testing','test','contfeedback','sigproc.reset'},...
							 'predFilt',opts.contPredFilt,'verb',opts.verb,...
							 'trlen_ms',opts.trlen_ms,'overlap',.5,... %default to predict every trlen_ms/2 ms
							 opts.contFeedbackOpts{:}); % but override with contFeedbackOpts
										  % save to disk and merge with training data
		fname=['testingdata' '_' subject '_' datestr];
		fprintf('Saving %d epochs to : %s\n',numel(testdevents),fname);save([fname '.mat'],'testdata','testdevents','hdr');
		% concatenate with the training data so can re-train with the extended data-set
		if ( ~isempty(traindata) )
		  traindata   =cat(1,traindata,testdata);
		  traindevents=cat(1,traindevents,testdevents);
		else
		  traindata   =testdata;
		  traindevents=testdevents;
		end
	 end
	catch
      fprintf('Error in : %s',phaseToRun);
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
		if ( ~isempty(le.stack) )
		  for i=1:numel(le.stack);
			 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
		  end;
		end
      msgbox({sprintf('Error in : %s',phaseToRun) 'OK to continue!'},'Error');
      sendEvent('testing','end');    
    end


   %---------------------------------------------------------------------------------
   case userPhaseNames;
	  phasei = find(strcmp(lower(phaseToRun),userPhaseNames));
     %try
		 if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) 
			clsfrfile = [cname '_' subject '_' datestr];
         if ( ~(exist([clsfrfile '.mat'],'file') || exist(clsfrfile,'file')) ) 
           [fn,pth]=uigetfile({[cname '*.mat']},'Pick saved classifier file.'); drawnow;
	        if ( ~isequal(fn,0) );
             clsfrfile=fullfile(pth,fn);
           else
             continue;
           end;
         end
			if(opts.verb>0)fprintf('Loading classifier from file : %s\n',clsfrfile);end;
			clsfr=load(clsfrfile);
			clsSubj = subject;
		 end;

		 if( any(strcmp(opts.userFeedbackTable{phasei,2},{'event','epoch'})) )		 
			event_applyClsfr(clsfr,'startSet',opts.testepochEventType,...
								  'endType',{'testing','test','epochfeedback','eventfeedback',lower(phaseToRun),'sigproc.reset'},'verb',opts.verb,...
								  'trlen_ms',opts.trlen_ms,...
								  opts.userFeedbackTable{phasei,3}{:});
		 elseif ( any(strcmp(opts.userFeedbackTable{phasei,2},'cont')) )
			cont_applyClsfr(clsfr,...
								 'endType',{'testing','test','contfeedback',lower(phaseToRun),'sigproc.reset'},'verb',opts.verb,...
								 'trlen_ms',opts.trlen_ms,'overlap',.5,... %default to prediction every trlen_ms/2 ms
								 opts.userFeedbackTable{phasei,3}{:}); 			
		 else
			error('UserFeedback apply-method type is unrecognised');
		 end
       sendEvent(lower(phaseToRun),'end'); % indicate command finished
		 
% 	  catch
% 		 fprintf('Error in : %s',phaseToRun);
%       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
% 		if ( ~isempty(le.stack) )
% 		  for i=1:numel(le.stack);
% 			 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
% 		  end;
% 		end
%       msgbox({sprintf('Error in : %s',phaseToRun) 'OK to continue!'},'Error');
%       sendEvent('testing','end');    
%     end
	 
   case {'quit','exit'};
    break;
    
   otherwise;
	  
    warning(sprintf('Unrecognised experiment phase ignored! : %s',phaseToRun));
    
  end
  if ( opts.verb>0 ) fprintf('Finished : %s @ %5.3fs\n',phaseToRun,getwTime()-ptime); end;
  sendEvent(['sigproc.' lower(phaseToRun)],'end');    
  % show GUI again when phase has completed
  if ( opts.useGUI && ishandle(contFig) ) set(contFig,'visible','on'); end;
  
end
