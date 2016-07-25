function [traindata,traindevents]=trainDataCatcher(varargin)
% general catcher, accumulator, and saver for data triggered by particular buffer-events 
%
%  Between start/end events of {t:'startPhase.cmd',v:dataCatchPhases} catch data after trigger events {t:epochEventType}
%  and accumulate this data, then save the resulting data to the file trainingdata_${subjectID}_${YYMMDD}
%
%  Note: This does some of the same work as startSigProcBuffer, so need to be careful don't have both running at the same time...
%
% Options:
%   phaseEventType -- 'str' event type which says start a new phase                 ('startPhase.cmd')
%   dataCatchPhases -- {'str'} list of phase names for which we will catch epochEvents and add to the traing data
%                  default ({'test','testing','epochfeedback','eventfeedback','contfeedback','calibrate','calibration','calibrate_incremental'})
%   epochEventType -- 'str' event type which indicates start of calibration epoch.  ('stimulus.target')
%                     This event's value is used as the class label
%   trlen_ms       -- [int] trial length in milliseconds.  This much data after each  (1000)
%                     epochEvent saved to train the classifier
%   calibrateOpts  -- {cell} addition options to pass to the calibration routine
%                     SEE: buffer_waitData for information on th options available
%   verb           -- [int] verbosity level                                            (1)
%   buffhost       -- str, host name on which ft-buffer is running                     ('localhost')
%   buffport       -- int, port number on which ft-buffer is running                   (1972)
%
% Examples:
%   trainDataCatcher(); % run with standard parameters using the GUI to get more info.
%
%  % Run where epoch is any of row/col or target flash and saving 600ms after these events for classifier training
%   trainDataCatcher('epochEventType',{'stimulus.target','stimulus.rowFlash','stimulus.colFlash'},'trlen_ms',600); 

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
            'dataCatchPhases',{{'test','testing','epochfeedback','eventfeedback','contfeedback','calibrate','calibration','calibrate_incremental'}},...
				'epochEventType',[],'trlen_ms',1000,...
				'calibrateOpts',{{}},
				'subject','test','verb',1,'buffhost',[],'buffport',[],'timeout_ms',500);
opts=parseOpts(opts,varargin);

% [] TODO: ask the user for the trigger-event type and the trial-length
if ( isempty(opts.epochEventType) )
   ;
end
if ( isempty(opts.epochEventType) )     opts.epochEventType='stimulus.target'; end;

datestr = datevec(now); datestr = sprintf('%02d%02d%02d',datestr(1)-2000,datestr(2:3));
dname='training_data';  traindata=[]; traindevents=[];
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
phaseToRun=[];
while ( true )

  if ( ~isempty(phaseToRun) ) state=[]; end
  % GUI update
  fprintf('.'); drawnow;

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
    elseif ( strncmp(devents(di).type,'sigproc.',numel('sigproc.')) && strcmp(devents(di).value,'start') ) % start phase command
      phaseToRun=devents(di).type(numel('sigproc.')+1:end);
    else
      phaseToRun=devents(di).value;
      break;
    end  
  end
  if ( isempty(phaseToRun) ) continue; end;

  fprintf('%d) Starting phase : %s\n',devents(di).sample,phaseToRun);
  if ( opts.verb>0 ) ptime=getwTime(); end;
  
  sendEvent(['sigproc.' lower(phaseToRun)],'ack'); % ack-start cmd recieved
  switch lower(phaseToRun);
    	 
   %---------------------------------------------------------------------------------
    case opts.dataCatchPhases;
      % run the data catcher
      [ntraindata,ntraindevents,state]=buffer_waitData(opts.buffhost,opts.buffport,[],...
                                                       'startSet',opts.epochEventType,...
                                                       'exitSet',{{phaseToRun ['sigproc.' phaseToRun] 'sigproc.reset'} 'end'},...
                                                       'trlen_ms',opts.trlen_ms,...
                                                       'verb',opts.verb,opts.calibrateOpts{:});
      mi=matchEvents(ntraindevents,{'calibrate' 'calibration'},'end'); ntraindevents(mi)=[]; ntraindata(mi)=[];%remove exit event
      % accumulate the data
      if(isempty(traindata))
        traindata=ntraindata;                  traindevents=ntraindevents;
      else
        traindata=cat(1,traindata,ntraindata); traindevents=cat(1,traindevents,ntraindevents);
      end
      % save the combined training data-file
      fname=[dname '_' subject '_' datestr];
      fprintf('Saving %d epochs to : %s\n',numel(traindevents),fname);save([fname '.mat'],'traindata','traindevents','hdr');
      trainSubj=subject;

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
       break;
     else
       fprintf('Loading training data from : %s\n',fname);
     end
     chdr=hdr;
     load(fname); 
     if( ~isempty(chdr) ) hdr=chdr; end;
     trainSubj=subject;
    	 
   case {'quit','exit'};
    break;
    
   otherwise;
	  
    warning(sprintf('Unrecognised experiment phase ignored! : %s',phaseToRun));
    
  end
  if ( opts.verb>0 ) fprintf('Finished : %s @ %5.3fs\n',phaseToRun,getwTime()-ptime); end;
  sendEvent(['sigproc.' lower(phaseToRun)],'end');      
end
