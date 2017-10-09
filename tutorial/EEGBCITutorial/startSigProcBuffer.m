% buffer controlled execution of the different signal processing phases.
%
% Input events: (type,value)
%  (startPhase.cmd,capfitting) -- show capfitting
%  (startPhase.cmd,calibrate)  -- start calibration phase processing (i.e. cat data)
%  (startPhase.cmd,testing)    -- start test phase, i.e. on-line prediction generation
%  (startPhase.cmd,exit)       -- stop everything
configureDemo;
if( ~exist('capFile','var') || isempty(capFile) ) 
  [fn,pth]=uigetfile('../../resources/caps/*.txt','Pick cap-file'); 
  if ( isequal(fn,0) || isequal(pth,0) ) capFile='1010.txt'; % 1010 default if not selected
  else capFile=fullfile(pth,fn);
  end; 
end
if ( ~isempty(strfind(capFile,'1010.txt')) ) overridechnms=0; else overridechnms=1; end; % force default override
thresh=[.5 3];  badchThresh=.5;
if ( ~isempty(strfind(capFile,'tmsi')) ) thresh=[.0 .1 .2 5]; badchThresh=1e-4; end;
datestr = datevec(now); datestr = sprintf('%02d%02d%02d',datestr(1)-2000,datestr(2:3));
dname='training_data';
cname='clsfr';
testname='testing_data';
if ( ~exist('verb','var') ) verb =2; end;
subject='test';

