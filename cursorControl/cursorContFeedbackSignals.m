function []=gameApplyClsfr(clsfr,varargin)
% now apply this classifier(s) to the new data
opts=struct('buffhost','localhost','buffport',1972,...
            'stimEventType','stimulus.arrows','endType','stimulus.test','endValue','end','verb',0);
[opts,varargin]=parseOpts(opts,varargin);

trlen_samp=0;
for ci=1:numel(clsfr); 
  if(isfield(clsfr(ci),'outsz') && ~isempty(clsfr(ci).outsz)) trlen_samp=max(trlen_samp,clsfr(ci).outsz(1));
  elseif ( isfield(clsfr(ci),'timeIdx') && ~isempty(clsfr(ci).timeIdx) ) trlen_samp = max(trlen_samp,clsfr(ci).timeIdx(2)); 
  end
end

state=[]; 
endTest=false; 
while ( ~endTest )
  % wait for data to apply the classifier to
  [data,devents,state]=buffer_waitData(opts.buffhost,opts.buffport,state,'startSet',{opts.stimEventType},'trlen_samp',trlen_samp,'exitSet',{'data' {opts.endType}},'verb',opts.verb);
  
  % process these events
  for ei=1:numel(devents)
    if (matchEvents(devents(ei),opts.endType,opts.endValue) ) % end testing
      if ( opts.verb>0 ) fprintf('Got end feedback event\n'); end;
      endTest=true;
    elseif ( matchEvents(devents(ei),opts.stimEventType) ) % classification event
      if ( opts.verb>0 ) fprintf('Processing event: %s',ev2str(devents(ei))); end;
      % apply classification pipeline to this events data
      [f,fraw,p]=buffer_apply_erp_clsfr(data(ei).buf,clsfr(1));
      if ( numel(clsfr)>1 ) % apply the 2nd classifier and include it's info in the output
        [f2,fraw2,p2]=buffer_apply_ersp_clsfr(data(ei).buf,clsfr(2));
        if ( opts.verb>0 ) fprintf('clsfrs out: '); fprintf('%g',f,f2); fprintf('\n'); end; % debug info
        f=f+f2; fraw2=fraw+fraw2;
      end
      % send the prediction event, **with the same sample indicator as the trigger event**
      predevt=sendEvent('classifier.prediction',f,devents(ei).sample);
      if ( opts.verb>0 ) fprintf(' = %g\n',f); end;
    end
  end % devents 
end % while
