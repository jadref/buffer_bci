function [data,devents,state,opts]=buffer_preprocwaitData(host,port,state,varargin); 
% wait for specific events in a buffer queue and extract data associated with these events
% 
% [data,devents,state,opts]=buffer_waitData(host,port,state,varargin);
%
% Inputs:
%  host -- buffer host name
%  port -- buffer port
%  state -- [struct] current state of the waitData, use this between subsequent calls to buffer_waitData
%            to resume processing from when the previous call finished.
%           This contains 3 fields:
%           .pending -- [struct] list of events for which we are still waiting for data
%           .nevents -- [int] number of events processed so far
%           .nsamples - [int] number of samples processed so far
%           .hdr     -- [struct] the header from the buffer
%           .buffer  -- [d x T] ring-buffer of all data so far
%       OR 
%           [int 3x1] = [numSamples numEvents timeout_ms]
%               set of counts idicating how many samples/events have been processed so far 
%               in the same format as for buffer('wait_dat',state), i.e.
%               
% Options:
%  hdr  -- buffer header, got from state.hdr or read_hdr if empty. ([])
%  startSet -- {type value} OR {{types} {values}} cell array of match strings/numbers for matching 
%              events based on their type and/or value as used in matchEvents.
%               The first element of this array is the *set* of event types to match
%               The second element of this array is the *set* of event values to match
%               An event which matches one of the types *and* one of the values is counted as a match.
%                [N.B. internally matchEvents is used to matching mi=matchEvents(events,startSet{:})]
%               See matchEvents for more details on the structure of startSet
%  exitSet  -- {type value} OR {{types} {values}} cell array of type,value sets on which to *STOP* waiting for
%               more events in the same structure as for the startSet (see matchEvents for more details)
%              OR
%               'data' - stop as soon as we have the data for *ANY* matching event
%              OR
%                [int] - time to wait in ms before returning
%              Note: These types of match can be combined, e.g. 
%                 {1000 'data' {'cmd' 'stimulus'} 'end'} exits when:
%                    1000ms have pased,   OR
%                    a startEvent has data available,    OR
%                    a type:'cmd' value:'end' event is recieved,          OR 
%                    a type:'stimulus' value:'end' event is recieved
%  offset_ms/samp -- offset from start/end event from/to which we gather data in ms or samples
%                    i.e. actual data is from [start+offset(1) : start+trlen+offset(2)]
%  trlen_ms/samp  -- trial length from start event in ms or samples
%  hdr      -- [struct] cached header structure for the attached buffer
%  timeOut_ms -- [int] time to wait in buffer('wait_dat',...) call before returning  (5000)
%  preprocFn  -- {functionName, arguments} cell array of function name + arguments to apply to the raw-data before storing in the local data ring-buffer.
%             preprocFn should have the signature:
%                 [ppX,preprocstate]=function(X,preprocstate,arguments{:})
%             where arguments is the list of arguments.
%               N.B. when used we always postpend the following name,value arguments:
%                    'fs',fSample -- the current EEG sample-rate
%                    'ch_names',{nCh x } -- the current EEG channel names
%
% Outputs:
%  data  -- {cell Nx1} cell array of data segements for each recorded event
%  devents -- [struct Nx1] structure containing the events associated with each data block
%  state -- [struct] current waitData state in the same format as the input state
%            .pending - list of pending events stil waiting for new data with fields
%                    .bgns - start sample for event data
%                    .ends - end sample for event data
%                    .events - actual trigger event for each pending
%
% Examples:
% % Example 1: block until an event of type 'stimulus' is recieved and return it immeadiately:
%  [data,devents]=buffer_waitData([],[],[],'exitSet',{'stimulus'});
%
% % Example 2: get 1s of data after every event with type 'stimulus' until we recieve a 'cmd','exit' event
%  [data,devents]=buffer_waitData([],[],[],'startSet',{'stimulus'},'trlen_ms',1000,'exitSet',{'cmd' 'exit');
% % Example 2: loop geting data and processing it forever
% state=[];
% while ( true ) 
%  % block until we've got new events *and* data to process
%  % Note: we pass the 'state' back into call so no events are missed between calls.
%  [data,devents,state]=buffer_waitData([],[],state,'startSet',{'stimulus'},'trlen_ms',1000,'exitSet',{'data' 'cmd' 'exit'});
%  if ( any(matchEvents(devents,'cmd','exit')) ) % check for exit events, stop if found
%    break;
%  end
%  % process the new (non-exit) events we've got
%  if ( ~isempty(devents) )
%     process_events(data,devents);
%  end
% end
if ( nargin<1 || isempty(host) ) host='localhost'; end;
if ( nargin<2 || isempty(port) ) port=1972; end;
if ( nargin<3 || isempty(state)) % get the current info fast so don't miss things...
  status=buffer('wait_dat',[-1 -1 -1],host,port);
  state =struct('pending',[],'nevents',status.nevents,'nsamples',status.nsamples,'hdr',[],'samplebuffer',[],'preprocFn',{{}},'preprocstate',[],'prepprocstep',[]);  
end;
% TODO [] : merge opts and state, this is very confusing....
if ( numel(varargin)==1 && isstruct(varargin{1}) ) % shortcut option parsing!
  opts=varargin{1}; 
else
  opts=struct('fs',[],'startSet',[],'endSet',[],'exitSet',[],'offset_ms',[],'offset_samp',[],'trlen_ms',[],'trlen_samp',[],'hdr',[],'ch_names',[],'verb',1,'timeOut_ms',2000,'getOpts',0,'samplebuffer',-30,'prepprocstep',-15,'preprocFn',[],'preprocstate',[]);
  opts=parseOpts(opts,varargin);
  if ( opts.getOpts ) 
    data=[];devents=[];state=[]; 
    return; 
  end;
end
startSet=opts.startSet; endSet=opts.endSet; exitSet=opts.exitSet;
if ( ~iscell(startSet) ) startSet={startSet}; end;
% check for special 'data' exit type
dataExit=false; timeExit=false;
if ( isequal(exitSet,'data') ) dataExit=true; exitSet=[];
elseif( isnumeric(exitSet) && numel(exitSet)==1 ) timeExit=exitSet; exitSet=[];
elseif (iscell(exitSet))
  if ( isequal(exitSet{1},'data') ) dataExit=true; exitSet(1)=[];
  elseif ( iscell(exitSet{1}) && isequal(exitSet{1}{1},'data') ) dataExit=true; exitSet{1}(1)=[]; 
  end
  if ( ~isempty(exitSet) )
    if ( isnumeric(exitSet{1}) && numel(exitSet{1})==1 ) timeExit=exitSet{1}; exitSet(1)=[];
    elseif ( iscell(exitSet{1}) && isnumeric(exitSet{1}{1})) timeExit=exitSet; exitSet{1}(1)=[]; 
    end
  end
  if ( ~isempty(exitSet) )
    if ( isequal(exitSet{1},'data') ) dataExit=true; exitSet(1)=[];
    elseif ( iscell(exitSet{1}) && isequal(exitSet{1}{1},'data') ) dataExit=true; exitSet{1}(1)=[]; 
    end  
  end
end
if ( ~iscell(exitSet) ) exitSet={exitSet}; end;
if ( ~isempty(endSet) ) warning('endSet not supported yet! option ignored'); end;

hdr=[]; if ( isfield(state,'hdr') ) hdr=state.hdr; end; if ( isempty(hdr) ) hdr=opts.hdr; end;

% convert offsets etc from ms to samples
fs=opts.fs; 
if ( isempty(fs) && ( ~isempty(opts.trlen_ms) || ~isempty(opts.offset_ms) ) ) 
  if ( isempty(hdr) ) 
    try;
      hdr=buffer('get_hdr',[],host,port); 
    catch;
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);      
      fprintf('Error: Header not set!  Is the amplifier connected?\nTry again later.\n');
    end
  end
  fs=hdr.fsample; 
