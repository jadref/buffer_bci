function [testdata,testevents,predevents]=cont_applyClsfr(clsfr,varargin)
% continuously apply this classifier to the new data
%
%  [testdata,testevents,predevents]=cont_applyClsfr(clsfr,varargin)
%
% Options:
%  buffhost, buffport, hdr
%  endType, endValue  -- event type and value to match to stop giving feedback   ('stimulus.test','end')
%  predEventType -- 'str' event type to use for the generated prediction events  ('classifier.prediction')
%  trlen_ms/samp -- [float] length of trial to apply classifier to               ([])
%                     if empty, then = windowFn size used in the classifier training
%  overlap       -- [float] fraction of trlen_samp between successive classifier predictions, i.e.
%                    prediction at, t, t+trlen_samp*overlap, t+2*(trlen_samp*overlap), ...
%  step_ms       -- [float] time between classifier predictions                 ([])
%  predFilt         -- [float] prediction filter  ([])
%                     predFilt=[] - no filtering 
%                     predFilt>=0 - coefficient for exp-decay moving average. f=predFilt*f + (1-predFilt)f_new
%                                N.B. predFilt = exp(log(.5)/halflife)
%                     predFilt<0  - #components to average                    f=mean(f(:,end-predFilt:end),2)
%                  OR
%                   {str} {function_handle}  a function to 'filter' the predictions through
%                             before sending prediction event.
%                         N.B. If used, prediction events are only sent if f is non-empty
%                         [f,state]=func(f,state,evt)
%                             where state is the internal state of the filter, e.g. the history of past values
%                             and evt is the reason the classifier was applied at this time
%                      Examples: 
%                        'predFilt',@(x,s,e) avefilt(x,s,10)   % moving average filter, length 10
%                        'predFilt',@(x,s,e) biasFilt(x,s,50)  % bias adaptation filter, length 50
%                        'predFilt',@(x,s,e) stdFilt(x,s,100)  % normalising filter (0-mean,1-std-dev), length 100
%                        'predFilt',@(x,s,e) avenFilt(x,s,10)  % send average f every 10 predictions
%                        'predFilt',@(x,s,e) marginFilt(x,s,3) % send if margin between best and worst prediction >=3
%  resetType     -- event type to match to reset the filter states   ('classifier.reset')
%  clsfrOpts  -- {opts} name,value pairs to override fields in the input classfier structure
% Examples:
%  % 1) Default: apply clsfr every 100ms and send predictions as 'classifier.predicition'
%  %    stop processing when get a 'stimulus.test','end' event.
%  cont_applyClsfr(clsfr,'step_ms',100)
%  % 2) apply clsfr every 500ms and send weighted average of the last 10 predictions as 
%  %    an 'alphaPower' event type
%  %    stop processing when get a 'neurofeedback','end' event.
%  cont_applyClsfr(clsfr,'step_ms',500,'predFilt',exp(log(.5)/10),'predEventType','alphaPower','endType','neurofeedback')
%  % 3) smooth output with standardising filter, such that mean=0 and variance=1 
%  %    over last 100 predictions
%  cont_applyClsfr(clsfr,'predFilt',@(x,s) stdFilt(x,s,exp(log(.5)/100)));

opts=struct('buffhost','localhost','buffport',1972,'hdr',[],...
            'endType',{{'stimulus.test' 'stimulus.testing' 'sigproc.reset'}},'endValue','end','verb',0,...
				'resetType','classifier.reset',...
            'predEventType','classifier.prediction',...
            'rawpredEventType','',...
				'labelEventType',[],...
            'maxFrameLag',3,...
            'trlen_ms',[],'trlen_samp',[],'overlap',.5,'step_ms',[],...
            'predFilt',[],'timeout_ms',1000,'adaptspatialfiltFn',[]);
[opts]=parseOpts(opts,varargin);

% override classifier fields
if ( ~isempty(opts.adaptspatialfiltFn) )
  for ci=1:numel(clsfr); clsfr(ci).adaptspatialfiltFn=opts.adaptspatialfiltFn; end;
end

