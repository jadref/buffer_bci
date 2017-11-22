function [phaseSlice,hdr,events]=slicePhases(fname,varargin)
% Example of how to slice a raw recording file up epochs
%
% [phaseSlice,hdr,events]=sliceraw(outputdir,varargin)
%
% Roughly this file consists of 3 steps
%  1) read the header information
%  2) read all events and 
%  2.1) select the subset we want to get data from.  
%       By default this uses matchEvents, to use a more complex selection criteria supply 
%       your own match function (see the startSet option)
%  3) read the data for the selected events
%
% Note: Outputs are given in the same format as returned by buffer_waitData, so can be used
%       directly as input to either buffer_train_er(s)p_clsfr, or buffer_apply_er(s)p_clsfr
%  
% Inputs:
%  outputdir - [str] name of the directory where the data was saved
%      Note: By default raw data is saved to
%            MAC/LINUX: ~/output/test/YYMMDD/HHMM_PID/raw_buffer/0001 
%            WINDOWS: C:\output\test\YYMMDD\HHMM\raw_buffer\0001 
%     where YYMMDD is the date in year/month/day format,
%           HHMM is start time hourmin
%           PID is the buffer process ID (usually a 5 digit number)
% Outputs:
%  data  - [struct 1xN] structure with the data for each epoch
%         This structure contains:
%          data.buf -- [nCh x nSamp] matrix of the raw data in channels x time format
%  devents-[struct 1xN] structure with the event used to slice for each epoch, 
%                       i.e. devents(1) is event for data(1) etc..
%         Each of these structures is a normal event structure as made by mkEvent.  The basic format it:
%          devent=struct('type',*type-string*,'sample',*eventSample*,'value',*value*)
%  hdr   - [struct] the data header
%  events- [struct 1xM] all events in this data file
% Options:
%  phaseStart -- 'str' cell array of match strings/numbers for matching
%              events to indicate the start/end of an experiment phase
%  startSet -- {2x1} cell array of match strings/numbers for matching 
%              events based on their type and/or value as used in matchEvents.
%              {type value} OR {{types} {values}}
%               See matchEvents for details
%             OR
%               {str} [function_handle] handle to a function which takes in all events and returns
%                   a logical or index expression saying which should be sliced.  e.g.
%                    [matchedEvents] = myMatchEvents(events); % events is struct array of all events
%             OR
%               (struct) struct array of event's already selected/filtered to slice on
%  trlen_ms/trlen_samp - [1x1] length of data to get for each epoch in milliseconds or samples (3000ms)
%  offset_ms/offset_samp - [2x1] offset from event start/end to get data from in milli-sec or samples  ([])
%                that is: data_range= event.sample+offset_samp(1) : event.sample+trlen_samp+offset_samp(2)
%  subsample -- [1x1] sub-sample recorded data to max of this frequency if needed       (256)
%  hdr       -- [struct] header file
%  events    -- [struct] all events from the datafile
%
% Examples:
%  % 1: Simple example of slicing a whole file
%  % slice 3000ms from start of all events with type 'stimulus.trial' and value 'start'
%  [data,devents,hdr]=sliceraw('~/output/test/140117/2145_20681/raw_buffer/0001','startSet',{'stimulus.trial' 'start'});
%  % train a ERsP classifier on this data
%  [clsfr,X]=buffer_train_ersp_clsfr(data,devents,hdr)
%  % apply this classifier to the same data
%  [f]      =buffer_apply_ersp_clsfr(data,clsfr)
%
%  % 2: using your own matching function
%  myMatchFn = @(events) 1:10;  % simple match function which matches exactly the first 10 events
%  % slice 1000ms from start of these events
%  [data,devents,hdr]=sliceraw('~/output/test/140117/2145_20681/raw_buffer/0001','startSet',myMatchFn,'trlen_ms',1000);
% See Also: buffer_waitData, buffer_train_erp_clsfr, buffer_train_ersp_clsfr, buffer_apply_erp_clsfr, buffer_apply_ersp_clsfr

% set and parse the input options
opts=struct('phaseStart','startPhase.cmd','startSet','stimulus.target','trlen_ms',3000,'trlen_samp',[],'offset_ms',[],'offset_samp',[],'verb',0,'subsample',256,'hdr',[],'events',[]);
opts=parseOpts(opts,varargin);

% get the directory which contains the files
if ( isdir(fname) ) 
   fdir=fname;
else % strip the file-name part out
   [fdir,fname,fext]=fileparts(fname);
   if ( ~isdir(fdir) ) error('Couldnt find output directory!'); end
end
hdrfname=fullfile(fdir,'header');
eventfname=fullfile(fdir,'events');
datafname =fullfile(fdir,'samples');

										  % read the header and the events
