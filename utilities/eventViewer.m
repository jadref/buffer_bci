function []=eventViewer(host,port,excludeSet)
% view the event stream from a fieldtrip buffer
%
% []=eventViewer(host,port,excludeSet)
%
% Inputs:
%   host -- host where the buffer is running  ('localhost')
%   port -- port where the buffer is running  (1972)
%   excludeSet -- {2x1} match set for events *not* to display         ([])
%              format is as used in matchEvents but basically consists of pairs of types and values
%              {type value} OR {{types} {values}}
%               See matchEvents for details
run ../utilities/initPaths;
if ( nargin<1 || isempty(host) ) host='localhost'; end;
if ( nargin<2 || isempty(port) ) port=1972; end;
if ( nargin<3 ) excludeSet={}; end;
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

nevents=[]; nSamples=0; tic;
while ( true )
  [events,nevents,nsamples]=buffer_newevents([],[],nevents,host,port);
  if ( ~isempty(events) ) 
    if ( ~isempty(excludeSet) )
      mi=matchEvents(events,excludeSet{:});
      events=events(~mi);
    end
    fprintf('%d) %s\n',nsamples,ev2str(events));
  end
  if ( nsamples > nSamples+fs ) % once per *data* second print a '.'
    fprintf(1,'%d %d %f (samp,event,sec)\r',nsamples,nevents,toc);
    nSamples=nsamples;
  elseif ( nsamples<nSamples ) % buffer-restart detected
    fprintf(1,'Buffer restart detected\n');
    nSamples=nsamples;
  end
end