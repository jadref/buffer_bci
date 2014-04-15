% buffer controlled execution of the different signal processing phases.
%
% Input events: (type,value)
%  (startPhase.cmd,capfitting) -- show capfitting
%  (startPhase.cmd,calibrate)  -- start calibration phase processing (i.e. cat data)
%  (startPhase.cmd,testing)    -- start test phase, i.e. on-line prediction generation
%  (startPhase.cmd,exit)       -- stop everything
configureIM;

if( ~exist('capFile','var') || isempty(capFile) ) 
  [fn,pth]=uigetfile('../utilities/*.txt','Pick cap-file'); capFile=fullfile(pth,fn);
  if ( isequal(fn,0) || isequal(pth,0) ) capFile='1010.txt'; end; % 1010 default if not selected
  if ( strcmpi(fn,'1010.txt') ) overridechnms=0; else overridechnms=1; end; % force default override
end
thresh=[.5 3];  badchThresh=.5;   overridechnms=0;
if ( ~isempty(strfind(capFile,'tmsi')) ) thresh=[.0 .1 .2 5]; badchThresh=1e-4;  end;
datestr = datevec(now); datestr = sprintf('%02d%02d%02d',datestr(1)-2000,datestr(2:3));
dname='training_data';
cname='clsfr';
testname='testing_data';
if ( ~exist('verb','var') ) verb =2; end;
subject='test';

% main loop waiting for commands and then executing them
state=struct('pending',[],'nevents',[],'nsamples',[],'hdr',hdr); 
phaseToRun=[]; clsSubj=[]; trainSubj=[];
while ( true )

  if ( ~isempty(phaseToRun) ) state=[]; end
  drawnow;
  
  % wait for a phase control event
  if ( verb>0 ) fprintf('Waiting for phase command\n'); end;
  [data,devents,state]=buffer_waitData(buffhost,buffport,state,'trlen_ms',0,'exitSet',{{'startPhase.cmd' 'subject'}},'verb',verb,'timeOut_ms',5000);   
  if ( numel(devents)==0 ) 
    continue;
  elseif ( numel(devents)>1 ) 
    % ensure events are processed in *temporal* order
    [ans,eventsorder]=sort([devents.sample],'ascend');
    data=data(eventsorder); devents=devents(eventsorder);
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
  if ( verb>0 ) fprintf('Starting : %s\n',phaseToRun); ptime=getwTime(); end;
  sendEvent(lower(phaseToRun),'start'); % mark start/end testing
  
  switch lower(phaseToRun);
    
    %---------------------------------------------------------------------------------
   case 'capfitting';
    capFitting('noiseThresholds',thresh,'badChThreshold',badchThresh,'verb',verb,'showOffset',0,'capFile',capFile,'overridechnms',overridechnms);

    %---------------------------------------------------------------------------------
   case 'eegviewer';
    eegViewer(buffhost,buffport,'capFile',capFile,'overridechnms',overridechnms);

    %---------------------------------------------------------------------------------
   case {'erspvis','erpviewer'};
    [X,Y,key]=erpViewer(buffhost,buffport,'capFile',capFile,'overridechnms',overridechnms,'cuePrefix','stimulus.target','endType',lower(phaseToRun),'trlen_ms',trlen_ms);

    fn=sprintf('erpvis_%s_%s',subject,datestr);fprintf('Saving to: %s\n',fn); % save results
    save(fn,'X','Y','key');
    
    
   %---------------------------------------------------------------------------------
   case {'calibrate','calibration'};
    [traindata,traindevents,state]=buffer_waitData(buffhost,buffport,[],'startSet',{'stimulus.target'},'exitSet',{'stimulus.training' 'end'},'verb',verb,'trlen_ms',trlen_ms);

    mi=matchEvents(traindevents,'stimulus.training','end'); traindevents(mi)=[];traindata(mi)=[];%remove exit event
    fprintf('Saving %d epochs to : %s\n',numel(traindevents),[dname '_' subject '_' datestr]);
    save([dname '_' subject '_' datestr],'traindata','traindevents','hdr');
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

      clsfr=buffer_train_ersp_clsfr(traindata,traindevents,state.hdr,'spatialfilter','slap','freqband',[6 10 26 30],'badchrm',1,'badtrrm',1,'objFn','lr_cg','compKernel',0,'dim',3,'capFile',capFile,'overridechnms',overridechnms,'visualize',2);
      clsSubj=subject;
      fprintf('Saving classifier to : %s\n',[cname '_' subject '_' datestr]);
      save([cname '_' subject '_' datestr],'-struct','clsfr');
    %catch
    %  fprintf('Error in train classifier!');
    %end

    %---------------------------------------------------------------------------------
   case {'test','testing'};
    if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) 
      clsfrfile = [cname '_' subject '_' datestr];
      if ( ~exist([clsfrfile '.mat'],'file') ) clsfrfile=[cname '_' subject]; end;
      if(verb>0)fprintf('Loading classifier from file : %s\n',clsfrfile);end;
      clsfr=load(clsfrfile);
      clsSubj = subject;
    end;

    imOnlineFeedbackSignals(clsfr,'buffhost',buffhost,'buffport',buffport,'hdr',hdr,'endType',lower(phaseToRun),'alpha',0); % N.B. no-averaging in classifier as it's done in the feedback
    
   case 'exit';
    break;
    
   otherwise;
    warning(sprintf('Unrecognised experiment phase ignored! : %s',phaseToRun));
    
  end
  if ( verb>0 ) fprintf('Finished : %s @ %5.3fs\n',phaseToRun,getwTime()-ptime); end;
  sendEvent(lower(phaseToRun),'end');
end

%uiwait(msgbox({'Thankyou for participating in our experiment.'},'Thanks','modal'),10);