% if not explicitly given work out from the classifier information the trial length needed
% to apply the classifier
trlen_samp=opts.trlen_samp; 
if ( isempty(trlen_samp) ) 
  trlen_samp=0;
  if ( ~isempty(opts.trlen_ms) ) 
    if(~isempty(opts.hdr)) fs=opts.hdr.fsample; 
    else opts.hdr=buffer('get_hdr',[],opts.buffhost,opts.buffport); fs=opts.hdr.fsample; 
    end;
    trlen_samp = opts.trlen_ms /1000 * fs; 
  end
  % ensure is at least a big as the welch window size!
  for ci=1:numel(clsfr); 
    if(isfield(clsfr(ci),'outsz') && ~isempty(clsfr(ci).outsz)) trlen_samp=max(trlen_samp,clsfr(ci).outsz(1));
    elseif ( isfield(clsfr(ci),'timeIdx') && ~isempty(clsfr(ci).timeIdx) ) trlen_samp = max(trlen_samp,clsfr(ci).timeIdx(2)); 
    elseif ( isfield(clsfr(ci),'windowFn') ) % est from size welch window function
      trlen_samp=max(trlen_samp,size(clsfr(ci).windowFn,2)); 
    end
  end
end;

% get time to wait between classifier applications
if ( ~isempty(opts.step_ms) )
  if(~isempty(opts.hdr)) fs=opts.hdr.fsample; 
  else opts.hdr=buffer('get_hdr',[],opts.buffhost,opts.buffport); fs=opts.hdr.fsample; 
  end;
  step_samp = round(opts.step_ms/1000 * fs);
else
  step_samp = round(trlen_samp * opts.overlap);
end

                                % send info our our class mapping
if ( numel(clsfr)==1 )
  spKey=clsfr.spKey;
  if(iscell(spKey)) % can't send cell-array's directly...
    str='';
    for ci=1:numel(spKey);
      if( ischar(spKey{ci}) ) str=sprintf('%s\n%s',str,spKey{ci});
      elseif( isnumeric(spKey{ci}) ) str=sprintf('%s\n%d',str,spKey{ci});
      else str=sprintf('%s\n???',str);
      end;
    end
    spKey=str;
  end
  sendEvent('classifier.spKey',spKey);
end

% for returning the data used by the classifier if wanted
testdata={}; testevents={}; predevents={};%N.B. cell array to avoid expensive mem-realloc during execution loop

% get the current number of samples, so we can start from now
status=buffer('wait_dat',[-1 -1 -1],opts.buffhost,opts.buffport);
nEvents=status.nevents; nSamples=status.nSamples; % most recent event/sample seen
endSample=nSamples+trlen_samp; % last sample of the first window to apply to

