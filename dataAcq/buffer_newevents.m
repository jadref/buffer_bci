function [events,state,nevents,nsamples]=buffer_newevents(host,port,state,mtype,mval,timeOut_ms)
% Get new events of matching type from the ft_buffer
%
% [events,state]=buffer_newevents(host,port,state,startType,startVal,timeOut_ms)
% Inputs:
%  host -- buffer host name
%  port -- buffer port
%  state -- current state of the newevents, use this between subsequent calls to buffer_newevents
%            to resume processing events from when the previous call finished
%       Format:
%           [1x1 int]   - count of the number of events processed so far
%       OR 
%           [int 3x1] = [numSamples numEvents timeout_ms]
%               set of counts idicating how many samples/events have been processed so far 
%               in the same format as for buffer('wait_dat',state), i.e.
%       OR
%          [struct] - This contains 3 fields:
%           .nevents -- [int] number of events processed so far
%           .nsamples - [int] number of samples processed so far
%  mType -- {{types}} cell array of match strings for matching events types
%  mVal  -- {{values}} cell array of match values for matching events.  
%     N.B. Match occurs if type matches *any* startType, and value matches *any* startValue
%     [N.B. internally matchEvents is used to matching mi=matchEvents(events,startType,startValue)
%               See matchEvents for more details on the structure of startSet
%  timeOut_ms -- [int] time to wait in buffer('wait_dat',...) call before returning  (5000)
%
% Outputs:
%  devents -- [struct Nx1] structure containing the matched events
%  state -- [struct] current newevents state in the same format as the input state
if ( nargin<1 || isempty(host) ) 
  global ft_buff;
  if ( ~isempty(ft_buff) ) host=ft_buff.host ; else host='localhost'; end; 
end
if ( nargin<2 || isempty(port) ) 
  global ft_buff;
  if ( ~isempty(ft_buff) ) port=ft_buff.port ; else port=1972; end;
end;
if ( nargin<3 || isempty(state) ) state=-1; end;
if ( nargin<4 || isempty(mtype) ) mtype='*'; end;
if ( nargin<5 || isempty(mval)  ) mval ='*'; end;
if ( nargin<6 || isempty(timeOut_ms) ) timeOut_ms=5000; end;

% get the set of possible events
if ( isstruct(state) ) nevents=state.nevents; 
elseif ( numel(state)==3 ) nevents=state(2); 
elseif ( numel(state)==1 ) nevents=state(1);
else warning('Dont understand state format');
end
if ( isempty(nevents) || nevents<=0 ) % first call
  status=buffer('wait_dat',[-1 -1 -1],host,port); nevents=status.nevents;
end; 
events=[]; 
timeToGo_ms=timeOut_ms;
while ( isempty(events) ) % until there are some matching events
  % wait for any new events, keeping track of elapsed time for time-based exits
  tic;status=buffer('wait_dat',[inf nevents timeToGo_ms],host,port);timeToGo_ms=timeToGo_ms-toc*1000;
  if( status.nevents>nevents )
    % N.B. event range is counted from start -> end-1!
    % N.B. event Id start from 0
    events=buffer('get_evt',[max(nevents,status.nevents-50) status.nevents-1],host,port); 
    % filter for the event types we care about
    mi=matchEvents(events,mtype,mval);
    events=events(mi);
  end
  nevents=status.nevents;
  if ( timeToGo_ms<=0 ) break; end;
end
state=status;
nevents=state.nevents;nsamples=state.nsamples;
return;
