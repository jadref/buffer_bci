function []=gameApplyClsfr(clsfr,varargin)
% now apply this classifier(s) to the new data
opts=struct('buffhost','localhost','buffport',1972,...
            'stimEventType','stimulus.arrows','endType','stimulus.test','endValue','end','nSymbs',2,'verb',0,...
            'endSeqType','stimulus.endSeq',...
            'minEvents',1,'maxEvents',[]);
[opts,varargin]=parseOpts(opts,varargin);
if ( isempty(opts.maxEvents) ) opts.maxEvents=opts.nSymbs; end; % default to 1 pred per rep
trlen_samp=size(clsfr(1).W,2);
state=[];
predevt=struct('type','prediction','value',[],'sample',[],'duration',[],'offset',[]);
endTest=false;
updateTime=-inf;
nevents=0;
nSymbs=max(1,opts.nSymbs); 
endSeq=false;
highlight=-ones(nSymbs,1);
dv       =zeros(nSymbs,1);
while( ~endTest )
  % block until we've got new events *and* data to process
  [data,devents,state]=buffer_waitData(opts.buffhost,opts.buffport,state,'startSet',{{opts.stimEventType}},'exitSet',{{'data' opts.endSeqType opts.endType}},'trlen_samp',trlen_samp,'verb',opts.verb-1,varargin{:});
  
  for ei=1:numel(devents);
    event=devents(ei);
    % skip events we don't care about
    if( isequal(opts.endType,event.type) && isequal(opts.endValue,event.value) ) % end event
      endTest=true; 
      fprintf('Discarding all subsequent events: exit\n');
      break;
    elseif ( isequal(opts.endSeqType,event.type) )
      if ( opts.verb>0 ) fprintf('EndSeq event: %s\n',ev2str(event)); end
      endSeq=true;
    elseif ( ~isequal(event.type,opts.stimEventType) || isequal(event.value,opts.endValue) )
      if ( opts.verb>0 ) fprintf('Ignoring event: %s\n',ev2str(event)); end
      continue; 
    else % stimulus event to process
      if ( opts.verb>0 ) fprintf('Processing event: %s\n',ev2str(event)); end
      % decode into who's highlighted and who's not.
      if ( numel(event.value)==1 ) % stimulus ID encoded
        highlight(:)=-1; highlight(event.value)=1; 
        if ( event.value>nSymbs ) nSymbs=event.value; dv(end+1:nSymbs)=0; end;
      else %logical vector of who's highlighted encoded
        highlight=single(event.value>0); highlight(highlight<=0)=-1; 
        if ( numel(highlight)>nSymbs ) nSymbs=numel(highlight); dv(end+1:nSymbs)=0; end;
      end;
      highlight(end+1:nSymbs)=0; % zero pad if needed

      % apply classification pipeline to this events data
      [f,fraw,p]=buffer_apply_erp_clsfr(data(ei).buf,clsfr(1));
      if ( numel(clsfr)>1 ) % apply the 2nd classifier and include it's info in the output
        [f2,fraw2,p2]=buffer_apply_ersp_clsfr(data(ei).buf,clsfr(2));
        if ( opts.verb>0 ) fprintf('clsfrs out: '); fprintf('%g',f,f2); fprintf('\n'); end; % debug info
        f=f+f2; fraw2=fraw+fraw2;
      end
      
      % generate per-symbol prediction
      dvi = f*highlight; % decode w.r.t. who was actually highlighted
      dv  = dv + dvi;    % accumulate over events
      nevents=nevents+1; % count num event proc so far
    end
    
    if ( nevents>opts.minEvents && nevents >= opts.maxEvents || endSeq ) 
      % send event with prediction
      predevt=sendEvent('classifier.prediction',dv);
      fprintf('Classification output: event %s\n',ev2str(predevt));
      dv(:)=0;  nevents=0;     % clear accumulated info      
      if ( endSeq ) state.pending=[]; end % clear waiting data also
      endSeq=false;  
    end
  end
end
