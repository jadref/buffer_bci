function [testdata,testevents]=event_applyClsfr(clsfr,varargin)
% apply classifier to data after the indicated events
%
%  [testdata,testevents]=imContFeedbackSignals(clsfr,varargin)
%
% Inputs:
%  clsfr  -- [struct] a classifier structure as returned by train_ersp_clsfr
% Outputs:
%  testdata   -- [struct 1xN] data classifier was applied to in each epoch
%  testevents -- [struct 1xN] event which triggered the classifier to be applied
% Options:
%  buffhost, buffport, hdr
%  startSet      -- {2 x 1} cell array of {event.type event.value} to match to start getting data to 
%                   apply the classifier to.                                   ({'stimulus.target'})
%  endType, endValue  -- event type and value to match to stop giving feedback ('stimulus.test','end')
%  sendPredEventType -- [str] send all predictions generated so far *only* after the event  ([])
%                          type is recieved.  If empty then send all predictions immeadiately.
%  predEventType -- [str] the type to use when sending prediction events       ('classifier.prediction')
%  trlen_ms/samp -- [int] length of trial to apply classifier to               ([])
%                     if empty, then = windowFn size used in the classifier training
%  alpha         -- [float] decay constant for exp-weighted moving average,     ([])
%                     for continuous Neurofeedback style feedback. N.B. alpha = exp(log(.5)/halflife)
%                     if alpha isempty, then simply sum the decision values between prediction events
%
% Examples:
%  % 1) Default: apply clsfr on 'stimulus.target' events and 
%  %    immeadiately send predictions as 'classifier.predicition'
%  %    stop processing when get a 'stimulus.test','end' event.
%   event_applyClsfr(clsfr)
%  % 2) apply clsfr on 'stimulus.target' events
%  %    but accmulate predictions until recieve 'send.prediction' event
%  %    then send all accumulated predictions as 'classifier.prediction' event
%  %    stop processing when get a 'stimulus.test','end' event.
%   event_applyClsfr(clsfr,'sendPredEvent','send.prediction')
%  % 3) apply clsfr on 'stimulus.rowFlash' or 'stimulus.colFlash' events and 
%  %    accumulate predictions until recieve 'send.prediction' event
%  %    stop processing when get a 'stimulus.test','end' event.
%   event_applyClsfr(clsfr,'startSet',{'stimulus.rowFlash','stimulus.colFlash},'sendPredEvent','send.prediction')
opts=struct('buffhost','localhost','buffport',1972,'hdr',[],...
            'startSet',{'stimulus.target'},...
            'endType','stimulus.test','endValue','end','verb',0,...
            'sendPredEventType',[],...
            'predEventType','classifier.prediction',...
            'trlen_ms',[],'trlen_samp',[],...
            'alpha',[],'timeout_ms',1000); 
[opts,varargin]=parseOpts(opts,varargin);

% if not explicitly given work out from the classifier information the trial length needed
% to apply the classifier
trlen_samp=opts.trlen_samp; 
if ( isempty(trlen_samp) ) 
  trlen_samp=0;
  if ( ~isempty(opts.trlen_ms) ) 
    if(~isempty(opts.hdr))fs=opts.hdr.fsample;else hdr=buffer('get_hdr',opts.buffhost,opts.buffport);fs=hdr.fsample; end;
    trlen_samp = opts.trlen_ms /1000 * fs; 
  end
  % ensure is at least a big as the welch window size!
  for ci=1:numel(clsfr); 
    if(isfield(clsfr(ci),'outsz') && ~isempty(clsfr(ci).outsz)) trlen_samp=max(trlen_samp,clsfr(ci).outsz(1));
    elseif ( isfield(clsfr(ci),'timeIdx') && ~isempty(clsfr(ci).timeIdx) ) trlen_samp = max(trlen_samp,clsfr(ci).timeIdx(2)); 
    elseif ( isfield(clsfr,'windowFn') ) % est from size welch window function
      trlen_samp=max(trlen_samp,size(clsfr.windowFn,2)); 
    end
  end
end

% combine the endType info and the sendPrediction event type info, to make a complete set of events for which
% we should stop gathering data and do something
endType=opts.endType;
if ( ~iscell(endType) ) endType={endType}; end;
if ( ~isempty(opts.sendPredEventType) ) 
  if ( iscell(opts.sendPredEventType) ) endType={endType{:} opts.sendPredEventType{:}};
  else                                  endType={endType{:} opts.sendPredEventType};
  end
end

% get startSet in the right format for buffer_waitdata
startSet=opts.startSet;
if ( ~iscell(startSet) || numel(startSet)~=2 ) startSet={startSet}; end;

% for returning the data used by the classifier if wanted
testdata={}; testevents={}; %N.B. cell array to avoid expensive mem-realloc during execution loop

% get info on the current state (do it this way for debugging purposes)
state=buffer('wait_dat',[-1 -1 -1],opts.buffhost,opts.buffport);

dv=[];
nEpochs=0;
nPred=0;
sendPred=false;
endTest=false;
while ( ~endTest )

  % wait for data to apply the classifier to, or got an stop-predicting/send Predictions event
  [data,devents,state]=buffer_waitData(opts.buffhost,opts.buffport,state,'startSet',startSet,'trlen_samp',trlen_samp,'exitSet',{'data' endType},'verb',opts.verb);
  
  % process these events
  for ei=1:numel(devents)

    if ( matchEvents(devents(ei),opts.endType,opts.endValue) ) % end training
      if ( opts.verb>0 ) fprintf('Got end feedback event\n'); end;
      endTest=true;
    
    elseif ( matchEvents(devents(ei),opts.sendPredEventType,opts.endValue) ) % send accumulated predictions
      if ( opts.verb>0 ) fprintf('Got send predictions event\n'); end;
      sendPred=true;
    
    elseif ( matchEvents(devents(ei),opts.startSet) ) % apply the classifier event
      if ( opts.verb>0 ) fprintf('Processing event: %s',ev2str(devents(ei))); end;      

      % save the data used by the classifier if wanted
      if ( nargout>0 ) nEpochs=nEpochs+1; testdata{nEpochs}=data(ei); testevents{nEpochs}=devents(ei); end;

      % apply classification pipeline(s) to this events data      
      for ci=1:numel(clsfr);
        [f(:,ci),fraw(:,ci),p(:,ci)]=buffer_apply_clsfr(data(ei).buf,clsfr(ci));
        if ( opts.verb>1 ) fprintf('clsfr%d pred=[%s]\n',ci,sprintf('%g ',f(:,ci))); end;
      end
      if ( numel(ci)>1 ) % combine individual classifier predictions
        f=sum(f,2); fraw=sum(fraw,2);
      end
      
      % smooth the classifier predictions if wanted
      if ( isempty(dv) || isempty(opts.alpha) ) % moving average
        dv=f;
      elseif ( isnumeric(opts.alpha) )
        if ( opts.alpha>=0 ) % exp weighted moving average
          dv=dv*opts.alpha + (1-opts.alpha)*f;
        else
          fbuff(:,mod(nEpochs-1,abs(opts.alpha))+1)=f; % store predictions in a ring buffer
          dv=mean(fbuff,2);
        end
      end          
      
      % Send prediction event
      if ( isempty(opts.sendPredEventType) ) % send predictions immeadiately
        sendEvent(opts.predEventType,dv,devents(ei).sample);
      else % accumulate predictions
        nPred=nPred+1;
        fs(1:numel(f),nPred)=f; % add to the stored set of predictions
      end
      if ( opts.verb>0 ) fprintf('%d) Clsfr Pred: [%s]\n',devents(ei).sample,sprintf('%g ',dv)); end;
    
    else % another event type we're not sure how to process  (Should never happen)
      if ( opts.verb>0 ) fprintf('Unmatched event : %s\n',ev2str(devents(ei))); end;
    
    end
  end % devents 

  % if got a send-predictionns event, then send the accumulated prediction information
  if ( sendPred )
    sendEvent(opts.predEventType,fs(:,1:nPred));
    if (opts.verb>=0) fprintf('%d) Saved Clsfr Pred: [%s]\n',devents(ei).sample,sprintf('%g ',fs)); end;
    sendPred=false; nPred=0; fs(:)=0; % reset the accumulated info
  end
end % feedback phase
if( nargout>0 ) testdata=cat(1,testdata{:}); testevents=cat(1,testevents{:}); end;
return;
%--------------------------------------
function testCase()
% send immeadiately mode
event_applyClsfr(clsfr,'startSet',{'stimulus.target'},'endType','stimulus.test')
% send on cue mode
event_applyClsfr(clsfr,'startSet',{'stimulus.target'},'endType','stimulus.test','sendPredEventType','stimulus.sequence')