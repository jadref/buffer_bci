function [testdata,testevents]=cont_applyClsfr(clsfr,varargin)
% continuously apply this classifier to the new data
%
%  [testdata,testevents]=cont_applyClsfr(clsfr,varargin)
%
% Options:
%  buffhost, buffport, hdr
%  endType, endValue  -- event type and value to match to stop giving feedback
%  trlen_ms/samp -- [float] length of trial to apply classifier to               ([])
%                     if empty, then = windowFn size used in the classifier training
%  overlap       -- [float] fraction of trlen_samp between successive classifier predictions, i.e.
%                    prediction at, t, t+trlen_samp*overlap, t+2*(trlen_samp*overlap), ...
%  step_ms       -- [float] time between classifier predictions                 ([])
%  predFilt         -- [float] prediction filter  ([])
%                     predFilt=[] - no filtering 
%                     predFilt>=0 - coefficient for exp-decay moving average. f=predFilt(f) + (1-predFilt)f_new
%                                N.B. predFilt = exp(log(.5)/halflife)
%                     predFilt<0  - #components to average                    f=mean(f(:,end-predFilt:end),2)
%                  OR
%                   {str} {function_handle}  a function to 'filter' the predictions through
%                             before sending prediction event.  This function should have the signature:
%                         [f,state]=func(f,state)
%                             where state is the internal state of the filter, e.g. the history of past values
%                      Examples: 
%                        'predFilt',@(x,s) avefilt(x,s,10)   % moving average filter, length 10
%                        'predFilt',@(x,s) biasFilt(x,s,50)  % bias adaptation filter, length 50
%                        'predFilt',@(x,s) stdFilt(x,s,100)  % normalising filter (0-mean,1-std-dev), length 100
% Examples:
%  % 1) Default: apply clsfr every 100ms and send predictions as 'classifier.predicition'
%  %    stop processing when get a 'stimulus.test','end' event.
%  cont_applyClsfr(clsfr,'step_ms',100)
%  % 2) apply clsfr every 500ms and send weighted average of the last 10 predictions as 
%  %    an 'alphaPower' event type
%  %    stop processing when get a 'neurofeedback','end' event.
%  cont_applyClsfr(clsfr,'step_ms',500,'alpha',exp(log(.5)/10),'predEventType','alphaPower','endType','neurofeedback')
opts=struct('buffhost','localhost','buffport',1972,'hdr',[],...
            'endType','stimulus.test','endValue','end','verb',0,...
            'predEventType','classifier.prediction',...
            'trlen_ms',[],'trlen_samp',[],'overlap',.5,'step_ms',[],...
            'predFilt',[],'timeout_ms',1000); % exp moving average constant, half-life=10 trials
[opts,varargin]=parseOpts(opts,varargin);

% if not explicitly given work out from the classifier information the trial length needed
% to apply the classifier
trlen_samp=opts.trlen_samp; 
if ( isempty(trlen_samp) ) 
  trlen_samp=0;
  if ( ~isempty(opts.trlen_ms) ) 
    if(~isempty(opts.hdr)) fs=opts.hdr.fsample; 
    else opts.hdr=buffer('get_hdr',opts.buffhost,opts.buffport); fs=opts.hdr.fsample; 
    end;
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
end;

% get time to wait between classifier applications
if ( ~isempty(opts.step_ms) )
  if(~isempty(opts.hdr)) fs=opts.hdr.fsample; 
  else opts.hdr=buffer('get_hdr',[],opts.buffhost,opts.buffport); fs=opts.hdr.fsample; 
  end;
  step_samp = round(opts.step_ms/1000 * fs);
else
  step_samp = round(trlen_samp * opts.overlap);
end

% for returning the data used by the classifier if wanted
testdata={}; testevents={}; %N.B. cell array to avoid expensive mem-realloc during execution loop

% get the current number of samples, so we can start from now
status=buffer('wait_dat',[-1 -1 -1],opts.buffhost,opts.buffport);
nEvents=status.nevents; nSamples=status.nsamples;

dv=[];
nEpochs=0; filtstate=[];
endTest=false;
tic;t1=0;
while( ~endTest )

  % block until new data to process
  status=buffer('wait_dat',[nSamples+trlen_samp -1 opts.timeout_ms],opts.buffhost,opts.buffport);
  if ( status.nsamples < nSamples ) 
    fprintf('Buffer restart detected!'); 
    nSamples=status.nsamples;
    dv(:)=0;
    continue;
  end
    
  % logging stuff for when nothing is happening... 
  if ( opts.verb>=0 ) 
    t=toc;
    if ( t-t1>=5 ) 
      fprintf(' %5.3f seconds, %d samples %d events\r',t,status.nsamples,status.nevents);
      if ( ispc() ) drawnow; end; % re-draw display
      t1=t;
    end;
  end;
    
  % process any new data
  onSamples=nSamples;
  start = onSamples:step_samp:status.nsamples-trlen_samp-1; % window start positions
  if( ~isempty(start) ) nSamples=start(end)+step_samp; end % start of next trial for which not enough data yet
  for si = 1:numel(start);    
    nEpochs=nEpochs+1;
    
    % get the data
    data = buffer('get_dat',[start(si) start(si)+trlen_samp-1],opts.buffhost,opts.buffport);
      
    if ( opts.verb>1 ) fprintf('Got data @ %d->%d samp\n',start(si),start(si)+trlen_samp-1); end;
    % save the data used by the classifier if wanted
    if ( nargout>0 ) testdata{nepochs}=data;testevents{nepochs}=mkEvent('data',0,start(si)); end;
      
    % apply classification pipeline to this events data
    for ci=1:numel(clsfr);
      [f(:,ci),fraw(:,ci),p(:,ci)]=buffer_apply_clsfr(data.buf,clsfr(ci));
      if ( opts.verb>1 ) fprintf('clsfr%d pred=[%s]\n',ci,sprintf('%g ',f(:,ci))); end;
    end
    if ( numel(clsfr)>1 ) % combine individual classifier predictions, simple max-likelihood sum
      f=sum(f,2); fraw=sum(fraw,2);
    end
    % smooth the classifier predictions if wanted
    if ( isempty(dv) || isempty(opts.predFilt) ) 
      dv=f;
    else
      if ( isnumeric(opts.predFilt) )
        if ( opts.predFilt>=0 ) % exp weighted moving average
          dv=dv*opts.predFilt + (1-opts.predFilt)*f;
        end
      elseif ( isstr(opts.predFilt) || isa(opts.predFilt,'function_handle') )
        [dv,filtstate]=feval(opts.predFilt,f,filtstate);
      end
    end
      
    % Send prediction event
    sendEvent(opts.predEventType,dv,start(si));
    if ( opts.verb>0 ) fprintf('%d) Clsfr Pred: [%s]\n',start(si),sprintf('%g ',dv)); end;
  end
    
  % deal with any events which have happened
  if ( status.nevents > nEvents )
    devents=buffer('get_evt',[nEvents status.nevents-1],opts.buffhost,opts.buffport);
    mi=matchEvents(devents,opts.endType,opts.endValue);
    if ( any(mi) ) fprintf('Got exit event. Stopping'); endTest=true; end;
    nEvents=status.nevents;
  end
end % while not endTest
return;
%--------------------------------------
function testCase()
cont_applyClsfr(clsfr,'overlap',.1)
% smooth output with standardising filter, such that mean=0 and variance=1 over last 100 predictions
cont_applyClsfr(clsfr,'predFilt',@(x,s) stdFilt(x,s,exp(log(.5)/100)));