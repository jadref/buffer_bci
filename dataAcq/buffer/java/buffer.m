function [varargout]=buffer(cmd,detail,host,port)
% BUFFER manages and accesses the realtime data acquisition buffer
% This function is implented as a mex file.
%
% Use as
%   retval = buffer(cmd, detail, host, port)
%
% To read data from a buffer server over the network
%   hdr = buffer('get_hdr', [],     host, port)
%   dat = buffer('get_dat', datsel, host, port)
%   evt = buffer('get_evt', evtsel, host, port) %N.B. only 1-d array event values are supported
%
% The selection for data and events should be zero-offset and contain
%   datsel = [begsample endsample]
%   evtsel = [begevent  endevent ]
%
% To write data to a buffer server over the network
%   buffer('put_hdr', hdr, host, port)
%   buffer('put_dat', dat, host, port)
%   buffer('put_evt', evt, host, port)
%
% To wait (i.e. block) until a threshold number of samples or events have been recieved, 
% or timeout is passed
%   sampevents = buffer('wait_dat', threshold, host, port)
% The thresholds are zero-offset and contain
%   threshold = [nsamples nevents timeout]
% setting any threshold to -1 makes it ignored.  All thresholds=-1 returns immeadiately
% 
% Clock alignment extensions
%   buffer('get_samp', [],  host, port) % get the estimated sample count for the current real-time-clock time
%   buffer('get_samp', t,   host, port) % get the estimated sample count at time 't' from the real-time-clock
%   buffer('get_time', [],  host, port) % get the current real-time-clock time
%   buffer('sync_clk',wait, host, port) % sync the real-time and sample clocks with points at wait
%   buffer('con', [], host, port) % create connection to host/port
%
% N.B. if the GLOBAL variable TESTING=true, then returns immediately for all cases with an empty structure
%      useful for stimulus development without a buffer/signal proxy running
%
% N.B. datatype IDs
%	 CHAR    = 0;	 UINT8   = 1;	 UINT16  = 2;	 UINT32  = 3;	 UINT64  = 4;	 INT8    = 5;
%	 INT16   = 6;	 INT32   = 7;	 INT64   = 8;	 FLOAT32 = 9;	 FLOAT64 = 10;
    
global bufferClient TESTING; % globals used to hold the java object, and connection info
if ( nargin<1 ) cmd=[]; end;
if ( nargin<2 ) detail=[]; end;
if ( nargin<3 ) host=[]; end;
if ( nargin<4 ) port=[]; end;
if ( isequal(TESTING,true) ) 
  switch lower( cmd ) 
   case 'get_hdr'; % simulate a header
      res=struct('nChans',0,'nSamples',0,'nEvents',0,'fSample',0,'labels',{{}},'dataType',10);
   case 'put_evt';  res=detail; % simulate put
	case 'get_samp'; res=-1; % simulate sample get
   case 'get_time'; res=javaMethod('currentTimeMillis','java.lang.System');
     if( exist('OCTAVE_VERSION')) res=res.doubleValue(); end;
   otherwise; res=struct();
  end
  varargout{1}=res;
  return; 
end;

if ( isempty(bufferClient) )
  buffer_bcidir=fileparts(fileparts(fileparts(mfilename('fullpath')))); % buffer_bci directory
  bufferjavaclassdir = fileparts(mfilename('fullpath'));
  bufferjar = fullfile(bufferjavaclassdir,'BufferClient.jar');
  if ( exist(bufferjar,'file') )
    if ( ~any(strcmp(javaclasspath,bufferjar)) )
      warning('Modifying javaclass path -- this clears all variables!');
      javaaddpath(bufferjar); % N.B. this will clear all variables!
    end
  elseif ( ~any(strcmp(javaclasspath,bufferjavaclassdir)) )
    warning('Modifying javaclass path -- this clears all variables!');
    javaaddpath(bufferjavaclassdir); % N.B. this will clear all local variables!
  end
end

% re-connect if wanted / needed
[bufClient,host,port]=reconnect(host,port);

