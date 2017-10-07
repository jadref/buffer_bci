function [data,devents,state]=cont_calibrate(buffhost,buffport,state,varargin)
% continuously apply this classifier to the new data
%
%  [data,devents,allevents]=cont_calibrate(buffhost,buffport,state,varargin)
%
% Options:
%  buffhost, buffport
%
%  exitType, exitValue  -- event type and value to match to stop giving feedback   ('stimulus.test','end')
%  predEventType -- 'str' event type to use for the generated prediction events  ('classifier.prediction')
%  trlen_ms/samp -- [float] length of trial to apply classifier to               ([])
%                     if empty, then = windowFn size used in the classifier training
%  overlap       -- [float] fraction of trlen_samp between successive classifier predictions, i.e.
%                    prediction at, t, t+trlen_samp*overlap, t+2*(trlen_samp*overlap), ...
%  step_ms       -- [float] time between classifier predictions                 ([])

opts=struct('buffhost','localhost','buffport',1972,'hdr',[],...
            'startSet',{'stimulus.target'},'endSet',[],...
            'exitType',{{'stimulus.test' 'stimulus.testing' 'sigproc.reset'}},'exitValue','end','verb',0,...
				'labelEventType',[],...
            'maxFrameLag',3,...
            'trlen_ms',[],'trlen_samp',[],'overlap',.5,'step_ms',[]);
[opts]=parseOpts(opts,varargin);

trlen_samp=opts.trlen_samp;
if ( isempty(trlen_samp) )
  trlen_samp=0;
  if ( ~isempty(opts.trlen_ms) )
    if(~isempty(opts.hdr)) fs=opts.hdr.fsample;
    else opts.hdr=buffer('get_hdr',[],opts.buffhost,opts.buffport); fs=opts.hdr.fsample;
    end;
    trlen_samp = opts.trlen_ms /1000 * fs;
  end
end;
% get time to between data packets
if ( ~isempty(opts.step_ms) )
  if(~isempty(opts.hdr)) fs=opts.hdr.fsample;
  else opts.hdr=buffer('get_hdr',[],opts.buffhost,opts.buffport); fs=opts.hdr.fsample;
  end;
  step_samp = round(opts.step_ms/1000 * fs);
else
  step_samp = round(trlen_samp * opts.overlap);
end

% get the current number of samples, so we can start from now
status=buffer('wait_dat',[-1 -1 -1],opts.buffhost,opts.buffport);
nEvents=status.nevents; nSamples=status.nSamples; % most recent event/sample seen
endSample=nSamples+trlen_samp; % last sample of the first window to apply to

nEpochs=0;
endTest=false;
tic;t0=0;t1=t0;
while( ~endTest )

  % block until new data to process
  status=buffer('wait_dat',[endSample -1 opts.timeout_ms],opts.buffhost,opts.buffport);
  if ( status.nSamples < nSamples )
    fprintf('Buffer restart detected!');
    nSamples =status.nSamples;
	  endSample=nSamples+trlen_samp;
    continue;
  end
  nSamples=status.nSamples; % keep track of last sample seen for re-start detection
  % grab any new events which have happened
  newevents=[];
  if( status.nevents > nEvents  ) % deal with any events which have happened
    newevents=buffer('get_evt',[nEvents status.nevents-1],buffhost,buffport);
    nEvents=status.nevents; % update record of which events have been got from buffer
    
    % extract any useful labelling information
  	mi=matchEvents(newevents,opts.startSet{:});
  	if( any(mi) ) bgnEvents=cat(1,bgnEvents,newevents(mi)); end;
  	if(~isempty(opts.endSet))
  	  mi=matchEvents(newevents,opts.endSet{:});
  	  if( any(mi) ) endEvents=cat(1,endEvents,newevents(mi));
  	end;
	end
    
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
    data{nEpochs} = buffer('get_dat',[fin(si)-trlen_samp fin(si)-1],opts.buffhost,opts.buffport);
    devents(nEpochs) = defaultEvent;
    
    % add labelling information if available
    % TODO: search for event with right sample number, make new label value, include latch mode...

    if ( opts.verb>1 ) fprintf('Got data @ %d->%d samp\n',fin(si)-trlen_samp,fin(si)-1); end;
  end
      
  if ( isnumeric(opts.endType) ) % time-based termination
	 t=toc;
	 if ( t-t0 > opts.endType ) fprintf('\nGot to end time. Stopping'); endTest=true; end;
  elseif ( any(matchEvents(newevents,opts.exitType,opts.exitValue)) )
    fprintf('\nGot exit event. Stopping');
	  endTest=true;
  end
end % while not endTest
return;
%--------------------------------------
function testCase()
