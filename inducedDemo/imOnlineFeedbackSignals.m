function []=imApplyClsfr(clsfr,varargin)
% now apply this classifier to the new data
%
%  []=imApplyClsfr(clsfr,varargin)
%
% Options:
%  buffhost, buffport, hdr
%  endType, endValue
%  minEvents, maxEvents
%  trlen_ms/samp -- [int] length of trial to apply classifier to
%  overlap       -- [float] fraction overlap between successive trials, start=t,t+trlen_samp*overlap
%  alpha         -- [float] decay constant for exp-weighted moving average,  (.93 = halflife 10 windows)
%                           N.B. alpha = exp(log(.5)/halflife)
opts=struct('buffhost','localhost','buffport',1972,'hdr',[],...
            'endType','stimulus.test','endValue','end','verb',0,...
            'minEvents',1,'maxEvents',1,'trlen_ms',[],'trlen_samp',[],'overlap',.5,...
            'alpha',exp(log(.5)/10)); % exp moving average constant, half-life=10 trials
[opts,varargin]=parseOpts(opts,varargin);
trlen_samp=opts.trlen_samp; 
if ( isempty(trlen_samp) ) 
  if ( isfield(clsfr,'windowFn') ) % est from size welch window function
    trlen_samp=size(clsfr.windowFn,2); 
  elseif ( ~isempty(opts.trlen_ms) ) 
    if(~isempty(opts.hdr)) fs=opts.hdr.fsample; else hdr=buffer('get_hdr',buffhost,buffport); fs=hdr.fsample; end;
    trlen_samp = opts.trlen_ms /1000 * fs; 
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
while( ~endTest )
  % block until new data to process
  status=buffer('wait_dat',[nSamples+trlen_samp -1 -1],opts.buffhost,opts.buffport);
  
  onSamples=nSamples;
  start = onSamples:step_samp:status.nsamples-trlen_samp-1; % window start positions
  if ( ~isempty(start) ) nSamples = start(end)+step_samp; end % start of next trial for which not enough data yet
  for si = 1:numel(start);    
    % get the data
    data = buffer('get_dat',[start(si)-trlen_samp start(si)-1],opts.buffhost,opts.buffport);

    if ( opts.verb>1 ) fprintf('Got data @ %d samp\n',start(si)); end;
    
    % apply classification pipeline to this events data
    [f,fraw,p]=buffer_apply_ersp_clsfr(data.buf,clsfr);

    % generate per-symbol prediction
    if ( isempty(dv) ) 
      dv=f; 
    else
      dv  = dv*opts.alpha + (1-opts.alpha)*f;      % exp weighted moving average
    end
    nTrials=nTrials+1; % count num event proc so far
    
    if ( nTrials>opts.minEvents && nTrials >= opts.maxEvents ) 
      % send event with prediction
      predevt=sendEvent('stimulus.prediction',dv);
      fprintf('Classification output: event %s\n',ev2str(predevt));      
      nTrials=0;     % clear accumulated info      
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