elseif ( isempty(hdr) && ~isempty(fs) ) 
  hdr=struct('fsample',fs,'nevents',[],'nsamples',[]);
end;
ch_names=opts.ch_names;
if( isempty(ch_names) && isfield(hdr,'labels') )
  ch_names=hdr.labels;
end
% Use the given trial length to over-ride the status info if wanted
if ( ~isempty(opts.trlen_ms) || ~isempty(opts.offset_ms) )
  if ( isempty(fs) ) error('no fs: cant compute ms2samp'); end;
  samp2ms = 1000/fs; ms2samp = fs/1000;
  opts.trlen_samp = floor(opts.trlen_ms*ms2samp);
end
% offset if wanted
if ( ~isempty(opts.offset_ms) ) 
   if ( numel(opts.offset_ms)<2 ) 
      opts.offset_ms=[-opts.offset_ms opts.offset_ms]; 
   end;
   samp2ms = 1000/fs; ms2samp = fs/1000;
   opts.offset_samp = ceil(opts.offset_ms*ms2samp);
end

% now run the loop watching for the events we care about and accumulating the data

% extract state from the input options, or ignore anything before now if not set
nsamples=[]; 
if( isfield(state,'nsamples')) nsamples=state.nsamples; end;
if( isempty(nsamples) ) nsamples=hdr.nsamples; end;
nevents =[];
if( isfield(state,'nevents')) nevents=state.nevents; end;
if( isempty(nevents)  ) nevents=hdr.nevents; end; 
% if nothing else set, then use the *current* info as start point
if ( isempty(nsamples) && isempty(nevents) ) 
  status=buffer('wait_dat',[-1 -1 -1],host,port);
  nsamples=status.nsamples; nevents=status.nevents;
