function []=eventViewer(host,port,mtype,mval)
% view the event stream from a fieldtrip buffer
%
% []=eventViewer(host,port,startType,startVal)
%
% Inputs:
%   host -- host where the buffer is running  ('localhost')
%   port -- port where the buffer is running  (1972)
%   startType -- {{types}} cell array of match strings for matching events types
%   startValue -- {{values}} cell array of match values for matching events.  
%     N.B. Match occurs if type matches *any* startType, and value matches *any* startValue
%     [N.B. internally matchEvents is used to matching mi=matchEvents(events,startType,startValue)
%               See matchEvents for more details on the structure of startSet
if ( ~exist('buffer','file') ) run('../utilities/initPaths.m'); end;
if ( nargin<1 || isempty(host) ) host='localhost'; end;
if ( nargin<2 || isempty(port) ) port=1972; end;
if ( nargin<3 ) mtype={};  end;
if ( nargin<4 ) mval={}; end;
% wait for valid header
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
  try 
    hdr=buffer('get_hdr',[],host,port); 
  catch
    hdr=[];
    fprintf('Invalid header info... waiting.\n');
  end;
  pause(1);
end;

fs=100;
if ( isfield(hdr,'SampleRate') ) fs=hdr.SampleRate;
elseif ( isfield(hdr,'Fs') )     fs=hdr.Fs;
end

state=[]; nSamples=0; tic;
while ( true )
  [events,state]=buffer_newevents([],[],state,mtype,mval);
  if ( ~isempty(events) ) 
    fprintf('%d) %s\n',state.nsamples,ev2str(events));
  end
  if ( state.nsamples > nSamples+fs ) % once per *data* second print a '.'
    fprintf(1,'%d %d %f (samp,event,sec)\r',state.nsamples,state.nevents,toc);
    nSamples=state.nsamples;
  elseif ( state.nsamples<nSamples ) % buffer-restart detected
    fprintf(1,'Buffer restart detected\n');
    nSamples=state.nsamples;
  end
end