function [data,devents,pending,opts]=buffer_catData(host,port,varargin);
% wait for buffer events and get the data associated with them
%
%  [data,devents]=buffer_catData(host,port,varargin);
%
% Inputs:
%  host -- buffer host name
%  port -- buffer port
% Options:
%  hdr  -- buffer header, got from read_hdr if empty. ([])
%  startSet -- {2x1} cell array of match strings/numbers for matching 
%              events based on their type and/or value as used in matchEvents.
%               See matchEvents for details
%  endSet   -- {2x1} cell array of data range ending markers.  
%               N.B. currently *NOT* supported
%  exitSet  -- {2x1} cell array of type,value sets on which to *STOP* waiting for
%               more events.
%              OR
%               'data' - stop as soon as we have *ANY* data
%  offset_ms/samp -- offset from start/end event from/to which we gather data in ms or samples
%  trlen_ms/samp  -- trial length from start event in ms or samples
%  hdr      -- [struct] cached header structure for the attached buffer
%  timeOut_ms -- [int] time to wait for new data before returning  (5000)
%  pending  -- [struct] cache of previously matched events for which we are still waiting for data
%
% Examples:
% % get 1s of data after every stimulus event until we recieve a 'cmd','exit' event
%  [data,devents]=buffer_catData([],[],'startSet',{{'stimulus'} []},'trlen_ms',1000,'exitSet',{{'cmd'} {'exit'});
% % loop geting data and processing it forever
% pending=[];
% while ( true ) 
%  
%  


mdir=fileparts(mfilename('fullfile'));
addpath(fullfile(mdir,'ft_buffer','matlab'));
opts=struct('fs',[],'startSet',[],'endSet',[],'exitSet',[],'offset_ms',[],'offset_samp',[],'trlen_ms',[],'trlen_samp',[],'hdr',[],'verb',0,'timeOut_ms',5000,'pending',[]);
[opts,varargin]=parseOpts(opts,varargin);
if ( nargin<2 || isempty(port) ) port=1972; end;
if ( nargin<1 || isempty(host) ) host='localhost'; end;
if ( numel(varargin)>0 ) opts.startSet=varargin{1}; end;
if ( numel(varargin)>1 ) opts.endSet  =varargin{2}; end;

startSet=opts.startSet; endSet=opts.endSet; exitSet=opts.exitSet;
if ( ~iscell(startSet) ) startSet={startSet}; end;
if ( ~isempty(endSet) ) warning('endSet not supported yet! option ignored'); end;

hdr=opts.hdr; if ( isempty(hdr) ) hdr=buffer('get_hdr',[],host,port); end;

% convert offsets etc from ms to samples
fs=opts.fs; if ( isempty(fs) ) fs=hdr.fsample; end;
samp2ms = 1000/fs; ms2samp = fs/1000;
% Use the given trial length to over-ride the status info if wanted
if ( ~isempty(opts.trlen_ms) )
   if ( isempty(fs) ) error('no fs: cant compute ms2samp'); end;
   opts.trlen_samp = floor(opts.trlen_ms*ms2samp);
end
% offset if wanted
if ( ~isempty(opts.offset_ms) ) 
   if ( numel(opts.offset_ms)<2 ) 
      opts.offset_ms=[-opts.offset_ms opts.offset_ms]; 
   end;
   opts.offset_samp = ceil(opts.offset_ms*ms2samp);
end

% now run the loop watching for the events we care about and accumulating the data
nsamples=hdr.nsamples; nevents=hdr.nevents; % num samples/events before now -> ignored!
pending=opts.pending; if ( isempty(pending) ) pending=struct('events',[],'bgns',[],'ends',[]); end;
data={}; devents=[];
while ( true )
  
  if ( ~isempty(pending.events) ) endsamp=min(pending.ends); else endsamp=-1; end;
  % blocking wait for either all the data to be ready or for a new event to be recieved  
  onevents=nevents; 
  if ( opts.verb>0 ) tic; end;
  status=buffer('wait_dat',[endsamp nevents+1 opts.timeOut_ms],host,port);
  if ( opts.verb>0 ) 
    t=toc; 
    if ( t>=opts.timeOut_ms/1000 ) toc, end; 
  end;
  
  % scan the new events for ones we are interested in
  if ( status.nevents>nevents ) % new events to process
    events=buffer('get_evt',[nevents status.nevents-1],host,port); nevents=status.nevents;
    events=events(:);% get the new events
    startEi=matchEvents(events,startSet{:});
    if ( any(startEi) ) % some events matched so we need to get their data
      startEIdx=find(startEi); 
      keep=true(size(startEIdx)); bgns=zeros(size(keep)); ends=bgns;
      for ei=1:numel(startEIdx); % construct a new event with the datarange defined
        % N.B.we assume: start_samp = sample+offset; end_samp=sample+offset+duration;
          event=events(startEIdx(ei));
          if ( ~isempty(opts.trlen_samp) )
          event.duration=opts.trlen_samp;
        end
        if ( ~isempty(opts.offset_samp) )          
          event.offset  = opts.offset_samp(1);
          event.duration= event.duration - opts.offset_samp(1); 
          if ( numel(opts.offset_samp)>1 )
            event.duration = event.duration+opts.offset_samp(2);
          end
        end
        bgns(ei,1)=event.sample+event.offset;
        ends(ei,1)=event.sample+event.offset+event.duration;
        if ( opts.verb>0 ) fprintf('recording event: %s\n',ev2str(startevents(ei))); end
        % write back the modified event info
        if ( keep(ei) ) events(startEIdx(ei))=event; end;
      end
      startEi(startEIdx(~keep))=false;
      startevents=events(startEi);bgns=bgns(keep); ends=ends(keep);
      
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
    events=events(~startEi);
    
    % check for exit events
    if ( ~isempty(opts.exitSet) && iscell(opts.exitSet) )      
      mi=matchEvents(events,ops.exitSet{:});
      if ( any(mi) ) 
        if ( opts.verb>0 ) fprintf('Got an exit event, exiting'); end;
        break; 
      end
    end      
  end % if new events
  
  % get the data for any pending events for which all the data is available
  if ( ~isempty(pending.events) )
    finEi = find(pending.ends < status.nsamples);
    if ( ~isempty(finEi) )
      % get the data associated with these events, 
      % N.B. could be clever here with a data cache to prevent getting the same data many times
      for i=1:numel(finEi);
        ei=finEi(i); 
        if ( opts.verb>0 ) fprintf('saving event: %s\n',ev2str(pending.events(ei))); end;
        dat=buffer('get_dat',[pending.bgns(ei) pending.ends(ei)],host,port);
        if ( isempty(data) )
          data={dat};
          devents=pending.events(ei);          
        else
          data{end+1}=dat;
          devents(end+1)=pending.events(ei);
        end
      end
      % remove these ones from the pending queue
      pending.events(finEi)=[];
      pending.ends(finEi)=[];
      pending.bgns(finEi)=[];
      % exit if we should when data has been received
      if( strcmp(opts.exitSet,'data') ) break; end;
    end
  end  
end
return;
%-----------------------
function testCase();
% in another matlab!
buffer_signalproxy();
buffer_catData([],[],'startSet',{{'sim' 'keyboard'} []},'trlen_ms',1000,'offset_ms',[-200 0],'verb',1)

% get 0-600 ms after a stimulus event
[data,devents]=buffer_catData([],[],'startSet',{{'stimulus'}},'trlen_ms',600,'offset_ms',0,'verb',1);
% now train and erp classifer on this data
X=cat(3,data{:}); Y=[devents.value];