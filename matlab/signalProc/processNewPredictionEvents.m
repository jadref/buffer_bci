function [dv,prob,buffstate,filtstate]=processNewPredictionEvents(buffhost,buffport,buffstate,predType,timeout_ms,filtFn,filtstate,verb)
% function to catch new prediction events and convert them to class dv's and probabilities
%
%  [dv,prob,buffstate,filtstate]=processNewPredictionEvents(buffhost,buffport,buffstate,predType,timeout_ms,filtFn,filtstate,verb)
%
% Inputs:
%  buffhost,buffport - [str],[int]; host:port of the buffer server                     ('localhost',1972)
%  buffstate         - [struct] internal state of the buffer-server connection         ([])
%  predType          - [str] types of prediction to match and process                  ('classifier.prediction')
%  timeout_ms        - [float] max time to wait for prediction events                  (5000)
%  filtFn            - 'str' or {'filtFn' args..}.  Function to post-process the predictions, e.g. for smoothing.
%                      function prototype:  [dv,state]=filtFn(dv,filtstate,args..);
%                     OR
%                      [float] -- special case for moving average smoother.
%                        filtFn<1 - ma-factor for exp-moving-ave filter
%                        filtFn>1 - window size for windowed moving average
% 
% Usage Example:
%  dv=[]; state=[]; filtstate=[];
%  while ( timetogo>0 )
%    % get new predictions, waiting max until end-of-trial.  Smooth with 10-prediction-ring-buffer
%    [dv,prob,state,filtstate]=processNewPredictionEvents([],[],state,[],timetogo,10,filtstate);
%    % do something with the predictions
%    fprintf('%5.2f) Pr=[%s]\n',timetogo,sprintf('%g ',prob)); % print the class probs
%  end
if( nargin<1 ) buffhost=[]; end;
if( nargin<2 ) buffport=[]; end;
if( nargin<3 ) buffstate=[]; end;
if( nargin<4 || isempty((predType)))   predType='classifier.prediction'; end;
if( nargin<5 || isempty(timeout_ms) )  timeout_ms=5000; end;
if( nargin<6 ) filtFn=''; end;
if( nargin<7 ) filtstate=[]; end;
if( nargin<8 || isempty(verb) ) verb=0; end

dv=[]; prob=[];

% wait for new prediction events to process *or* end of trial time
if( isstruct(predType) && isfield(predType,'sample') ) % predType is already the events to process
  events = predType;
else
  [events,buffstate,nsamples,nevents] = buffer_newevents(buffhost,buffport,buffstate,predType,[],min(1000,timeout_ms));
end

if ( isempty(events) ) 
  if ( verb>=0 && timeout_ms>300 ) fprintf('%d) no predictions!\n',nsamples); end;
else
  [ans,si]=sort([events.sample],'ascend'); % proc in *temporal* order
  for predEventi=1:numel(events);
    ev=events(si(predEventi));% event to process
	 pred=ev.value;
	 % now do something with the prediction....
    if ( numel(pred)==1 ) pred=[pred -pred]; end% binary special case
	 
    % additional prediction smoothing if needed
	 if ( isempty(filtFn) )
      dv=pred;
    else % additional prediction smoothing for display, if wanted
      if ( isnumeric(filtFn) )
		  if ( filtFn<=1 ) % exp weighted moving average
		    filtstate=filtstate*filtFn + (1-filtFn)*pred(:);
          dv       =filtstate;
		  else % size of ring buffer to use
		    filtstate(:,mod(nEpochs-1,abs(filtFn))+1)=pred(:);% store predictions in a ring buffer
		    dv=mean(filtstate,2);
		  end
      elseif ( iscell(filtFn) || ischar(filtFn) )
        if( ischar(filtFn) ) filtFn={filtFn}; end;
        [dv,filtstate]=feval(filtFn{1},pred,filtstate,filtFn{2:end});
      else
        error('Unrecognised prediction post-processor');
      end
	 end
    if( isempty(dv) ) continue; end;
    
    % convert from dv to normalised probability
    prob=exp((dv-max(dv))); prob=prob./sum(prob); % robust soft-max prob computation
    if ( verb>0 ) 
		fprintf('%d) dv:[%s]\tPr:[%s]\n',ev.sample,sprintf('%5.4f ',pred),sprintf('%5.4f ',prob));
    end;
  end
end % if prediction events to process
