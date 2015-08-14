function []=startSigProcBuffer(varargin)
% buffer controlled execution of the different signal processing phases.
%
% Trigger events: (type,value)
%  (startPhase.cmd,capfitting) -- show capfitting
%  (startPhase.cmd,calibrate)  -- start calibration phase processing (i.e. cat data)
%  (calibrate,end)             -- end calibration phase
%  (startPhase.cmd,train)      -- train a classifier based on the saved calibration data
%  (startPhase.cmd,testing)    -- start test phase, i.e. on-line prediction generation
%                                 This type of testing will generate 1 prediction event for each epoch
%                                  (FYI: this uses the function event_applyClsfr)
%  (startPhase.cmd,contfeedback) -- start continuous feedback phase,
%                                     i.e. prediciton event generated every trlen_ms/2 milliseconds
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
%   epochEventType -- 'str' event type which indicates start of calibration epoch.  ('stimulus.target')
%                     This event's value is used as the class label
%   clsfr_type     -- 'str' the type of classifier to train.  One of: 
%                        'erp'  - train a time-locked response (evoked response) classifier
%                        'ersp' - train a power change (induced response) classifier
%   trlen_ms       -- [int] trial length in milliseconds.  This much data after each  (1000)
%                     epochEvent saved to train the classifier
%   freqband       -- [float 4x1] frequency band to use the the spectral filter during ([.1 .5 10 12])
%                     pre-processing
%   capFile        -- [str] filename for the channel positions                         ('1010')
%   verb           -- [int] verbosity level                                            (1)
%   buffhost       -- str, host name on which ft-buffer is running                     ('localhost')
%   buffport       -- int, port number on which ft-buffer is running                   (1972)
%   epochPredFilt  -- [float/str/function_handle] prediction filter for smoothing the 
%                      epoch output classifier.
%   contpredFilt   -- [float/str/function_handle] prediction filter for smoothing the continuous
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

% setup the paths if needed
wb=which('buffer'); 
if ( isempty(wb) || isempty(strfind('dataAcq',wb)) ) 
  mdir=fileparts(mfilename('fullfile')); run(fullfile(mdir,'../utilities/initPaths.m')); 
  % set the real-time-clock to use
  initgetwTime;
  initsleepSec;
end;
opts=struct('epochEventType',[],'clsfr_type','erp','trlen_ms',1000,'freqband',[.1 .5 10 12],...
            'epochPredFilt',[],'contPredFilt',[],'capFile',[],...
				'subject','test','verb',1,'buffhost',[],'buffport',[],'useGUI',1);
[opts,varargin]=parseOpts(opts,varargin);

thresh=[.5 3];  badchThresh=.5;   overridechnms=0;
capFile=opts.capFile;
if( isempty(capFile) ) 
  [fn,pth]=uigetfile('../utilities/*.txt','Pick cap-file'); capFile=fullfile(pth,fn);
  if ( isequal(fn,0) || isequal(pth,0) ) capFile='1010.txt'; end; % 1010 default if not selected
end
if ( ~isempty(strfind(capFile,'1010.txt')) ) overridechnms=0; else overridechnms=1; end; % force default override
if ( ~isempty(strfind(capFile,'tmsi')) ) thresh=[.0 .1 .2 5]; badchThresh=1e-4; end;

if ( isempty(opts.epochEventType) && opts.useGUI )
  optsFig=bufferSignalProcOpts(); 
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

datestr = datevec(now); datestr = sprintf('%02d%02d%02d',datestr(1)-2000,datestr(2:3));
dname='training_data';
cname='clsfr';
testname='testing_data';
subject=opts.subject;


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

