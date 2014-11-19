function []=buffer_signalproxy(host,port,filename,varargin);
% generate simulated data for a buffer
%
% []=buffer_fileproxy(host,port,filename,varargin);
% 
% Inputs:
%  host - [str] hostname on which the buffer server is running (localhost)
%  port - [int] port number on which to contact the server     (1972)
%  filename - [str] file/directory name where we can find the saved buffer data
% Options:
%  blockSize- [int] number of samples to send at a time to buffer (2)
%  verb           - [int] verbosity level.  If <0 then rate in samples to print status info (0)
%  speedup  - [float] playback speed factor, i.e. playback this times real time (1)
%  excludeSet -- {2x1} match set for events *not to* resend                             ([])
%              format is as used in matchEvents but basically consists of pairs of types and values
%              {type value} OR {{types} {values}}
%               See matchEvents for details
%  startSamp --  [int] sample number to start playing from                       (1)
%  endSamp   --  [int] sample number to stop  playing from                       ([end-of-file])
%  startEvent -- [int] event number to start playing from
%              OR
%                {2x1} match set to start from the first matching event
%              format is as used in matchEvents but basically consists of pairs of types and values
%              {type value} OR {{types} {values}}
%               See matchEvents for details
%  endEvent --   [int] event number to stop playing
%              OR
%                {2x1} match set to start from the first matching event
%              format is as used in matchEvents but basically consists of pairs of types and values
%              {type value} OR {{types} {values}}
%               See matchEvents for details

if ( nargin<2 || isempty(port) ) port=1972; end;
if ( nargin<1 || isempty(host) ) host='localhost'; end;
if ( nargin<3 || isempty(filename) ) 
  [fn,pth]=uigetfile('~/output/*.txt','Pick header.txt in a data save directory!'); drawnow;
  if ( ~isequal(fn,0) ) filename=fullfile(pth,fn); end;
end;
wb=which('buffer'); if ( isempty(wb) || isempty(strfind('dataAcq',wb)) ) run('../utilities/initPaths.m'); end;
% init the accurate real-time-clock
initgetwTime;
initsleepSec;

opts=struct('blockSize',5,'verb',0,'speedup',1,'excludeSet',[],...
            'startSamp',[],'endSamp',[],'startEvent',[],'endEvent',[]);
opts=parseOpts(opts,varargin);

% get the associated header and events filenames
if ( isdir(filename) ) 
   fdir=filename;
else
   [fdir,fname,fext]=fileparts(filename);
   if ( strcmp(fname,'contents') ) 
      % find the latest directory
      fdirs = dir(fdir); fdirs=fdirs([fdirs.isdir]); fdirs=sort({fdirs(3:end).name});
      fdir=fullfile(fdir,fdirs{end}); 
   end;
end
hdrfname=fullfile(fdir,'header');
eventfname=fullfile(fdir,'events');
datafname =fullfile(fdir,'samples');

% read the header
hdr=read_buffer_offline_header(hdrfname);
hdr.data_type=10; % force double
hdr.dataType=10;
buffer('put_hdr',hdr,host,port);

% cope with different hdr formats/name conventions
dataType=10;
if ( isfield(hdr,'dataType') ) dataType=hdr.dataType; 
elseif( isfield(hdr,'data_type') ) dataType=hdr.data_type;
elseif( isfield(hdr,'orig') )      dataType=hdr.orig.data_type;
end
nSamples=0;
if ( isfield(hdr,'nSamples') )     nSamples=hdr.nSamples;
elseif( isfield(hdr,'nsamples') )  nSamples=hdr.nsamples;
end
if ( nSamples<=0 ) nSamples=inf; end;
nChans=0;
if ( isfield(hdr,'nChans') )     nChans=hdr.nChans;
elseif( isfield(hdr,'nchans') )  nChans=hdr.nchans;
end

dat=struct('nchans',nChans,'nsamples',opts.blockSize,'data_type',dataType,'buf',[]);

% read all the events
events=read_buffer_offline_events(eventfname,hdr);
% and make-sure they are in sample order
if ( numel(events)>0 )
oevstartsamp=cat(1,events.sample);
[oevstartsamp,si]=sort(oevstartsamp,'ascend');
events=events(si); 
if ( ~isempty(opts.excludeSet) )
  mi=matchEvents(events,opts.excludeSet{:});
  if ( opts.verb>0 ) fprintf('Excluded %d events out of %d',sum(mi),numel(mi)); end;
  % remove excluded events from all events and time-indication for it
  oevstartsamp=oevstartsamp(~mi);
  events=events(~mi);  
end
end

% get the sample rate
if ( isfield(hdr,'SampleRate') )
  fs=hdr.SampleRate;
elseif ( isfield(hdr,'Fs') )
  fs=hdr.Fs;
else
  error('Cant find sample rate');
end
if any(fs~=fs(1))
   error('channels with different sampling rate not supported');
end

% pre-read some data to get the function+file in cache
dat.buf = read_buffer_offline_data(datafname,hdr,[1 2]);

blockSize     = opts.blockSize;
blockDuration = blockSize/fs/opts.speedup; % time-between sending blocks
startTime=getwTime(); curTime=startTime; printtime=startTime;
startSamp=1; nevents=1;
if ( ~isempty(opts.startSamp) ) 
  startSamp=opts.startSamp; 
