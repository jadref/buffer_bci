function []=startSigProcBuffer_ERP(varargin)
% buffer controlled execution of the different signal processing phases.
%
% Trigger events: (type,value)
%  (startPhase.cmd,capfitting) -- show capfitting
%  (startPhase.cmd,calibrate)  -- start calibration phase processing (i.e. cat data)
%  (calibrate,end)             -- end calibration phase
%  (startPhase.cmd,testing)    -- start test phase, i.e. event based on-line prediction generation
%  (startPhase.cmd,contfeedback) -- start continuous feedback phase, i.e. prediciton event generated every
%                                     trlen_ms/2 milliseconds
%  (testing,end)               -- end testing phase  (either testing, or contfeedback)
%  (startPhase.cmd,exit)       -- stop everything
%
%  []=startSigProcBuffer_ERsP(varargin)
%
% Options:
%   epochEventType -- 'str' event type which indicates start of calibration epoch.   ('stimulus.target') 
%                     This event's value is used as the class label
%   trlen_ms       -- [int] trial length in milliseconds.  This much data after each  (3000)
%                     epochEvent saved to train the classifier
%   freqband       -- [float 4x1] frequency band to use the the spectral filter during ([8 10 28 30])
%                     pre-processing
%   capFile        -- [str] filename for the channel positions                         ('1010')
%   verb           -- [int] verbosity level                                            (1)
% 
% Examples:
%   startSigProcBuffer_ERsP(); % run with standard paramters
%
%  % Run where epoch is any target event or a baseline event and saving 3000ms for classifier training
%   startSigProcBuffer_ERsP('epochEventType',{'stimulus.target','stimulus.baseline'},'trlen_ms',3000); 

% setup the paths if needed
wb=which('buffer'); 
if ( isempty(wb) || isempty(strfind('dataAcq',wb)) ) 
  mdir=fileparts(mfilename('fullfile')); run(fullfile(mdir,'../utilities/initPaths.m')); 
end;
opts=struct('epochEventType','stimulus.target','trlen_ms',3000,'freqband',[8 10 28 30],...
            'capFile',[],'subject','test','verb',0);
opts=parseOpts(opts,varargin);

capFile=opts.capFile;
if( isempty(capFile) ) 
  [fn,pth]=uigetfile('../utilities/*.txt','Pick cap-file'); capFile=fullfile(pth,fn);
  if ( isequal(fn,0) || isequal(pth,0) ) capFile='1010.txt'; end; % 1010 default if not selected
end
if ( ~isempty(strfind(capFile,'1010.txt')) ) overridechnms=0; else overridechnms=1; end; % force default override
thresh=[.5 3];  badchThresh=.5;
if ( ~isempty(strfind(capFile,'tmsi')) ) thresh=[.0 .1 .2 5]; badchThresh=1e-4; end;

datestr = datevec(now); datestr = sprintf('%02d%02d%02d',datestr(1)-2000,datestr(2:3));

dname='training_data';
cname='clsfr';
testname='testing_data';
subject=opts.subject;

