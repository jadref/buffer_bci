function evt=mkEvent(type,value,sample,offset,duration)
% make a ft-buffer event

%  evt=mkEvent(type,value,sample,offset,duration)
% 
%Inputs:
%  type -- {str} event type
%  value -- value for this event ([])
%  sample -- [int] time of this event in samples   ([current sample number])
%           N.B. if not specified current sample number is used!
%  offset -- [int] 0-time offset in samples (relative to sample) for this event
%  duration -- [int] duration (in samples) for this event
global exevt; evt=exevt;
if ( nargin<5 ) evt.duration=0; else evt.duration=duration;end;
if ( nargin<4 ) evt.offset=0; else evt.offset=offest; end;
if ( nargin<3 ) evt.sample=-1; else evt.sample=sample; end;
if ( nargin<2 ) evt.value=[]; else 
  if ( iscell(value) && ischar(value{1}) ) evt.value=str2buff(value); else evt.value=value; end;
end;
evt.type=type;
