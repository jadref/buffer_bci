configureCursor;

cname='clsfr';
if ( ~exist('clsfr','var') ) clsfr=load(cname); end;
trlen_samp=size(clsfr.W,2);

state=[]; 
endTest=false; fs=0;
while ( ~endTest )
  % reset the sequence info
  endSeq=false; 
  fs(:)=0;  % predictions
  nFlash=0; % number flashes processed
  while ( ~endSeq && ~endTest )
    % wait for data to apply the classifier to
    [data,devents,state]=buffer_waitData(buffhost,buffport,state,'startSet',{{'stimulus.rowFlash' 'stimulus.colFlash'}},'trlen_samp',trlen_samp,'exitSet',{'data' {'stimulus.sequence' 'stimulus.feedback'} 'end'},'verb',verb);
  
    % process these events
    for ei=1:numel(devents)
      if ( matchEvents(devents(ei),'stimulus.sequence','end') ) % end sequence
        if ( verb>0 ) fprintf('Got sequence end event\n'); end;
        endSeq=true;
      elseif (matchEvents(devents(ei),'stimulus.feedback','end') ) % end training
        if ( verb>0 ) fprintf('Got end feedback event\n'); end;
        endTest=true;
      elseif ( matchEvents(devents(ei),{'stimulus.rowFlash','stimulus.colFlash'}) ) % flash, apply the classifier
        if ( verb>0 ) fprintf('Processing event: %s',ev2str(devents(ei))); end;
        nFlash=nFlash+1;
        % apply classification pipeline to this events data
        [f,fraw,p]=buffer_apply_erp_clsfr(data(ei).buf,clsfr);
        fs(1:numel(f),nFlash)=f; % store the set of all predictions so far
        if ( verb>0 ) fprintf(' = %g',f); end;
      end
    end % devents 
  end % sequences
  if ( endSeq ) % send the accumulated predictions
    if ( verb>0 ) fprintf('Sending classifier prediction.\n'); end;
    sendEvent('classifier.prediction',fs(:,1:nFlash));
  end
end % feedback phase