end
pending =[];
if ( isfield(state,'pending') ) pending=state.pending; end;
if ( isempty(pending) )  pending=struct('events',[],'bgns',[],'ends',[]); end

%------------- initialize the ring-buffer + pre-slice functions
samplebuffer=opts.samplebuffer;
if ( isfield(state,'samplebuffer') && ~isempty(state.samplebuffer) ) 
  samplebuffer=state.samplebuffer; 
end;
if( numel(samplebuffer)==1 && samplebuffer<0 )
  samplebuffer=ceil(fs*abs(samplebuffer));
end;
prepprocstep=opts.prepprocstep;
if ( isfield(state,'prepprocstep') ) prepprocstep=state.prepprocstep; end;
if( prepprocstep<0 ) % convert seconds -> samples
  if( numel(samplebuffer)==1 )  totbuffsamp=samplebuffer; else totbuffsamp=size(samplebuffer,2); end;
  prepprocstep=totbuffsamp/abs(prepprocstep);
end
preprocFn   =opts.preprocFn;
if( isfield(state,'preprocFn') && ~isempty(state.preprocFn) ) 
   preprocFn=state.preprocFn; 
end;
preprocstate=opts.preprocstate;
if( isfield(state,'preprocstate') && ~isempty(state.preprocstate) ) 
   preprocstate=state.preprocstate; 
end;

global bufferClient;
if ( isempty(bufferClient) ) % different data response format for java vs. mex version
  emptydat= struct('nchans',[],'nsamples',0,'data_type',10,'bufsize',0,'buf',[]); % for non-data events
else
  emptydat= struct('buf',[]);