if ( isempty(cmd) ) return; end;
switch cmd;
 
 case 'get_hdr';  
  hdrj=bufClient.getHeader();  
  hdr=struct('nChans',hdrj.nChans,...
             'nSamples',hdrj.nSamples,...
             'nEvents',hdrj.nEvents,...
             'fSample',hdrj.fSample,...
             'labels',{{}},...
             'dataType',hdrj.dataType);
  labj=hdrj.labels; for ci=1:numel(labj); hdr.labels{ci}=char(labj(ci)); end;
  if ( ~isnumeric(hdr.fSample) && exist('OCTAVE_VERSION','builtin') ) hdr.fSample=hdr.fSample.doubleValue(); end;
  % Argh! duplicte field names to also be in the mex-version format, i.e non-camelCase
  hdr.nchans  =hdr.nChans;
  hdr.nsamples=hdr.nSamples;
  hdr.nevents =hdr.nEvents;
  hdr.fsample =hdr.fSample;
  hdr.data_type=hdr.dataType;
  hdr.channel_names=hdr.labels; % N.B. inconsistent names btw java and mex versions
  varargout{1}=hdr;
 
 case 'put_hdr';  
  if ( isfield(detail,'nChans') ) % java or mex-buffer version of the header field names
    if ( isfield(detail,'Fs') ) fs=detail.Fs; else fs=detail.fSample; end;
    if ( isfield(detail,'dataType') ) dataType=detail.dataType; 
    elseif( isfield(detail,'data_type') ) dataType=detail.dataType;
    elseif( isfield(detail,'orig') )      dataType=detail.orig.data_type;
    end
    if ( isstr(dataType) ) dataType=getTypeID(dataType); end
    hdr=javaObject('nl.fcdonders.fieldtrip.bufferclient.Header',detail.nChans,fs,dataType);
  else
    if ( isfield(detail,'fs') ) fs=detail.fs; else fs=detail.fsample; end;
    hdr=javaObject('nl.fcdonders.fieldtrip.bufferclient.Header',detail.nchans,fs,detail.data_type);    
  end
  try
	 if ( isfield(detail,'labels') )
		hdr.labels=detail.labels; % N.B. inconsistent names btw java and mex versions    
	 elseif ( isfield(detail,'channel_names') )
		hdr.labels=detail.channel_names; % N.B. inconsistent names btw java and mex versions
	 elseif ( isfield(detail,'label') )
		hdr.labels=detail.label;
	 end
  catch
  end
  bufClient.putHeader(hdr);
 
 case 'get_dat'; 
  bufj=bufClient.getDoubleData(detail(1),detail(2));
  buf=bufj; 
  % N.B. matlab is col-major, java is row-major.  Need to transpose results
  if ( exist('OCTAVE_VERSION') ) % in octave have to manually convert arrays..
    tic,[w,h]=size(bufj); buf=zeros(h,w); for i=1:w; tmp=bufj(i); for j=1:h; buf(j,i)=tmp(j);end; end;toc
  else
    buf=buf'; 
  end
  varargout{1}=struct('buf',buf);
 
 case 'put_dat';
  % N.B. java stores in *column major order* so transpose the data before putting it!
  if ( isstruct(detail) ) detail=detail.buf; end;
  % N.B. java-Order = Row-Major so reverse size
  bufClient.putData(detail(:),[size(detail,2) size(detail,1)]); 
 
 case 'get_evt';
  if ( numel(detail)<2 ) detail(2)=detail(end); end;
  evtj=bufClient.getEvents(detail(1),detail(2));
  evt =repmat(struct('type',[],'value',[],'sample',-1,'offset',0,'duration',0),size(evtj)); % pre-alloc array
  for ei=1:numel(evtj); % Note this conversion is *VERY VERY* slow...
    evtjei=evtj(ei);
    evt(ei).type=evtjei.getType().getArray();
    evt(ei).value=evtjei.getValue().getArray();
    evt(ei).sample=evtjei.sample;
    evt(ei).offset=evtjei.offset;
    evt(ei).duration=evtjei.duration;
    if ( exist('OCTAVE_VERSION','builtin') ) % in octave have to manually convert arrays..
      if ( strcmp(typeinfo(evt(ei).type),'octave_java') )
        tmp = zeros(size(evt(ei).type));
        for i=1:numel(evt(ei).type); tmp(i)=evt(ei).type(i); end; evt(ei).type=tmp;
      end
      if ( strcmp(typeinfo(evt(ei).value),'octave_java') )
        tmp = zeros(size(evt(ei).value));
        for i=1:numel(evt(ei).value) 
          if isnumeric(evt(ei).value(i)) && numel(evt(ei).value(i))>1
            tmp(i)=evt(ei).value(i).doubleValue(); 
          else
            tmp(i)=evt(ei).value(i);
          end; 
        end
        evt(ei).value=tmp;
      end
    end;
  end
  % argh! different names from mex version
  varargout{1}=evt;
 
 case 'put_evt';
  if ( numel(detail)==1 ) 
	 if ( islogical(detail.value) ) detail.value=single(detail.value); end; % BODGE: convert to single float
    e=bufClient.putEvent(javaObject('nl.fcdonders.fieldtrip.bufferclient.BufferEvent',detail.type,detail.value,detail.sample));
  else
    for ei=1:numel(detail);
      evt=detail(ei);
		if ( islogical(evt.value) ) evt.value=single(evt.value); end; % BODGE: convert to single float
      e=bufClient.putEvent(javaObject('nl.fcdonders.fieldtrip.bufferclient.BufferEvent',evt.type,evt.value,evt.sample));
    end
  end
  if ( nargout>0 ) % convert to matlab (quickly, getArray is v.slow)
    e =struct('type',detail(end).type,'value',detail(end).value,'sample',e.sample,'offset',e.offset,'duration',e.duration);
  end
  varargout{1}=e;
 
 case {'wait_dat','poll'};
  if ( isempty(detail) ) detail=[-1 -1 -1]; end;
  if ( all(detail<0) ) detail(:)=0; end; % diff between mex and java  
  sampeventsj=bufClient.wait(detail(1),detail(2),detail(3));
  sampevents=struct('nSamples',sampeventsj.nSamples,'nEvents',sampeventsj.nEvents);
  % argh! different names from mex version
  sampevents.nsamples=sampevents.nSamples; sampevents.nevents=sampevents.nEvents;
  varargout{1}=sampevents;
 
 case 'get_samp';
  if ( isempty(detail) ) 
    varargout{1}=bufClient.getSamp();
  else
    varargout{1}=bufClient.getSamp(detail);
  end
  if ( ~isnumeric(varargout{1}) && exist('OCTAVE_VERSION','builtin') )%in octave have to manually convert arrays..
    varargout{1}=varargout{1}.doubleValue();
  end
 
 case 'get_time';
  varargout{1}=bufClient.getTime();
 
 case 'sync_clk'; 
  if ( ~isempty(detail) ) bufClient.syncClocks(detail); else bufClient.syncClocks(); end;