elseif ( ~isempty(opts.startEvent) )
  if ( isnumeric(opts.startEvent) ) nevents=opts.startEvent; 
  elseif ( iscell(opts.startEvent) ) % match criteria for the starting event
    mi=matchEvents(events,opts.startEvent{:}); 
    nevents=find(mi,1,'first'); % fist matching event is start point
    if ( isempty(nevents) ) 
      warning('Didnt find a matching start event'); 
      nevents=1;
    end
  end
  startSamp=oevstartsamp(nevents)-1; % start 1 sample before starting event
end
if( startSamp>0 ) % modify all events to be relative to this new start time...
  for ei=1:numel(events); events(ei).sample=events(ei).sample-startSamp; end;
end
if ( ~isempty(opts.endSamp) ) nSamples=min(nSamples,opts.endSamp);
elseif( ~isempty(opts.endEvent) )
  endEvent=[];
  if ( isnumeric(opts.endEvent) ) endEvent=opts.endEvent; 
  elseif ( iscell(opts.endEvent) ) % match criteria for the starting event
    mi=matchEvents(events,opts.endEvent{:}); 
    endEvent=find(mi,1,'last'); % last matching event is end-point
    if ( isempty(endEvent) ) 
      warning('Didnt find a matching end event'); 
      endEvent=numel(oevstartsamp);
    end
  end
  nSamples=min(nSamples,oevstartsamp(endEvent)-1); % start 1 sample before starting event  
end
nblk=0; nsamp=startSamp;
while( nsamp < nSamples )
  nblk=nblk+1;
  onsamp=nsamp; nsamp=min(nsamp+blockSize,nSamples);

  % read the data, N.B. -1 at the end so don't send the same sample twice!
  dat.buf = read_buffer_offline_data(datafname,hdr,[onsamp nsamp-1]);
  dat.buf = double(dat.buf); % force double
  % put the data
  buffer('put_dat',dat,host,port);
  % put any events
  while ( nevents<numel(events) && oevstartsamp(nevents)<nsamp )
    buffer('put_evt',events(nevents),host,port);
    if ( opts.verb>0 ) fprintf('%d) %s',nsamp-startSamp,ev2str(events(nevents))); end;
    nevents=nevents+1;
  end
  % debug info
  if ( opts.verb>=0 )
    ctime=getwTime();
    if ( opts.verb>=0 && ctime-printtime>5 )
      fprintf('%d %d %d %f (blk,samp,event,sec)\r',nblk,nsamp-startSamp,nevents,ctime-startTime);
      printtime=ctime;
    end
  end  
  %wait until next block is due
  curTime=curTime+blockDuration;
  sleepSec(curTime-getwTime()); % sleep until next block should be sent
end
if ( opts.verb~=0 ) fprintf('\n'); end
return;

%-------------
function testCase();
% real-time replay
buffer_fileproxy([],[],'~/data/bci/own_experiments/visual/vssep_robot/geertjan/20131128/buffer_raw/1321/raw_buffer/0001/')
% test with speedup
buffer_fileproxy([],[],'~/data/bci/own_experiments/visual/vssep_robot/geertjan/20131128/buffer_raw/1321/raw_buffer/0001/','speedup',32,'blockSize',5*32)
% test with speedup + event exclusion
buffer_fileproxy([],[],'~/data/bci/own_experiments/visual/vssep_robot/geertjan/20131128/buffer_raw/1321/raw_buffer/0001/','speedup',32,'blockSize',5*32,'excludeSet',{{'stimulus.prediction' 'stimulus.predTgt'}})
% test with sample based start criteria
buffer_fileproxy([],[],'~/data/bci/own_experiments/visual/vssep_robot/geertjan/20131128/buffer_raw/1321/raw_buffer/0001/','speedup',32,'blockSize',5*32,'startSamp',4000)
buffer_fileproxy([],[],'~/data/bci/own_experiments/visual/vssep_robot/geertjan/20131128/buffer_raw/1321/raw_buffer/0001/','speedup',32,'blockSize',5*32,'startSamp',4000,'endSamp',10000)
% test with event based start criteria
buffer_fileproxy([],[],'~/data/bci/own_experiments/visual/vssep_robot/geertjan/20131128/buffer_raw/1321/raw_buffer/0001/','speedup',32,'blockSize',5*32,'startEvent',6)
buffer_fileproxy([],[],'~/data/bci/own_experiments/visual/vssep_robot/geertjan/20131128/buffer_raw/1321/raw_buffer/0001/','speedup',32,'blockSize',5*32,'startEvent',{{'startPhase.cmd'} {'calibrate' 'calibration'}})
buffer_fileproxy([],[],'~/data/bci/own_experiments/visual/vssep_robot/geertjan/20131128/buffer_raw/1321/raw_buffer/0001/','speedup',32,'blockSize',5*32,'startEvent',{{'startPhase.cmd'} {'calibrate' 'calibration'}},'endEvent',{{'calibrate','calibration'} {'end'}})

%....
buffer_fileproxy([],[],'~/data/bci/own_experiments/visual/vssep_robot/geertjan/20131128/buffer_raw/1321/raw_buffer/0001/','speedup',8,'blockSize',5,'startEvent',{{'startPhase.cmd'} {'test' 'testing'}},'endEvent',{{'test','testing'} {'end'}},'excludeSet',{{'stimulus.prediction'}},'verb',1)