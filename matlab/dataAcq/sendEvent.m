function [evt]=sendEvent(type,value,sample,offset,duration,host,port)
% send an event to the ft-buffer
%
% [evt]=sendEvent(evt,host,port)
% [evt]=sendEvent(type,value,sample,offset,duration,host,port)
%
% Inputs:
%  evt  -- [struct] fieldtrip buffer event structure
%  type -- {str} event type
%  value -- value for this event ([])
%  sample -- [int] time of this event in samples   ([current sample number])
%           N.B. if not specified, or sample=[], or sample<0 then sample=current sample number!
%  offset -- [int] 0-time offset in samples (relative to sample) for this event (0)
%  duration -- [int] duration (in samples) for this event                    (0)
%  host -- [str] host where the buffer is running
%  port -- [int] port where the buffer is running
%global exevt;
%evt=exevt;
if ( isstruct(type) ) % struct call type
    evt=type;
    if ( nargin<3 ) host=[]; port=[]; end;
else % fields call type
	evt=struct('sample',-1,'type',[],'value',[],'offset',0,'duration',0);
    if ( nargin<5 ) evt.duration=0; else evt.duration=duration;end;
    if ( nargin<4 ) evt.offset=0;   else evt.offset=offset; end;
    if ( nargin<3 ) evt.sample=-1;  else evt.sample=sample; end;
    if ( nargin<2 ) evt.value =[];  else evt.value =value;  end;
    evt.type=type;
    if ( nargin<6 ) host=[]; port=[]; end;
end
%if ( evt.sample<0 ) evt.sample=round(getsampTime()); end;
% value type conversions for sending
if ( iscell(evt.value) && ischar(evt.value{1}) ) evt.value=str2buff(evt.value); 
elseif ( islogical(evt.value) ) evt.value=int8(evt.value); %logical conversion
elseif ( isempty(evt.value) )   evt.value=''; % empty string, can't send empty matrices
end
if ( nargout>0 ) % BODGE to avoid expensive type conversion if not needed
  evt=buffer('put_evt',evt,host,port);
else
  buffer('put_evt',evt,host,port);
end