end

% connection/reconnection helper function
function [bufClient,host,port]=reconnect(host,port)
global bufferClient;
clientIdx=[];
if ( isempty(host) && isempty(port) ) % use first existing connection or defaults
  host='localhost'; port=1972;
  if ( ~isempty(bufferClient) ) clientIdx=1; end;
else % search for matching client connection
  for bi=1:numel(bufferClient);
    try; buffhost=bufferClient{bi}.getHost(); catch; buffhost=[]; end;
    try; buffport=bufferClient{bi}.getPort(); catch; buffport=1972; end;
    if ( (isempty(host) || isempty(buffhost) || strcmp(host,buffhost)) ...
         && (isempty(port) || port==buffport) ) 
      clientIdx=bi; break; % found a match
    end;
  end
end
if ( isempty(clientIdx) ) % make a new connection
  clientIdx=numel(bufferClient)+1;
  try
    fprintf('Initialize connection to : %s %d\n',host,port);
    bufferClient{clientIdx}=javaObject('nl.fcdonders.fieldtrip.bufferclient.BufferClientClock');
    bufferClient{clientIdx}.setAutoReconnect(true);
  catch
    le=lasterr;
    if ( isfield(le,'message') )
        fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    else
        fprintf('ERROR Caught:\n%s\n',le);
    end
    error('Couldnt connect to the buffer: %s %d',host,port);    
  end  
end
if ( ~bufferClient{clientIdx}.isConnected() ) % re-connect if wanted/needed
  try
    fprintf('Connecting to : %s %d...',host,port);
    bufferClient{clientIdx}.disconnect();
    bufferClient{clientIdx}.connect(host,port);
    fprintf('done.\n');
  catch
    error('Failed: Couldnt connect to the buffer: %s %d',host,port);
  end
end
bufClient=bufferClient{clientIdx};
return;

function [dataType]=getTypeID(dataType)
typeIDs={'CHAR',0;'UINT8',1;'UINT16',2;'UINT32',3;'UINT64',4;
         'INT8',5;'INT16',6;'INT32',7;'INT64',8;'FLOAT32',9;'FLOAT64',10;
        'single',9;'double',10};
idx=strmatch(lower(dataType),typeIDs(:,1));
dataType=typeIDs{idx,2};
return;


function testCase();
buffer;% connect
% put fake header
hdr0=struct('fsample',10,'channel_names',{'Cz'},'nchans',1,'nsamples',0,'nevents',0,'data_type',10);
buffer('put_hdr',hdr0);
hdr=buffer('get_hdr');
% put fake event
evt0=struct('type','hello','value','there','sample',1,'offset',0,'duration',0);
buffer('put_evt',evt0);
evt=buffer('get_evt',[0,0]);
% put and get fake data
dat=randn(1,10);
buffer('put_dat',dat)
buffer('get_dat',[0 9]); mad(dat,ans.buf)


% unit16 buffer -- 2-byte endian stuff
hdr0=struct('fsample',10,'channel_names',{'Cz'},'nchans',1,'nsamples',0,'nevents',0,'data_type',6);
buffer('put_hdr',hdr0);
buffer('put_dat',int16([0 1 0 1 0 1 0 1]));
buffer('get_dat',[0 8])

% test automatic clock sync code
tic,for i=1:50; e=buffer('put_evt',struct('type','test','value',1,'sample',-1,'offset',0,'duration',0)); fprintf('%d) t=%g s=%d\n',i,toc,e.sample); pause(.5); end;
