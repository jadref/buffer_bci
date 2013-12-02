function [events,nevents,nsamples]=buffer_newevents(mtype,mval,nevents,host,port)
% Get new events of matching type from the ft_buffer
%
% [events,nevents,nsamples]=buffer_newevents(mtype,mval,[nevents,host,port])
if ( nargin<1 || isempty(mtype) ) mtype='*'; end;
if ( nargin<2 || isempty(mval)  ) mval ='*'; end;
if ( nargin<3 || isempty(nevents) ) nevents=0; end;
if ( nargin<4 || isempty(host) ) 
  global ft_buff;
  if ( ~isempty(ft_buff) ) host=ft_buff.host ; else host='localhost'; end; 
end
if ( nargin<5 || isempty(port) ) 
  global ft_buff;
  if ( ~isempty(ft_buff) ) port=ft_buff.port ; else port=1972; end;
end;

% get the set of possible events
if ( nevents<=0 ) wait=[-1 -1 -1]; else wait=[inf nevents 1000]; end;
status=buffer('wait_dat',wait,host,port);
events=[];
if( status.nevents>nevents )
    % N.B. event range is counted from start -> end-1!
    % N.B. event Id start from 0
    events=buffer('get_evt',[max(nevents,status.nevents-50) status.nevents-1],host,port); 
    % filter for the event types we care about
    mi=matchEvents(events,mtype,mval);
    events=events(mi);
end
nevents =status.nevents;
nsamples=status.nsamples;
return;
