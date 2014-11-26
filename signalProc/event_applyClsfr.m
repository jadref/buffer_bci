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
%  trlen_ms/samp -- [int] length of trial to apply classifier to               ([])
%                     if empty, then = windowFn size used in the classifier training
%  alpha         -- [float] decay constant for exp-weighted moving average,     ([])
%                     for continuous Neurofeedback style feedback. N.B. alpha = exp(log(.5)/halflife)
%                     if alpha isempty, then simply sum the decision values between prediction events
opts=struct('buffhost','localhost','buffport',1972,'hdr',[],...
            'startSet',{'stimulus.target'},...
            'endType','stimulus.test','endValue','end','verb',0,...
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

% for returning the data used by the classifier if wanted
testdata={}; testevents={}; %N.B. cell array to avoid expensive mem-realloc during execution loop

state=[]; % start from the current time

dv=[];
nEpochs=0;
endTest=false;
while ( ~endTest )
  % wait for data to apply the classifier to, or got an stop-predicting event
  [data,devents,state]=buffer_waitData(opts.buffhost,opts.buffport,state,'startSet',opts.startSet,'trlen_samp',trlen_samp,'exitSet',{'data' {opts.endType}},'verb',opts.verb);
  
  % process these events
  for ei=1:numel(devents)

    if ( matchEvents(devents(ei),opts.endType,opts.endValue) ) % end training
      if ( opts.verb>0 ) fprintf('Got end feedback event\n'); end;
      endTest=true;
    
    elseif ( matchEvents(devents(ei),opts.startSet) ) % flash, apply the classifier
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
      else % exp-weighted moving average
        dv=dv*opts.alpha + (1-opts.alpha)*f;      
      end          
      
      % Send prediction events when wanted
      sendEvent('classifier.prediction',f,devents(ei).sample);
      if ( opts.verb>0 ) fprintf('%d) Clsfr Pred: [%s]\n',devents(ei).sample,sprintf('%g ',f)); end;
    else
      if ( opts.verb>0 ) fprintf('Unmatched event : %s\n',ev2str(devents(ei))); end;
    end
  end % devents 
end % feedback phase
if( nargout>0 ) testdata=cat(1,testdata{:}); testevents=cat(1,testevents{:}); end;
return;
%--------------------------------------
function testCase()
event_applyClsfr(clsfr,'startSet',{'stimulus.target'},'endType','stimulus.test')