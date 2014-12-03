% buffer controlled execution of the different signal processing phases.
%
% Input events: (type,value)
%  (startPhase.cmd,capfitting) -- show capfitting
%  (startPhase.cmd,calibrate)  -- start calibration phase processing (i.e. cat data)
%  (startPhase.cmd,testing)    -- start test phase, i.e. on-line prediction generation
%  (startPhase.cmd,exit)       -- stop everything
configureNF;

if( ~exist('capFile','var') || isempty(capFile) ) 
  [fn,pth]=uigetfile('../utilities/*.txt','Pick cap-file'); capFile=fullfile(pth,fn);
  if ( isequal(fn,0) || isequal(pth,0) ) capFile='1010.txt'; end; % 1010 default if not selected
end
if ( ~isempty(strfind(capFile,'1010.txt')) ) overridechnms=0; else overridechnms=1; end; % force default override
thresh=[.5 3];  badchThresh=.5;
if ( ~isempty(strfind(capFile,'tmsi')) ) thresh=[.0 .1 .2 5]; badchThresh=1e-4; end;
datestring = datestr(now,'yymmdd');
dname='training_data';
cname='clsfr';
testname='testing_data';
if ( ~exist('verb','var') ) verb =2; end;
trlen_ms = 600;
subject='test';

% main loop waiting for commands and then executing them
state=struct('nevents',[],'nsamples',[]); 
phaseToRun=[]; clsSubj=[]; trainSubj=[];
while ( true )

  if ( ~isempty(phaseToRun) ) state=[]; end
  drawnow;
  
  % wait for a phase control event
  if ( verb>0 ) fprintf('Waiting for phase command\n'); end;
  [devents,state,nevents,nsamples]=buffer_newevents(buffhost,buffport,state,{'startPhase.cmd' 'subject'},[],5000);
  %[data,devents,state]=buffer_waitData(buffhost,buffport,state,'trlen_ms',0,'exitSet',{{'startPhase.cmd' 'subject'}},'verb',verb,'timeOut_ms',5000);   
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
    if ( strcmpi(devents(di).type,'subject') )     
      subject=devents(di).value; 
      if ( verb>0 ) fprintf('Setting subject to : %s\n',subject); end;
      continue; 
    else
      phaseToRun=devents(di).value;
      break;
    end  
  end
  if ( isempty(phaseToRun) ) continue; end;

  fprintf('%d) Starting phase : %s\n',getwTime(),phaseToRun);
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
   case {'contfeedback'};
    % build the classifier     
    if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) 
      clsfrfile = [cname '_' subject '_' datestring];
      if ( ~exist([clsfrfile '.mat'],'file') ) clsfrfile=[cname '_' subject]; end;
      if ( ~exist([clsfrfile '.mat'],'file') )
        clsfr = buffer_train_nf_clsfr(width_ms,feedback,hdr,'capFile',capFile,'overridechnms',overridechnms);
        clsfrfile = [cname '_' subject '_' datestring];
        fprintf('saving to : %s',clsfrfile);  save(clsfrfile,'clsfr');
      end
      load(clsfrfile);
      if ( isfield(clsfr,'clsfr') ) clsfr=clsfr.clsfr; end; 
      clsSubj = subject;
    end;

    cont_applyClsfr(clsfr,'step_ms',step_ms,'alpha',@(x,s) stdFilt(x,s,exp(log(.5)/100)),'predEventType',feedbackEventType,'endType','neurofeedback');
    
   case 'exit';
    break;
    
   otherwise;
    warning(sprintf('Unrecognised experiment phase ignored! : %s',phaseToRun));
    
  end
  if ( verb>0 ) fprintf('Finished : %s @ %5.3fs\n',phaseToRun,getwTime()-ptime); end;    
  sendEvent(lower(phaseToRun),'end');    
end
close all;
%uiwait(msgbox({'Thankyou for participating in our experiment.'},'Thanks','modal'),10);