% main loop waiting for commands and then executing them
state=struct('nevents',[],'nsamples',[]); 
phaseToRun=[]; clsSubj=[]; trainSubj=[];
while ( true )

  if ( ~isempty(phaseToRun) ) state=[]; end
  drawnow;
  
  % wait for a phase control event
  if ( verb>0 ) fprintf('Waiting for phase command\n'); end;
  [devents,state,nevents,nsamples]=buffer_newevents(buffhost,buffport,state,{'startPhase.cmd' 'subject'},[],5000);
  if ( numel(devents)==0 ) 
    continue;
  elseif ( numel(devents)>1 ) 
    % ensure events are processed in *temporal* order
    [ans,eventsorder]=sort([devents.sample],'ascend');
    devents=devents(eventsorder);
  end
  if ( verb>0 ) fprintf('Got Event: %s\n',ev2str(devents)); end;
  
  % extract the subject info
  phaseToRun=[];
  for di=1:numel(devents);
    % extract the subject info
    if ( strcmp(devents(di).type,'subject') )     
      subject=devents(di).value; 
      if ( verb>0 ) fprintf('Setting subject to : %s\n',subject); end;
      continue; 
    else
      phaseToRun=devents(di).value;
      break;
    end  
  end
  if ( isempty(phaseToRun) ) continue; end;

  fprintf('%d) Starting phase : %s\n',devents(di).sample,phaseToRun);
  fprintf('State: %d %d\n',state.nsamples,state.nevents);
  sendEvent(lower(phaseToRun),'start'); % mark start/end testing
  
  switch lower(phaseToRun);
    
    %---------------------------------------------------------------------------------
   case 'capfitting';
    capFitting('noiseThresholds',thresh,'badChThreshold',badchThresh,'verb',verb,'showOffset',0,'capFile',capFile,'overridechnms',overridechnms);

    %---------------------------------------------------------------------------------
   case 'eegviewer';
    eegViewer(buffhost,buffport,'capFile',capFile,'overridechnms',overridechnms);
    
   %---------------------------------------------------------------------------------
   case {'calibrate','calibration'};
    [traindata,traindevents,state]=buffer_waitData(buffhost,buffport,state,'startSet',opts.epochEventType,'exitSet',{'calibrate' 'end'},'verb',verb,'trlen_ms',trlen_ms);
    mi=matchEvents(traindevents,'calibrate','end'); traindevents(mi)=[];traindata(mi)=[];%remove exit event
    fname=[dname '_' subject '_' datestr];
    fprintf('Saving %d epochs to : %s\n',numel(traindevents),fname);save(fname,'traindata','traindevents','hdr');
    trainSubj=subject;

    %---------------------------------------------------------------------------------
   case {'train','training'};
    %try
      if ( ~isequal(trainSubj,subject) || ~exist('traindata','var') )
        fprintf('Loading training data from : %s\n',[dname '_' subject '_' datestr]);
        load([dname '_' subject '_' datestr]); 
        trainSubj=subject;
      end;
      if ( verb>0 ) fprintf('%d epochs\n',numel(traindevents)); end;

      clsfr=buffer_train_ersp_clsfr(traindata,traindevents,hdr,'spatialfilter','slap','freqband',opts.freqband,'badchrm',1,'badtrrm',1,'objFn','lr_cg','compKernel',0,'dim',3,'capFile',capFile,'overridechnms',overridechnms,'visualize',2);
      clsSubj=subject;
      fname=[cname '_' subject '_' datestr];
      fprintf('Saving classifier to : %s\n',fname); save(fname,'-struct','clsfr');
    %catch
    %  fprintf('Error in train classifier!');
    %end

    %---------------------------------------------------------------------------------
   case {'test','testing','epochfeedback'};
    if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) 
      clsfrfile = [cname '_' subject '_' datestr];
      if ( ~exist([clsfrfile '.mat'],'file') ) clsfrfile=[cname '_' subject]; end;
      if(verb>0)fprintf('Loading classifier from file : %s\n',clsfrfile);end;
      clsfr=load(clsfrfile);
      clsSubj = subject;
    end;

    event_applyClsfr(clsfr,'startSet',{'stimulus.target'},'endType',{'testing','test','epochfeedback'});

    %---------------------------------------------------------------------------------
   case {'contfeedback'};
    if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) 
      clsfrfile = [cname '_' subject '_' datestr];
      if ( ~exist([clsfrfile '.mat'],'file') ) clsfrfile=[cname '_' subject]; end;
      if(verb>0)fprintf('Loading classifier from file : %s\n',clsfrfile);end;
      clsfr=load(clsfrfile);
      clsSubj = subject;
    end;
    
    cont_applyClsfr(clsfr,'overlap',.5,'endType',{'testing','test','contfeedback'});
    
   case 'exit';
    break;
    
   otherwise;
    warning(sprintf('Unrecognised experiment phase ignored! : %s',phaseToRun));
    
  end
  if ( verb>0 ) fprintf('Finished : %s @ %5.3fs\n',phaseToRun,getwTime()-ptime); end;
  sendEvent(lower(phaseToRun),'end');    
end

%uiwait(msgbox({'Thankyou for participating in our experiment.'},'Thanks','modal'),10);