dv=[];
lev=[]; testLabi=1;
nEpochs=0; filtstate=[]; fbuff=[];
endTest=false;
tic;t0=0;t1=t0;
while( ~endTest )

  % block until new data to process
  status=buffer('wait_dat',[endSample -1 opts.timeout_ms],opts.buffhost,opts.buffport);
  if ( status.nSamples < nSamples ) 
    fprintf('Buffer restart detected!'); 
    nSamples =status.nSamples;
	 endSample=nSamples+trlen_samp;
    dv(:)=0;
    continue;
  end
  nSamples=status.nSamples; % keep track of last sample seen for re-start detection
    
  % logging stuff for when nothing is happening... 
  if ( opts.verb>=0 ) 
    t=toc;
    if ( t-t1>=5 ) 
      fprintf(' %5.3f seconds, %d samples %d events\n',t,status.nsamples,status.nevents);
      if ( ispc() ) drawnow; end; % re-draw display
      t1=t;
    end;
  end;
    
  % process any new data
  oendSample=endSample;
  fin = oendSample:step_samp:status.nSamples; % window start positions
  if( ~isempty(fin) ) endSample=fin(end)+step_samp; end %fin of next trial for which not enough data
  if ( numel(fin)>opts.maxFrameLag ) % drop frames if we can't keep up
	  fprintf('Warning: classifier cant keep up, dropping %d frames!\n',numel(fin)-1);
	  fin=fin(end);
  end
  for si = 1:numel(fin);    
    nEpochs=nEpochs+1;
    
    % get the data
    data = buffer('get_dat',[fin(si)-trlen_samp fin(si)-1],opts.buffhost,opts.buffport);
      
    if ( opts.verb>1 ) fprintf('Got data @ %d->%d samp\n',fin(si)-trlen_samp,fin(si)-1); end;
    % save the data used by the classifier if wanted
    if ( nargout>0 ) testdata{nEpochs}=data;testevents{nEpochs}=mkEvent('data',0,fin(si)); end;
      
    % apply classification pipeline to this events data
    for ci=1:numel(clsfr);
      [f(:,ci),fraw(:,ci),p(:,ci)]=buffer_apply_clsfr(data.buf,clsfr(ci),opts.verb);
      if ( opts.verb>1 ) fprintf('clsfr%d pred=[%s]\n',ci,sprintf('%g ',f(:,ci))); end;
    end
    if ( numel(clsfr)>1 ) % combine individual classifier predictions, simple max-likelihood sum
      f=sum(f,2); fraw=sum(fraw,2);
    end
    % send raw prediction event if wanted
    if(opts.verb>0) fprintf('%3d) s:%d->%d',fin(si),fin(si)-trlen_samp,fin(si)); end
    if ( ~isempty(opts.rawpredEventType) )
	    if(opts.verb>0) fprintf('  raw_pred v:[%s]',sprintf('%5.3f ',f)); end
       sendEvent(opts.rawpredEventType,f,fin(si)-trlen_samp); %N.B. event sample is window-start!       
    end

    % filter the raw predictions if wanted
    if ( isempty(dv) || isempty(opts.predFilt) ) 
      dv=f;
    else
      if ( isempty(dv) ) dv=zeros(size(f)); end;
      if ( isnumeric(opts.predFilt) )
        if ( opts.predFilt>=0 ) % exp weighted moving average
          dv=dv*opts.predFilt + (1-opts.predFilt)*f;
		  else % store predictions in a ring buffer
          fbuff(:,mod(nEpochs-1,abs(opts.predFilt))+1)=f; % store predictions in a ring buffer
          dv=mean(fbuff,2);
        end
      elseif ( ischar(opts.predFilt) || isa(opts.predFilt,'function_handle') )
        [dv,filtstate]=feval(opts.predFilt,f,filtstate,fin(si));
      end
    end
      
	 % Send prediction event, if wanted
	 if( ~isempty(dv) ) 
		ev=sendEvent(opts.predEventType,dv,fin(si)-trlen_samp); %N.B. event sample is window-start!
		if ( opts.verb>0 ) fprintf('  pred v:[%s]\n',sprintf('%5.3f ',dv)); end
		if( nargout>2 ) predevents{nEpochs}=ev; end;
	 end
	 if ( opts.verb>-1 )
		fprintf('.'); 
	 end;
  end
      
  if ( isnumeric(opts.endType) ) % time-based termination
	 t=toc;
	 if ( t-t0 > opts.endType ) fprintf('\nGot to end time. Stopping'); endTest=true; end;
  elseif( status.nevents > nEvents  ) % deal with any events which have happened
    devents=buffer('get_evt',[nEvents status.nevents-1],opts.buffhost,opts.buffport);
    if ( any(matchEvents(devents,opts.endType,opts.endValue)) )
		fprintf('\nGot exit event. Stopping');
		endTest=true;
	 end
	 mi=matchEvents(devents,opts.resetType);
	 if ( any(mi) )
		fprintf('Got reset event. Prediction filters reset.\n');
		filtstate=[]; fbuff(:)=0; dv(:)=0;
		endSample = devents(mi).sample+trlen_samp; % wait for trials worth of data post reset time
	 end;
	 if ( nargout>1 && ~isempty(opts.labelEventType) )
		mi=matchEvents(devents,opts.labelEventType);
		if ( any(mi) )
        % N.B. we assume that a label applies until the next label event and that data *must*
		  % lie within a single labels range to be valid
		  if( ~isempty(lev) ) lev=[lev;devents(mi)]; else lev=devents(mi); end;
		  [ans,si]=sort([lev.sample],'ascend'); lev=lev(si);
		  for li=1:numel(lev-1);
			 for ti=testLabi:numel(testevents);
				if ( testevents{ti}.sample-trlen_samp > lev(li+1).sample )%start after end of labelled range
				  break;
				end
				if( testevents{ti}.sample-trlen_samp > lev(li).sample ... % after start of unlab data
					 && testevents{ti}.sample         < lev(li+1).sample ) % contained in this label range
				  testevents{ti}.value = lev(li).value; % add the label info
				end				  
			 end
			 testLabi=ti;
		  end
		  lev=lev(end);
		end
	 end
    nEvents=status.nevents;
  end
end % while not endTest
return;
%--------------------------------------
function testCase()
cont_applyClsfr(clsfr,'overlap',.1)
% bias adapting output smoothing, such that mean=0 over last 100 predictions
cont_applyClsfr(clsfr,'biasFilt',@(x,s) biasFilt(x,s,exp(log(.5)/100)));
% smooth output with standardising filter, such that mean=0 and variance=1 over last 100 predictions
cont_applyClsfr(clsfr,'predFilt',@(x,s) stdFilt(x,s,exp(log(.5)/100)));