% main loop waiting for commands and then executing them
nevents=hdr.nEvents; nsamples=hdr.nsamples;
state=struct('nevents',nevents,'nsamples',nsamples); 
phaseToRun=[]; clsSubj=[]; trainSubj=[];
while ( true )

  if ( ~isempty(phaseToRun) ) state=[]; end
  drawnow;
  
  % wait for a phase control event
  if ( opts.verb>0 ) fprintf('%d) Waiting for phase command\n',nsamples); end;
  [devents,state,nevents,nsamples]=buffer_newevents(opts.buffhost,opts.buffport,state,{'startPhase.cmd' 'subject'},[],5000);
  if ( numel(devents)==0 ) 
    continue;
  elseif ( numel(devents)>1 ) 
    % ensure events are processed in *temporal* order
    [ans,eventsorder]=sort([devents.sample],'ascend');
    devents=devents(eventsorder);
  end
  if ( opts.verb>0 ) fprintf('Got Event: %s\n',ev2str(devents)); end;
  
  % extract the subject info
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
  
  switch lower(phaseToRun);
    
    %---------------------------------------------------------------------------------
   case 'capfitting';
    capFitting('buffhost',opts.buffhost,'buffport',opts.buffport,'noiseThresholds',thresh,'badChThreshold',badchThresh,'verb',opts.verb,'showOffset',0,'capFile',capFile,'overridechnms',overridechnms);

    %---------------------------------------------------------------------------------
   case 'eegviewer';
    eegViewer(opts.buffhost,opts.buffport,'capFile',capFile,'overridechnms',overridechnms);
    
   %---------------------------------------------------------------------------------
   case {'calibrate','calibration'};
    [traindata,traindevents,state]=buffer_waitData(opts.buffhost,opts.buffport,[],'startSet',opts.epochEventType,'exitSet',{{'calibrate' 'calibration'} 'end'},'verb',opts.verb,'trlen_ms',opts.trlen_ms);
    mi=matchEvents(traindevents,{'calibrate' 'calibration'},'end'); traindevents(mi)=[]; traindata(mi)=[];%remove exit event
    fname=[dname '_' subject '_' datestr];
    fprintf('Saving %d epochs to : %s\n',numel(traindevents),fname);save(fname,'traindata','traindevents','hdr');
    trainSubj=subject;

    %---------------------------------------------------------------------------------
   case {'train','training'};
    %try
      if ( ~isequal(trainSubj,subject) || ~exist('traindata','var') )
        fname=[dname '_' subject '_' datestr];
        fprintf('Loading training data from : %s\n',fname);load(fname); 
        trainSubj=subject;
      end;
      if ( opts.verb>0 ) fprintf('%d epochs\n',numel(traindevents)); end;

      switch lower(opts.clsfr_type);
       
       case {'erp','evoked'};
         [clsfr,res]=buffer_train_erp_clsfr(traindata,traindevents,hdr,'spatialfilter','car','freqband',opts.freqband,'badchrm',1,'badtrrm',1,'capFile',capFile,'overridechnms',overridechnms,varargin{:});
       
       case {'ersp','induced'};
         [clsfr,res]=buffer_train_ersp_clsfr(traindata,traindevents,hdr,'spatialfilter','car','freqband',opts.freqband,'badchrm',1,'badtrrm',1,'capFile',capFile,'overridechnms',overridechnms,varargin{:});
       
       otherwise;
        error('Unrecognised classifer type');
      end
      clsSubj=subject;
      fname=[cname '_' subject '_' datestr];
      fprintf('Saving classifier to : %s\n',fname);save(fname,'-struct','clsfr');
    %catch
    %  fprintf('Error in train classifier!');
    %end

    %---------------------------------------------------------------------------------
   case {'test','testing','epochfeedback','eventfeedback'};
    if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) 
      clsfrfile = [cname '_' subject '_' datestr];
      if ( ~exist([clsfrfile '.mat'],'file') ) clsfrfile=[cname '_' subject]; end;
      if(opts.verb>0)fprintf('Loading classifier from file : %s\n',clsfrfile);end;
      clsfr=load(clsfrfile);
      clsSubj = subject;
    end;

    event_applyClsfr(clsfr,'startSet',opts.epochEventType,...
							'predFilt',opts.epochPredFilt,...
							'endType',{'testing','test','epochfeedback','eventfeedback'},'verb',opts.verb);

        %---------------------------------------------------------------------------------
   case {'contfeedback'};
    if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) 
      clsfrfile = [cname '_' subject '_' datestr];
      if ( ~exist([clsfrfile '.mat'],'file') ) clsfrfile=[cname '_' subject]; end;
      if(opts.verb>0)fprintf('Loading classifier from file : %s\n',clsfrfile);end;
      clsfr=load(clsfrfile);
      clsSubj = subject;
    end;

    if ( ~any(strcmp(lower(opts.clsfr_type),{'ersp','induced'})) )
      warning('Cant use an ERP classifier in continuous application mode. Ignored');
    else
		% generate prediction every trlen_ms/2 seconds using trlen_ms data
      cont_applyClsfr(clsfr,'trlen_ms',opts.trlen_ms,'overlap',.5,...
							 'endType',{'testing','test','contfeedback'},...
							 'predFilt',opts.contPredFilt,'verb',opts.verb);
    end
      
   case 'exit';
    break;
    
   otherwise;
    warning(sprintf('Unrecognised experiment phase ignored! : %s',phaseToRun));
    
  end
  if ( opts.verb>0 ) fprintf('Finished : %s @ %5.3fs\n',phaseToRun,getwTime()-ptime); end;
  sendEvent(lower(phaseToRun),'end');    
  
end
