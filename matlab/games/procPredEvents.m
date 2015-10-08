function [dv,mi]=procPredEvents(events,predType,dv,alpha,verb)
if ( isempty(events) ) mi=[]; return; end;
if ( nargin<4 ) alpha=[]; end;
if ( nargin<5 || isempty(verb) ) verb=0; end;
nSymbs=numel(dv);
mi    =matchEvents(events,predType{:});
if ( sum(mi)==0 )
  if ( 1 )
    return;
  else % make a random testing event
    predevents=struct('type','stimulus.prediction','sample',0,'value',randn(nSymbs,1));
  end  
else
  predevents=events(mi);
end
[ans,si]=sort([predevents.sample],'ascend'); % proc in *temporal* order
for ei=1:numel(predevents);
  ev=predevents(si(ei));% event to process
  if ( verb>1 ) fprintf('Processing Event: %s\n',ev2str(ev)); end;
  pred=ev.value(:);
  % now do something with the prediction....
  if ( numel(pred)==1 ) % predicted symbol, convert to dv equivalent
    tmp=pred; pred=zeros(nSymbs,1); pred(tmp)=1;
  end
  if( isempty(alpha) ) dv=      dv(:) +           pred(1:numel(dv)); 
  else                 dv=alpha*dv(:) + (1-alpha)*pred(1:numel(dv));
  end
  if ( verb>0 ) 
    fprintf('dv:');
    [ans,bs]=max(dv);
    for i=1:numel(dv); 
      fprintf('%5.4f',dv(i)); 
      if(i==bs)fprintf('* '); else fprintf('  '); end;
    end
    fprintf('\n'); 
  end;
 end