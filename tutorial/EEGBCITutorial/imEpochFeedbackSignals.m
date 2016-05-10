function [testdata,testevents]=imEpochFeedbackSignals(clsfr,varargin)
% apply classifier to data after the indicated events
%
%  [testdata,testevents]=imEpochFeedbackSignals(clsfr,varargin)
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
%  endType, endValue  -- event type and value to match to stop giving feedback
%  trlen_ms/samp -- [int] length of trial to apply classifier to               ([])
%                     if empty, then = windowFn size used in the classifier training
opts=struct('buffhost','localhost','buffport',1972,'hdr',[],...
            'startSet',{'stimulus.target'},...
            'endType','stimulus.test','endValue','end','verb',0,...
            'trlen_ms',[],'trlen_samp',[],...
            'alpha',[],'timeout_ms',1000); 
[opts,varargin]=parseOpts(opts,varargin);
trlen_samp=opts.trlen_samp; 
if ( isempty(trlen_samp) ) 
  trlen_samp=0;
  if ( ~isempty(opts.trlen_ms) ) 
    if(~isempty(opts.hdr))fs=opts.hdr.fsample;else hdr=buffer('get_hdr',opts.buffhost,opts.buffport);fs=hdr.fsample; end;
    trlen_samp = opts.trlen_ms /1000 * fs; 
  end
  % ensure is at least a big as the welch window size!
  if ( isfield(clsfr,'windowFn') ) % est from size welch window function
    trlen_samp=max(trlen_samp,size(clsfr.windowFn,2)); 
  end
end
testdata={}; testevents={}; %N.B. cell array to avoid expensive mem-realloc during execution loop
state=[]; 
endTest=false;
nepochs=0;
while ( ~endTest )
  % wait for data to apply the classifier to
  [data,devents,state]=buffer_waitData(opts.buffhost,opts.buffport,state,'startSet',opts.startSet,'trlen_samp',trlen_samp,'exitSet',{'data' {opts.endType}},'verb',opts.verb);
  
  % process these events
  for ei=1:numel(devents)
    if ( matchEvents(devents(ei),opts.endType,opts.endValue) ) % end training
      if ( opts.verb>0 ) fprintf('Got end feedback event\n'); end;
      endTest=true;
    elseif ( matchEvents(devents(ei),opts.startSet) ) % flash, apply the classifier
      if ( opts.verb>0 ) fprintf('Processing event: %s',ev2str(devents(ei))); end;
      nepochs=nepochs+1;
      if ( nargout>0 ) testdata{nepochs}=data(ei); testevents{nepochs}=devents(ei); end;
      % apply classification pipeline to this events data
      [f,fraw,p]=buffer_apply_ersp_clsfr(data(ei).buf,clsfr);
      sendEvent('classifier.prediction',f,devents(ei).sample);
      if ( opts.verb>0 ) fprintf('Sent classifier prediction = %s.\n',sprintf('%g ',f)); end;
    else
      if ( opts.verb>0 ) fprintf('Unmatched event : %s\n',ev2str(devents(ei))); end;
    end
  end % devents 
end % feedback phase
if( nargout>0 ) testdata=cat(1,testdata{:}); testevents=cat(1,testevents{:}); end;
