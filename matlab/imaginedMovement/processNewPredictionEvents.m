% wait for new prediction events to process *or* end of trial time
[events,state,nsamples,nevents] = buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],min(1000,eventWaitTime*1000));
if ( isempty(events) ) 
  if ( eventWaitTime>.3 ) fprintf('%d) no predictions!\n',nsamples); end;
else
  [ans,si]=sort([events.sample],'ascend'); % proc in *temporal* order
  for predEventi=1:numel(events);
    ev=events(si(predEventi));% event to process
	 %fprintf('pred-evt=%s\n',ev2str(ev));
	 pred=ev.value;
	 % now do something with the prediction....
    if ( numel(pred)==1 )
      if ( pred>0 && pred<=nSymbs && isinteger(pred) ) % predicted symbol, convert to dv equivalent
        tmp=pred; pred=zeros(nSymbs,1); pred(tmp)=1;
      else % binary problem
        pred=[pred -pred];
      end
    end

	 % additional prediction smoothing for display, if wanted
	 if ( ~isempty(stimSmoothFactor) && isnumeric(stimSmoothFactor) && stimSmoothFactor>0 )
		if ( stimSmoothFactor>=0 ) % exp weighted moving average
		  dv=dv*stimSmoothFactor + (1-stimSmoothFactor)*pred(:);
		else % store predictions in a ring buffer
		  fbuff(:,mod(nEpochs-1,abs(stimSmoothFactor))+1)=pred(:);% store predictions in a ring buffer
		  dv=mean(fbuff,2);
		end
	 else
		dv=pred;
	 end

    % convert from dv to normalised probability
    prob=exp((dv-max(dv))); prob=prob./sum(prob); % robust soft-max prob computation
    if ( verb>=0 ) 
		fprintf('%d) dv:[%s]\tPr:[%s]\n',ev.sample,sprintf('%5.4f ',pred),sprintf('%5.4f ',prob));
    end;
  end
end % if prediction events to process