end
data=[]; devents=[];  exitEvent=false; exitSamp=0; 
timeout_ms=opts.timeOut_ms; if ( timeExit ) timeout_ms=min(timeout_ms,timeExit); end;
if ( timeExit || opts.verb>0 ) t0=getTime(); end;
while( ~exitEvent ) 
  endsamp = inf; 
  if( ~isempty(pending.events) )
    endsamp = min(endsamp,min(pending.ends));
  end;
  if( prepprocstep>0 ) % stop early if full preproc-block
    endsamp = min(endsamp,nsamples+prepprocstep);
  end; 
  
  % blocking wait for either all the data to be ready or for a new event to be recieved  
  % update info about what we've seen so far
  onevents=nevents;
  if ( opts.verb>=0 ) t1=getTime(); end;
  % N.B. nevents-1... because test is >nevents events!
  try
    status=buffer('wait_dat',[endsamp nevents timeout_ms],host,port);
  catch % catch buffer failures and restart
    warning('Buffer crash!');
    break;
  end
  if ( status.nevents < onevents )
      warning('Buffer restarted!')
      nevents=0; endsamp=status.nsamples;
  end;
  if ( opts.verb>=0 ) 
    t=getTime()-t1; 
    if ( t>=opts.timeOut_ms/1000*.9 ) 
      fprintf(' %5.3f seconds, %d samples %d events\r',t,status.nsamples,status.nevents);
      if ( ispc() ) drawnow; end; % re-draw display
    end;
  end;

  % TODO []: make this only call when there is a need for the new data...
       % get the new data, apply the pre-processor and add to the ring buffer
  if( ~isempty(samplebuffer) && status.nsamples > nsamples )
    blkIdx = nsamples:status.nsamples-1;
    try
      blkdat = buffer('get_dat',[blkIdx(1) blkIdx(end)]);
    catch;
      fprintf('Warning: get_dat failed, assuming missing samples');
      blkIdx = (-2*fs:-1)+status.nsamples; % try for 2s data
      blkdat = buffer('get_dat',[blkIdx(1) blkIdx(end)]);
    end
    if( opts.verb>2 ) fprintf('Got data: [ %d - %d ]\n',blkIdx(1),blkIdx(end)); end   
    blkdat = blkdat.buf;
    %oblkdat=blkdat;
    if( size(blkdat,2) < numel(blkIdx) )
      fprintf('Warning: missing some samples.... assuming last OK');
      blkIdx = blkIdx(:,end-size(blkdat,2)+1:end);
    end
    if( ~isempty(preprocFn) )
      if( opts.verb>2 ) fprintf('Applying preprocFn'); end
      % post-pend the eeg info
      [blkdat,preprocstate] = feval(preprocFn{1},blkdat,preprocstate,preprocFn{2:end},'fs',fs,'ch_names',ch_names);
    end
    if( numel(samplebuffer)==1 )% init the sample buffer to the right size
      % make the buffer
      samplebuffer = zeros(size(blkdat,1),samplebuffer);
    end
    samplebuffer(:,mod(blkIdx-1,size(samplebuffer,2))+1)=blkdat;
    %cla;plot(samplebuffer(1,:)); hold on; plot(oblkdat(1,:),'r'); drawnow;
    nsamples=status.nsamples;
  end
  
  % scan the new events for ones we are interested in
  if ( status.nevents>nevents ) % new events to process
    try % guard against old events drapped from the buffer
      events=buffer('get_evt',[nevents status.nevents-1],host,port); 
    catch
      warning(sprintf('Potentially lost %d events due to long gap between calls!',status.nevents-50-nevents));
      nevents=max(nevents,status.nevents-50);
      events=buffer('get_evt',[nevents status.nevents-1],host,port);
    end
    if( numel(events) < status.nevents-1-nevents )
       warning(sprintf('Missing %d events!',status.nevents-nevents));      
    end
    events=events(:);% get the new events
    mi    =matchEvents(events,startSet{:});
    startevents=[];
    if ( any(mi) )
      startevents=events(mi); events=events(~mi);
    end
    if ( ~isempty(startevents) ) % some events matched so we need to get their data
      bgns=zeros(size(startevents)); ends=bgns;
      % construct a new event with the datarange defined
      for ei=1:numel(startevents); % N.B. events are returns in *reverse* temporal order, i.e. latest first!
        % N.B. we assume: start_samp = sample+offset; end_samp=sample+offset+duration;
        if ( ~isempty(opts.trlen_samp) )
          startevents(ei).duration=opts.trlen_samp;
        else % if no trial length then duration is 0
          startevents(ei).duration=0;
        end
        if ( ~isempty(opts.offset_samp) )          
          startevents(ei).offset  = opts.offset_samp(1);
          startevents(ei).duration= startevents(ei).duration - opts.offset_samp(1); 
          if ( numel(opts.offset_samp)>1 )
            startevents(ei).duration = startevents(ei).duration+opts.offset_samp(2);
          end
        end
        bgns(ei,1)=startevents(ei).sample+startevents(ei).offset;
        ends(ei,1)=startevents(ei).sample+startevents(ei).offset+startevents(ei).duration;
        if ( opts.verb>0 ) fprintf('%d) recording event: %s\n',status.nsamples,ev2str(startevents(ei))); end
      end
      if( isempty(pending.events) )
        pending.events=startevents; % discard other events
        pending.bgns  =bgns;
        pending.ends  =ends;
      else
        pending.events=cat(1,pending.events,startevents); % discard other events
        pending.bgns  =cat(1,pending.bgns,bgns);
        pending.ends  =cat(1,pending.ends,ends);
      end
    end
    % update info about number events/samples we've processed
    nevents=status.nevents;      

    % check for exit events
    if ( ~isempty(events) && ~isempty(exitSet) && iscell(exitSet) )      
      mi=matchEvents(events,exitSet{:});
      if ( any(mi) ) 
        if ( opts.verb>0 )
          fprintf('%d) Got an exit event, exiting...event: %s\n',nsamples,ev2str(events(find(mi,1)))); 
        end
        if ( isempty(data) )
          if ( sum(mi)==1 ) data=emptydat; else data=repmat(emptydat,sum(mi),1); end;
          devents=events(mi);
        else
          if( sum(mi)==1 )  data=cat(1,data,emptydat); else data=cat(1,data,repmat(emptydat,sum(mi),1)); end;
          devents=cat(1,devents,events(mi));
       end
          exitEvent=true; exitSamp = min([events(mi).sample]);
      end
    end
  end  % new events
  
  if ( ~isempty(pending.events) )
    if( exitEvent && exitSamp>0 ) % only events which finished before the sample of the exit Event
      finEi = find(pending.ends < status.nsamples & pending.bgns<= exitSamp); % enough data and started before exitEvent
    else
      finEi = find(pending.ends < status.nsamples | pending.bgns==pending.ends);
    end
    if ( ~isempty(finEi) )
      % get the data associated with these events, 
      % N.B. could be clever here with a data cache to prevent getting the same data many times
      for i=1:numel(finEi);
        ei=finEi(i); 
        if ( opts.verb>0 ) fprintf('%d) saving event: %s\n',status.nsamples,ev2str(pending.events(ei))); end
        dat=struct('buf',[]);
        if ( pending.bgns(ei)<pending.ends(ei) ) % only get dat if want data
          if( ~isempty(samplebuffer) )
            sampIdx = pending.bgns(ei):pending.ends(ei)-1;  % WARNING: check for off-by-one
            dat.buf = samplebuffer(:,mod(sampIdx-1,size(samplebuffer,2))+1);
          else % get directly from the ft-buffer
            try
              dat=buffer('get_dat',[pending.bgns(ei) pending.ends(ei)-1],host,port);
            catch
              warning('Missed data!!!!!!!!!!');            
            end
          end
        else
        end
        if ( isempty(data) )
          data   =dat;
          devents=pending.events(ei);          
        else
          devents(end+1,1)       =pending.events(ei);
          data(numel(devents),1) =dat; % ensure data and events remain aligned, even if no data saved
        end
      end
      % remove these ones from the pending queue
      pending.events(finEi)=[];
      pending.ends(finEi)=[];
      pending.bgns(finEi)=[];
      % exit if we should when data has been received
      if( dataExit ) exitEvent=true; exitSamp=devents(end).sample; end;
    end
  end % if pending events 
  % check for time based exit events
  if ( timeExit && (getTime()-t0)*1000>timeExit ) 
    exitEvent=true; exitSamp=0;
  end;
