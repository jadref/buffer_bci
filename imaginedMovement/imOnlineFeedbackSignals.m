function []=imOnlineFeedbackSignals(clsfr,varargin)
% now apply this classifier to the new data
%
%  []=imOnlineFeedbackSignals(clsfr,varargin)
%
% Options:
%  buffhost, buffport, hdr
%  endType, endValue  -- event type and value to match to stop giving feedback
%  minEvents     -- [int] minimum number of events before sending prediction   (1)
%  trlen_ms/samp -- [int] length of trial to apply classifier to               ([])
%                     if empty, then = windowFn size used in the classifier training
%  overlap       -- [float] fraction overlap between successive trials, start=t,t+trlen_samp*overlap
%  alpha         -- [float] decay constant for exp-weighted moving average,     ([])
%                     for continuous Neurofeedback style feedback. N.B. alpha = exp(log(.5)/halflife)
%                     if alpha isempty, then simply sum the decision values between prediction events
opts=struct('buffhost','localhost','buffport',1972,'hdr',[],...
            'endType','stimulus.test','endValue','end','verb',0,...
            'minEvents',0,'maxEvents',1,'trlen_ms',[],'trlen_samp',[],'overlap',.5,...
            'alpha',[],'timeout_ms',1000); % exp moving average constant, half-life=10 trials
[opts,varargin]=parseOpts(opts,varargin);
trlen_samp=opts.trlen_samp; 
if ( isempty(trlen_samp) ) 
  trlen_samp=0;
  if ( ~isempty(opts.trlen_ms) ) 
    if(~isempty(opts.hdr))fs=opts.hdr.fsample;else hdr=buffer('get_hdr',buffhost,buffport);fs=hdr.fsample; end;
    trlen_samp = opts.trlen_ms /1000 * fs; 
  end
  % ensure is at least a big as the welch window size!
  if ( isfield(clsfr,'windowFn') ) % est from size welch window function
    trlen_samp=max(trlen_samp,size(clsfr.windowFn,2)); 
  end
end;
step_samp = round(trlen_samp * opts.overlap);
state=[];
predevt=struct('type','prediction','value',[],'sample',[],'duration',[],'offset',[]);
endTest=false;
updateTime=-inf;
status=buffer('wait_dat',[-1 -1 -1],opts.buffhost,opts.buffport);
nEvents=status.nevents; nSamples=status.nsamples;
nTrials=0;
dv=[];
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
  if ( opts.verb>=0 ) % logging stuff for when nothing is happening... 
    t=toc;
    if ( t-t1>=5 ) 
      fprintf(' %5.3f seconds, %d samples %d events\r',t,status.nsamples,status.nevents);
      if ( ispc() ) drawnow; end; % re-draw display
      t1=t;
    end;
  end;
  
  onSamples=nSamples;
  start = onSamples:step_samp:status.nsamples-trlen_samp-1; % window start positions
  if( ~isempty(start) ) nSamples=start(end)+step_samp; end % start of next trial for which not enough data yet
  for si = 1:numel(start);    
    % get the data
    data = buffer('get_dat',[start(si) start(si)+trlen_samp-1],opts.buffhost,opts.buffport);

    if ( opts.verb>1 ) fprintf('Got data @ %d->%d samp\n',start(si),start(si)+trlen_samp-1); end;
    
    % apply classification pipeline to this events data
    [f,fraw,p]=buffer_apply_ersp_clsfr(data.buf,clsfr);

    % accumulate and smooth the classifiers output
    if ( isempty(dv) ) 
      dv=f; 
    else
      if ( isempty(opts.alpha) ) % sum until send
        dv=dv+f;
      else % continuous exp weighted moving average
        dv=dv*opts.alpha + (1-opts.alpha)*f;      
      end
    end
    nTrials=nTrials+1; % count num event proc so far
    
    % Send prediction events when wanted
    if ( nTrials>opts.minEvents && nTrials >= opts.maxEvents ) 
      % send event with prediction
      predevt=sendEvent('stimulus.prediction',dv);
      fprintf('Classification output: event %s\n',ev2str(predevt));      
      nTrials=0;     % clear accumulated info      
      if ( isempty(opts.alpha) ) dv(:)=0; end; % clear accumulated dv in discrete mode
    end
  end
  
  % deal with any events which have happened
  if ( status.nevents > nEvents )
    devents=buffer('get_evt',[nEvents status.nevents-1],opts.buffhost,opts.buffport);
    mi=matchEvents(devents,opts.endType,opts.endValue);
    if ( any(mi) ) fprintf('Got exit event. Stopping'); endTest=true; end;
    nEvents=status.nevents;
  end
end % while not finished
