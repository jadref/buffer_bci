function []=gameApplyClsfr(clsfr,varargin)
% now apply this classifier to the new data
opts=struct('buffhost','localhost','buffport',1972,...
            'stimEventType','stimulus.arrows','endType','stimulus.test','endValue','end','nSymbs',4,'verb',0,...
            'endSeqType','stimulus.endSeq',...
            'minEvents',1,'maxEvents',[],'margin',[],'saveFile',[]);
[opts,varargin]=parseOpts(opts,varargin);
if ( isempty(opts.maxEvents) ) opts.maxEvents=opts.nSymbs; end; % default to 1 pred per rep
if ( ~isempty(opts.margin) ) warning('margin option is ignored!'); end;
trlen_samp=size(clsfr.W,2);
saveData={};
state=[];
predevt=struct('type','prediction','value',[],'sample',[],'duration',[],'offset',[]);
endTest=false;
updateTime=-inf;
nevents=0;
endSeq=false;
highlight=-ones(opts.nSymbs,1);
dv       =zeros(opts.nSymbs,1);
while( ~endTest )
  % block until we've got new events *and/or* data to process
  [data,devents,state]=buffer_waitData(opts.buffhost,opts.buffport,state,'startSet',{{opts.stimEventType}},'exitSet',{{'data' opts.endSeqType opts.endType}},'trlen_samp',trlen_samp,'verb',opts.verb-1,varargin{:});
  
  for ei=1:numel(devents);
    stimEvent=false;
    event=devents(ei);
    % skip events we don't care about
    if( isequal(opts.endType,event.type) && isequal(opts.endValue,event.value) ) % end event
      endTest=true; 
      if ( opts.verb>0 ) fprintf('Exit event: %s\n',ev2str(event)); end
      break;
    elseif ( isequal(opts.endSeqType,event.type) )
      if ( opts.verb>0 ) fprintf('EndSeq event: %s\n',ev2str(event)); end
      endSeq=true;
    elseif ( ~isequal(event.type,opts.stimEventType) || isequal(event.value,opts.endValue) )
      if ( opts.verb>0 ) fprintf('Ignoring event: %s\n',ev2str(event)); end
      continue; 
    else
      if ( opts.verb>0 ) fprintf('Stimulus event: %s\n',ev2str(event)); end
      stimEvent=true;
    end;
    if ( stimEvent )
      % decode into who's highlighted and who's not.
      highlight(:)=-1; if ( ~isempty(event.value) && event.value>0 ) highlight(event.value)=1; end;

      % apply classification pipeline to this events data
      [f,fraw,p,badch,badtr]=buffer_apply_erp_clsfr(data(ei).buf,clsfr,opts.verb-1);
      if ( ~isempty(opts.saveFile) ) % save data for posterity
        saveData{end+1}=struct('event',devents(ei),'data',data(ei),'f',f,'fraw',fraw,'badch',badch,'badtr',badtr);
      end
      
      % generate per-symbol prediction
      dvi = f*highlight; % decode w.r.t. who was actually highlighted
      dv  = dv + dvi;    % accumulate over events
      nevents=nevents+1; % count num event proc so far
    end
    
    if ( (nevents>opts.minEvents && nevents>=opts.maxEvents) || endSeq ) 
      % send event with prediction
      predevt=sendEvent('stimulus.prediction',dv);
      if ( opts.verb>=0 ) fprintf('Classification output: event %s\n',ev2str(predevt)); end;
      dv(:)=0;  nevents=0;  
      if ( endSeq ) state.pending=[]; end % clear waiting data also
      endSeq=false;  
    end
  end
end
% save data for posterity
if ( ~isempty(opts.saveFile) ) 
    fprintf('Saving data to : %s\n',opts.saveFile);
    save(opts.saveFile,'-V6','saveData'); 
end