% main loop waiting for commands and then executing them
state=struct('nevents',[],'nsamples',[]); 
phaseToRun=[]; clsSubj=[]; trainSubj=[];
while ( true )

  if ( ~isempty(phaseToRun) ) state=[]; end
  pause(.1);
  
  % wait for a phase control event
  if ( verb>=0 ) fprintf('Waiting for phase command\n'); end;
  [devents,state,nevents,nsamples]=buffer_newevents(buffhost,buffport,state,...
																	 {'startPhase.cmd' 'subject' 'sigproc.*'},[],1000);
  fprintf('.');
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
  if ( isempty(phaseToRun) ) continue; end;

  fprintf('%g) Starting phase : %s\n',getwTime(),phaseToRun);
  if ( verb>=0 ) fprintf('Starting : %s\n',phaseToRun); ptime=getwTime(); end;
  sendEvent(lower(phaseToRun),'start'); % mark start/end testing
  
  switch lower(phaseToRun);
    
    %---------------------------------------------------------------------------------
   case 'capfitting';
    capFitting('noiseThresholds',thresh,'badChThreshold',badchThresh,'verb',verb,'showOffset',0,'capFile',capFile,'overridechnms',overridechnms);
    sendEvent(['sigproc.' phaseToRun],'end');
    
    %---------------------------------------------------------------------------------
   case 'eegviewer';
    eegViewer(buffhost,buffport,'capFile',capFile,'overridechnms',overridechnms);
    sendEvent(['sigproc.' phaseToRun],'end');
    
    %---------------------------------------------------------------------------------
   case {'erspvis','erpvis','erpviewer','erpvisptb'};	
    erpViewer(buffhost,buffport,'capFile',capFile,'overridechnms',overridechnms,'cuePrefix','stimulus','endType',lower(phaseToRun),'trlen_ms',ersptrlen_ms,'freqbands',[.0 .3 45 47]);
    sendEvent(['sigproc.' phaseToRun],'end');
    
   %---------------------------------------------------------------------------------
   %  Speller
   case {'spcalibrate','spcalibration','erpviewcalibrate','erpviewercalibrate','calibrateerp'};
     [traindata,traindevents]=erpViewer(buffhost,buffport,'capFile',capFile,'overridechnms',overridechnms,'cuePrefix','stimulus.tgtFlash','endType',{'stimulus.training'},'trlen_ms',sptrlen_ms,'freqbands',[.0 .3 45 47]);
     %[traindata,traindevents]=buffer_waitData(buffhost,buffport,[],'startSet',{'stimulus.tgtFlash'},'exitSet',{'stimulus.training' 'end'},'verb',verb+1,'trlen_ms',sptrlen_ms);
     mi=matchEvents(traindevents,'stimulus.training','end'); traindevents(mi)=[]; traindata(mi)=[];%remove exit event
     fprintf('Saving %d epochs to : %s\n',numel(traindevents),['sp_' dname '_' subject '_' datestr]);
     save(['sp_' dname '_' subject '_' datestr],'traindata','traindevents','hdr');
     trainSubj=subject;

   case {'sptrain','sptraining','spclassifier','trainerp'};
    try
      if ( ~isequal(trainSubj,subject) || ~exist('traindata','var') )
        fprintf('Loading training data from : %s\n',['sp_' dname '_' subject '_' datestr]);
        load(['sp_' dname '_' subject '_' datestr]); 
        trainSubj=subject;
      end;
      if ( verb>0 ) fprintf('%d epochs\n',numel(traindevents)); end;

      [clsfr,res]=buffer_train_erp_clsfr(traindata,traindevents,hdr,'spatialfilter','wht','freqband',[.1 .3 8 10],'badchrm',1,'badtrrm',0,'capFile',capFile,'overridechnms',overridechnms);
      clsSubj=subject;
      fprintf('Saving classifier to : %s\n',['sp_' cname '_' subject '_' datestr]);
      save(['sp_' cname '_' subject '_' datestr],'-struct','clsfr');
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);      
      fprintf('Error in train classifier!');
    end

    %---------------------------------------------------------------------------------
   case {'sptest','sptesting'};
    if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) 
      clsfrfile = ['sp_' cname '_' subject '_' datestr];
      %if ( ~exist([clsfrfile '.mat'],'file') ) clsfrfile=['sp_' cname '_' subject]; end;
      if(verb>0)fprintf('Loading classifier from file : %s\n',clsfrfile);end;
      clsfr=load(clsfrfile);
      clsSubj = subject;
    end;

    event_applyClsfr(clsfr,'startSet',{{'stimulus.rowFlash' 'stimulus.colFlash'}},...
                     'endType',{'stimulus.feedback' 'stimulus.test'},...
                     'sendPredEventType','stimulus.sequence',...
                     'trlen_ms',sptrlen_ms);
    %spFeedbackSignals
    
    %---------------------------------------------------------------------------------
    % Movement BCI
   case {'imcalibrate','imcalibration'};
     [traindata,traindevents]=erpViewer(buffhost,buffport,'capFile',capFile,'overridechnms',overridechnms,'cuePrefix','stimulus.target','endType',{'stimulus.training'},'trlen_ms',imtrlen_ms,'freqbands',[.0 .3 45 47]);
     %[traindata,traindevents,state]=buffer_waitData(buffhost,buffport,state,'startSet',{'stimulus.target'},'exitSet',{'stimulus.training' 'end'},'verb',verb+1,'trlen_ms',imtrlen_ms);
    mi=matchEvents(traindevents,'stimulus.training','end'); traindevents(mi)=[];traindata(mi)=[];%remove exit event
    fname=['im_' dname '_' subject '_' datestr];
    fprintf('Saving %d epochs to : %s\n',numel(traindevents),fname);save(fname,'traindata','traindevents','hdr');
    trainSubj=subject;

   case {'imtrain','imtraining','imclassifier','trainersp'};
     try
      if ( ~isequal(trainSubj,subject) || ~exist('traindata','var') )
        fprintf('Loading training data from : %s\n',['im_' dname '_' subject '_' datestr]);
        load(['im_' dname '_' subject '_' datestr]); 
        trainSubj=subject;
      end;
      if ( verb>0 ) fprintf('%d epochs\n',numel(traindevents)); end;

      clsfr=buffer_train_ersp_clsfr(traindata,traindevents,hdr,'spatialfilter','wht','freqband',[8 10 28 30],'badchrm',1,'badtrrm',0,'capFile',capFile,'overridechnms',overridechnms,'visualize',2);
      clsSubj=subject;
      fname=['im_' cname '_' subject '_' datestr];
      fprintf('Saving classifier to : %s\n',fname); save(fname,'-struct','clsfr');
    catch
      fprintf('Error in train classifier!');
    end

   case {'imtest','imtesting','imepochfeedback'};
    if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) 
      clsfrfile = ['im_' cname '_' subject '_' datestr];
      %if ( ~exist([clsfrfile '.mat'],'file') ) clsfrfile=['im_' cname '_' subject]; end;
      if(verb>0)fprintf('Loading classifier from file : %s\n',clsfrfile);end;
      clsfr=load(clsfrfile);
      clsSubj = subject;
    end;
    
    [testdata,testdevents]=event_applyClsfr(clsfr,'buffhost',buffhost,'buffport',buffport,'hdr',hdr,...
                                            'startSet','stimulus.target','trlen_ms',imtrlen_ms,'verb',verb)
    fname=['im_' dname '_' subject '_' datestr '_test'];
    fprintf('Saving %d epochs to : %s\n',numel(testdevents),fname);save(fname,'testdata','testdevents');
    
   case 'exit';
    break;
    
   otherwise;
    warning(sprintf('Unrecognised experiment phase ignored! : %s',phaseToRun));
    
  end
  if ( verb>=0 ) fprintf('Finished : %s @ %5.3fs\n',phaseToRun,getwTime()-ptime); end;
  sendEvent(lower(phaseToRun),'end');    
end

%uiwait(msgbox({'Thankyou for participating in our experiment.'},'Thanks','modal'),10);