hdr=opts.hdr;
if ( isempty(hdr) )       hdr   =read_buffer_offline_header(hdrfname); end;
allevents=opts.events;
if ( isempty(allevents) )
  if( opts.verb>0 ) fprintf('Reading all events\n'); end;
  allevents=read_buffer_offline_events(eventfname,hdr);
end;

% extract sample-rate from the header and convert from ms->samples if needed
if ( isfield(hdr,'SampleRate') ) fs=hdr.SampleRate; 
elseif ( isfield(hdr,'Fs') ) fs=hdr.Fs; 
elseif ( isfield(hdr,'fSample') ) fs=hdr.fSample; 
else warning('Cant find sample rate, using fs=1'); fs=1;
end
% convert data ranges from ms-> samples
if ( isempty(opts.trlen_samp) ) opts.trlen_samp = ceil(opts.trlen_ms*fs/1000); end;
if ( isempty(opts.offset_samp) && ~isempty(opts.offset_ms) ) 
  opts.offset_samp = ceil(opts.offset_ms*fs/1000);
end;
% set the sub-sample ratio of needed
subSampRatio=1;
if ( ~isempty(opts.subsample) && fs>opts.subsample ) 
  subSampRatio = round(fs/opts.subsample);
  outfs=fs/subSampRatio;
  fprintf('Subsampling from: %g to %g\n',fs,outfs);
end

% Compute relative start/end sample for the data we want to get
% Include the offset
offset_samp=[0 opts.trlen_samp-1];
if ( ~isempty(opts.offset_samp) ) offset_samp = offset_samp+opts.offset_samp; end;

% select the events we want to slice on from the stream
% Note: you can replace this with something more sophsicated
if( opts.verb>0 ) fprintf('Getting trial events\n'); end;
if ( iscell(opts.startSet) )
  mi=matchEvents(allevents,opts.startSet{:});
elseif ( isstruct(opts.startSet) ) % already the set of events to slice on
  allevents=opts.startSet; mi=true(numel(allevents),1);
elseif ( isa(opts.startSet,'function_handle') || exist(opts.startSet)==2 )
  mi=feval(opts.startSet,allevents);
elseif ( ischar(opts.startSet) ) % just a type spec
  mi=matchEvents(allevents,opts.startSet);
elseif ( isempty(opts.startSet) ) % return all events
  mi=true(numel(allevents),1);
end

% select the events which define start/end of the different experiment phases
if( opts.verb>0 ) fprintf('Getting phase events\n'); end;
phaseStarti=[];
if iscell(opts.phaseStart) 
   phaseStarti=matchEvents(allevents,opts.phaseStart{:});
elseif ischar(opts.phaseStart)
   phaseStarti=matchEvents(allevents,opts.phaseStart);
end
phaseStarti=find(phaseStarti);


fprintf('Slicing in %d phases\n',numel(phaseStarti));
phaseSlice=[];
for phasei=1:numel(phaseStarti);
  phaseStartEvt = allevents(phaseStarti(phasei));
  fprintf('Phase: %s',ev2str(phaseStartEvt));
   phaseEvtsi = mi;
   phaseEvtsi(1:phaseStarti(phasei))=false; % nothing before phase start
   if( phasei<numel(phaseStarti) ) % nothing after start next phase
      phaseEvtsi(phaseStarti(phasei+1):end)=false; 
   end
   % select this set of events
   devents=allevents(phaseEvtsi);
   if( isempty(devents) )
     fprintf('No startSet events in this phase, skipping.\n'); continue;
   end;
   
   % Finally get the data segements we want
   data=repmat(struct('buf',[]),size(devents));
   if ( opts.verb>=0 ) fprintf('Slicing %d epochs:',numel(devents));end;
   keep=true(numel(devents),1);
   if( isstruct(devents) ) bgns=[devents.sample]; else bgns=devents; end;
   for ei=1:numel(devents);
      data(ei).buf=read_buffer_offline_data(datafname,hdr,bgns(ei)+[offset_samp]);  
      if ( size(data(ei).buf,2) < (offset_samp(2)-offset_samp(1)) ) keep(ei)=false; end;
      if ( subSampRatio>1 ) % sub-sample
         [data(ei).buf,idx] = subsample(data(ei).buf,size(data(ei).buf,2)./subSampRatio,2);
      end
      if ( opts.verb>=0 ) fprintf('.');end
   end
   if ( opts.verb>=0 ) fprintf('done.\n');end
   if ( ~all(keep) )
      fprintf('Discarding %d events with no data\n',sum(~keep));
      data=data(keep);
      devents=devents(keep);
   end
   if( isempty(phaseSlice) )
     phaseSlice = struct('data',data,'devents',devents,'label',phaseStartEvt.value);
   else
     phaseSlice(end+1)=struct('data',data,'devents',devents,'label',phaseStartEvt.value);
   end
end
if ( subSampRatio>1 ) % update the sample rate stored in the header
  hdr.fSample=outfs;
end
return;