end

% record the updated internal state
state.hdr           =hdr;
state.pending       =pending;
state.nevents       =status.nevents;
state.nsamples      =status.nsamples;
state.samplebuffer  =samplebuffer;
state.prepprocstep  =prepprocstep;
state.preprocFn     =preprocFn;
state.preprocstate  =preprocstate;
return;

function t=getTime()
if (usejava('jvm') ) 
    t= javaMethod('currentTimeMillis','java.lang.System')/1000;
else
    t= clock()*[0 0 86400 3600 60 1]'; % in seconds
end 

%-----------------------
function testCase();
% in another matlab!
buffer_signalproxy();
% OR
% put a fake header so we don't need a signal proxy to proceed
hdr=struct('fsample',100,'channel_names',{{'Cz'}},'nchans',1,'nsamples',0,'nsamplespre',0,'ntrials',1,'nevents',0,'data_type',10);
buffer('put_hdr',hdr,buffhost,buffport);

% setup the path
addpath(fullfile(pwd,'ft_buffer','buffer','matlab'));

                                % now wait for data here
trlen_ms=3000;
[data,devents]=buffer_preprocwaitData([],[],[],'startSet',{{'a' 'b' 'c' 'd'}},'exitSet',{'quit'},'trlen_ms',trlen_ms,'verb',1)
                                % with a high-pass filter
[data,devents]=buffer_preprocwaitData([],[],[],'startSet',{{'a' 'b' 'c' 'd'}},'exitSet',{'quit'},'trlen_ms',trlen_ms,'preprocFn',{'filterFilt' 'filter',{'buttersos',8,.1,'high'}},'verb',1)
                                % test with bandpass filter
[data,devents]=buffer_preprocwaitData([],[],[],'startSet',{{'a' 'b' 'c' 'd'}},'exitSet',{'quit'},'trlen_ms',trlen_ms,'preprocFn',{'filterFilt' 'filter',{'buttersos',8,[.1,27],'bandpass'}},'verb',1)
clf;images3d(cat(3,data.buf),1);saveaspdf('~/sd-card/fig');
