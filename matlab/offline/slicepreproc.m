function [data,devents,hdr,allevents]=slicepreproc(fname,varargin)
% load a ftbuffer_offline save file, apply the given pre-processing function, and slice out data w.r.t. the given trigger events
%
% [data,devents,hdr,allevents]=slicepreproc(outputdir,varargin)
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
%
% Options:
%  startSet -- {2x1} cell array of match strings/numbers for matching 
%              events based on their type and/or value as used in matchEvents.
%              {type value} OR {{types} {values}}
%               See matchEvents for details
%             OR
%               {str} [function_handle] handle to a function which takes in all events and
%                   returns the set of events on which to slice e.g.
%                    [triggerEvents] = myMatchEvents(events); % events is struct array of all events
%             OR
%               (struct) struct array of event's already selected/filtered to slice on
%  trlen_ms/trlen_samp - [1x1] length of data to get for each epoch in milliseconds or samples (3000ms)
%  offset_ms/offset_samp - [2x1] offset from event start/end to get data from in milli-sec or samples  ([])
%                that is: data_range= event.sample+offset_samp(1) : event.sample+trlen_samp+offset_samp(2)
%  width_ms/samp - [1x1] time duration for single data packet to propogate to the preprocFn    ([500ms])
%  step_ms/samp  - [1x1] interval between raw data blocks to send to the pre-procFn            ([])
%                        if empty then non-overlapping blocks, i.e. step=width
%  preprocFn -- 'fname' or {fname args} function to call to preprocess the data, such as 'adaptWhitenFilt', or 'artChRegress'
%                fname should be the name of a *filterfunction* to call.  This should have a prototype:
%                 [Xout,state]=fname(X,state,args{:})
%                where;
%                  X    - [ ch x time x epoch ] raw data, for 1 packet of data
%                  Xout - [ ch x feat x epoch ] pre-processed data.
%                  state- [struct]  is some arbitary internal state of the filter which is propogated between calls
%                NOTE: during *training* we call with extra meta-information about the data, specifically;
%                           [X,state]=fname(X,state,args{:},'ch_names',ch_names,'fs',fs);
%                SEE ALSO: adaptWhitenFilt, artChRegress, rmEMGFilt
%  width_raw_ms/samp -- [1x1] time duration for a single packet of raw data from the save file. ([])
%                        if empty then; width_raw_ms=step_ms, i.e. the same as the preproc step size
%  hdr       -- [struct] header file
%  events    -- [struct] all events from the datafile
%
% Outputs:
%  data  - [struct 1xN] structure with the data for each epoch
%         This structure contains:
%          data.buf -- [nCh x nSamp] matrix of the raw data in channels x time format
%  devents-[struct 1xN] structure with the event used to slice for each epoch, 
%                       i.e. devents(1) is event for data(1) etc..
%         Each of these structures is a normal event structure as made by mkEvent.  The basic format it:
%          devent=struct('type',*type-string*,'sample',*eventSample*,'value',*value*)
%  hdr   - [struct] the data header
%  allevents- [struct 1xM] all events in this data file
%
% Examples:
%  % 1: Simple example of slicing a whole file
%  % slice 3000ms from start of all events with type 'stimulus.trial' and value 'start'
%  datadir='~/output/test/140117/2145_20681/raw_buffer/0001';
%  [data,devents,hdr]=slicepreproc(datadir,'startSet',{'stimulus.trial' 'start'});
%  % train a ERsP classifier on this data
%  [clsfr,X]=buffer_train_ersp_clsfr(data,devents,hdr)
%  % apply this classifier to the same data
%  [f]      =buffer_apply_ersp_clsfr(data,clsfr)
%
%  % 2: using your own matching function
%  myMatchFn = @(events) 1:10;  % simple match function which matches exactly the first 10 events
%  % slice 1000ms from start of these events
%  [data,devents,hdr]=slicepreproc(datadir,'startSet',myMatchFn,'trlen_ms',1000);
%
%  % 3: sub-sampled data by averaging 20ms blocks to a single output, load data in big-blocks for speed
%  [data,devents,hdr]=slicepreproc(datadir,'startSet',{'stimulus.tgtFlash'},'trlen_ms',1500,'width_raw_ms',5000,'width_ms',20,'preprocFn',@(x,s,varargin) deal(mean(x,2),[]))); 
%    N.B. need to use @(x,s,varargin) deal(fn,[]) to match the function signature of 2-or-more inputs and 2 outputs
%
%  % 4: high-pass the data with a butterworth IIR with high-pass @.5hz
%  bands=.5;
%  [B,A]=butter(6,bands*2/100,'high'); % get filter coefficients for butter IIR high-pass at .5hz, assume sample rate = 100hz
%  [data,devents,hdr,allevents]=slicepreproc(datadir,'startSet',{'stimulus.tgtFlash'},'trlen_ms',1500,'width_raw_ms',5000,'preprocFn',@(x,s) filter(B,A,x,s,2));
%
%  % 5: alternative way of doing a high-pass filter using the signalProc/filterFilt function
%  [data,devents,hdr,allevents]=slicepreproc(datadir,'startSet',{'stimulus.tgtFlash'},'trlen_ms',1500,'width_raw_ms',5000,'preprocFn',{'filterFilt' 'filter',{'butter',6,10,'low'}});
%
%  % 6: transformation to time-frequencey representation with welch + downsample->10hz
%  [data,devents,hdr,allevents]=slicepreproc(datadir,'startSet',{'stimulus.tgtFlash'},'trlen_ms',5000,'width_raw_ms',5000,'width_ms',250,'step_ms',100,'preprocFn',@(x,s) welchpsd(x,2,'width_samp',25));
%  % Note: data.buf is not [ ch x  ( freqs * times ) ]
%  tfr = reshape(data(1).buf,[size(data(1).buf,1) size(data(1).buf,2)/50 50]);
%  clf;image3d(tfr,'xlabel','ch','ylabel','freq','zlabel','time'); plot the TFR
%
%  % 6: apply minimal pre-processing consisting of, band-pass (1-10hz) -> CAR -> subsample@20Hz
%  [data,devents,hdr,allevents]=slicepreproc(datadir,'startSet',{'stimulus.tgtFlash'},'trlen_ms',5000,'width_raw_ms',5000,'width_ms',50,'preprocFn',{'minimalPreprocFilter' 'bands',[1 10],'subsample',20});
%
% TODO: [] assume dim-2 after pre-proc is still time, and sub-select to get sample accurate event slicing
%       [] test the offset_ms code..

% set and parse the input options
opts=struct('startSet',[],'trlen_ms',3000,'trlen_samp',[],'offset_ms',[],'offset_samp',[],...
            'width_ms',500,'width_samp',[],'step_ms',[],'step_samp',[],'preprocFn',{{}},'filtstate',[],...
            'width_raw_ms',[],'width_raw_samp',[],...
            'verb',0,'hdr',[],'events',[]);
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
if ( isempty(hdr) )       hdr      =read_buffer_offline_header(hdrfname); end;
allevents=opts.events;
if ( isempty(allevents) ) allevents=read_buffer_offline_events(eventfname,hdr); end;

% extract sample-rate from the header and convert from ms->samples if needed
if ( isfield(hdr,'SampleRate') ) fs=hdr.SampleRate; 
elseif ( isfield(hdr,'Fs') ) fs=hdr.Fs; 
elseif ( isfield(hdr,'fSample') ) fs=hdr.fSample; 
else warning('Cant find sample rate, using fs=1'); fs=1;
end
% convert data ranges from ms-> samples

% trlen_samp = amount of pre-processed data to grab after every trigger event
trlen_samp = opts.trlen_samp; if ( isempty(trlen_samp) ) trlen_samp = ceil(opts.trlen_ms*fs/1000); end;
% offset_samp = relative start/end for the data to grab after every trigger event
offset_samp= opts.offset_samp;
if ( isempty(offset_samp) && ~isempty(opts.offset_ms) )  offset_samp = ceil(opts.offset_ms*fs/1000); end;
% Include the trial length to get the true event relative start/end
if ( isempty(offset_samp) ) offset_samp = [0 trlen_samp];
else                        offset_samp = offset_samp+[0 trlen_samp];
end;
trlen_samp = offset_samp(2)-offset_samp(1); % and the *true* size of the event data in samples

                           % width_samp = amount of data for 1 preprocFn call
width_samp=opts.width_samp; if( isempty(width_samp) ) width_samp = ceil(opts.width_ms*fs/1000); end;
% step_samp = number of samples to skip between calls to preprocFn
step_samp =opts.step_samp;
if( isempty(step_samp) )
  if( ~isempty(opts.step_ms) ) step_samp = ceil(opts.step_ms*fs/1000);
  else                         step_samp = width_samp;
  end
end
% width_raw_samp = size of blocks of raw data to load from the save file at one time
width_raw_samp=opts.width_raw_samp;
if ( isempty(width_raw_samp) )
  if( ~isempty(opts.width_raw_ms) ) width_raw_samp=ceil(opts.width_raw_ms*fs/1000);
  else                              width_raw_samp=step_samp;
  end
end    

% extract the pre-processing function to use
preprocFn=opts.preprocFn; if ( ~isempty(preprocFn) && ~iscell(preprocFn) ) preprocFn={preprocFn}; end;
filtstate=opts.filtstate;

% select the events we want to slice on from the stream
% Note: you can replace this with something more sophsicated, e.g. to only return 
% matching events between a given phase start and phase end event, if that is useful
devents=allevents; % default is take all events
if ( iscell(opts.startSet) )
  mi=matchEvents(allevents,opts.startSet{:});
  devents=allevents(mi); 
elseif ( ischar(opts.startSet) ) % just a type spec
  mi=matchEvents(allevents,opts.startSet);
  devents=allevents(mi); % select the set of events for which we want data
elseif ( isstruct(opts.startSet) ) % already the set of events to slice on
  devents=opts.startSet;
elseif ( isa(opts.startSet,'function_handle') || exist(opts.startSet)==2 )
  devents=feval(opts.startSet,allevents); % assume event matching mode
  if( islogical(devents) || isnumeric(devents) ) devents=allevents(mi); end % match-mode
end
% copute the sample start/end times for these trigger events
if( isstruct(devents) ) bgns=[devents.sample]; else bgns=devents; end;
% ensure it's in sorted sample order
[bgns,si]=sort(bgns,'ascend'); devents=devents(si);
bgns       = bgns+offset_samp(1); % move bgn to first sample in the event info


% Note: notation:
%    width  - amount of raw data that goes into the pre-processing function
%    step   - amount we shift the raw data between calls of the pre-processing function
%    raw_width - amount of raw-data to get each call to the file loader
%    trlen  - size in samples of raw-data/pre-processed which gets sliced into 1 event's data
%    bgns(ei)- raw-sample number of start of event ei's data
%  output data for event ei is pp-packets ii such that:  bgns(ei)  < packet(ii).start < bgns(ei)+trlen
%  that is, when the 1st sample in a prep-processor input pack is inside the event range

% prime the pump, get 1st packets worth of data and run the pre-processor
% raw data buffer big-enough for one call to preprocFn,
% N.B. always with 1 extra window in case when pp-window overlaps the raw_packet boundaries
rawbuf_samp = (ceil(width_samp/width_raw_samp)+1)*width_raw_samp; 
rawdat      = read_buffer_offline_data(datafname,hdr,[1 rawbuf_samp]); % Warning: inclusive range, 1st sample has index 1
rawend_samp = rawbuf_samp; % move the cursor on, cursamp is last sample *in* rawdat
windat      = rawdat(:,1:width_samp,:); % extract the raw-data window for this pp-call
if( isempty(preprocFn) )
  curppdat  = windat;
else
  [curppdat,filtstate]  = feval(preprocFn{1},windat,filtstate,preprocFn{2:end},'fs',fs,'hdr',hdr);
end
szppwin     = size(curppdat); % size of 1 block of pre-processed data
subsampratio= szppwin(2) / step_samp; % estimate the ratio of raw-to-preprocessed samples, every step_samp -> szppwin(2) samples
outfs       = fs*subsampratio; % estimate the new sample rate
trlen_window= trlen_samp/step_samp;
trlen_ppsamp= ceil(trlen_samp * subsampratio);

% setup a ring-buffer for the pre-processed data, this should be at least 1 packet bigger than
% needed for the sliced event info
ppbuf_window = ceil(trlen_window) + 1; % number windows of preprocessed data for event data
ppdat        = zeros([szppwin(1),szppwin(2)*ppbuf_window,szppwin(3:end)]);
ppdat(:,end-szppwin(2)+1:end,:) = curppdat; % insert into the ring-buffer, N.B. ppdat is lagged w.r.t. rawdat!
ppbuf_samp   = ppbuf_window * step_samp; % number of raw samples in preprocessed data buffer
ppend_samp   = step_samp;  % last sample *in* the pre-processed data buffer


% Finally get the data segements we want
data=repmat(struct('buf',[]),size(devents));
if ( opts.verb>=0 ) fprintf('Slicing %d epochs:',numel(devents));end;
keep=false(numel(devents),1);
eof=false; curevt=1;
while( ~eof )  % process all packets
  
  % while got enough raw data to apply the pre-processing to
  rawstart_samp = rawend_samp + 1 - rawbuf_samp; % start sample for the rawbuf, N.B. rawend_samp is inclusive..
  while ( ppend_samp + width_samp <= rawend_samp ) 

                                % apply the pre-processor
    windowstart_samp = ppend_samp + 1 - rawstart_samp; % window-start = next sample *after* last pre-processed sample
    windowidx        = windowstart_samp + (1:width_samp);
    windat           = rawdat(:,windowidx,:); % extract the raw-data window for this pp-call
    if( isempty(preprocFn) ) % no pre-processsing
      curppdat  = windat;
    else % apply the given function
      [curppdat,filtstate]  = feval(preprocFn{1},windat,filtstate,preprocFn{2:end},'hdr',hdr);
      if( any(isnan(curppdat)) ) 
         warning('NaNs!!!');
      end
    end
      
                                % update the pre-processed data buffer
    ppdat(:,1:end-szppwin(2),:)    = ppdat(:,szppwin(2)+1:end,:); % shift
    ppdat(:,end-szppwin(2)+1:end,:)= curppdat; % insert
    %windowend_samp                 = windowend_samp + step_samp; % sample number for the current pre-proc call, used to matche event sample info
    ppend_samp                     = ppend_samp + step_samp; % update the end of ppdat marker
    
    % check if there is a trigger event we should slice out the pre-processed data for
    % TODO: [] update to *not* assume ppdat is contains *exactly* trlen_samp preprocessed data
    ppstart_samp       = ppend_samp - ppbuf_samp; % 1st sample in the pre-proc data buffer
    while( bgns(curevt)+trlen_samp <= ppend_samp )
      eventstart_ppsamp= (bgns(curevt)-ppstart_samp) * subsampratio; % samples from start ppbuf in pp-samples
      eventIdx         = ceil(eventstart_ppsamp) -1 + (1:trlen_ppsamp);
      data(curevt).buf = ppdat(:,eventIdx);  
      keep(curevt)     = true;
      curevt           = curevt+1; % move on to the next event
      fprintf('.');
      if( curevt>numel(bgns) ) eof=true; break; end; % stop when all events done
    end
    if( eof ) break; end; % finish early if got all events data
  end

                                                   % update the raw-data buffer
  try; % try to read more data
    % N.B. we read in raw_width bits, but (potentially) process in sub-parts
    curdat=read_buffer_offline_data(datafname,hdr,rawend_samp+[1 width_raw_samp]);    
    rawdat(:,1:end-width_raw_samp)=rawdat(:,width_raw_samp+1:end); % shift
    rawdat(:,end-width_raw_samp+1:end)=curdat; % insert new data
    rawend_samp = rawend_samp + width_raw_samp; % move the cursor on, cursamp is last sample read
  catch;                                
    eof=true; % data-read failed, then we are done...
  end

end
if ( opts.verb>=0 ) fprintf('done.\n');end

if ( ~all(keep) )
  fprintf('Discarding %d events with no data\n',sum(~keep));
  data   =data(keep);
  devents=devents(keep);
end

% update the sample rate for the pre-processed data
if( isfield(filtstate,'hdr') ) hdr=filtstate.hdr; end; % use updated header from the filter-function
hdr.fSample = outfs;
if ( isfield(hdr,'SampleRate') ) hdr.SampleRate=outfs; 
elseif ( isfield(hdr,'Fs') )     hdr.Fs=outfs; 
end
return;

%-------------------------------------------------------
function testCase();
run ../utilities/initPaths.m
datadir=fullfile('example_data','raw_buffer','0001');

% compare non-preprocesed pure slicing
[data0,devents0,hdr,allevents]=sliceraw(datadir,'startSet',{'stimulus.tgtFlash'},'trlen_ms',1500);

                                % single sample windows
[data,devents,hdr,allevents]=slicepreproc(datadir,'startSet',{'stimulus.tgtFlash'},'trlen_ms',1500,'width_ms',10); 
% big raw blocks, more disk efficient
[data,devents,hdr,allevents]=slicepreproc(datadir,'startSet',{'stimulus.tgtFlash'},'trlen_ms',1500,'width_raw_ms',5000,'width_ms',10); 
% big raw blocks, big-preproc-windows -- more comp efficient
[data,devents,hdr,allevents]=slicepreproc(datadir,'startSet',{'stimulus.tgtFlash'},'trlen_ms',1500,'width_raw_ms',5000,'width_ms',2000); 

% evaluation
mad(data0(1).buf,data(1).buf) % single epoch
mad(cat(3,data0.buf),cat(3,data.buf)) % all epochs


% sub-sampling preprocessing
                                % subsample to 50hz
[data0,devents0,hdr,allevents]=sliceraw(datadir,'startSet',{'stimulus.tgtFlash'},'trlen_ms',1500,'subsample',50); 
                                % average pairs of samples
[data,devents,hdr,allevents]=slicepreproc(datadir,'startSet',{'stimulus.tgtFlash'},'trlen_ms',1500,'width_raw_ms',5000,'width_ms',20,'preprocFn',@(x,s,varargin) deal(mean(x,2),[])); 

                                % slice the 1st 5000ms data
[data0,devents0,hdr,allevents]=sliceraw(datadir,'startSet',struct('type','start','value',1,'sample',1),'trlen_ms',5000,'subsample',50); 
[data,devents,hdr,allevents]=slicepreproc(datadir,'startSet',struct('type','start','value',1,'sample',1),'trlen_ms',5000,'width_raw_ms',5000,'width_ms',20,'preprocFn',@(x,s,varargin) deal(mean(x,2),[]));
[data,devents,hdr,allevents]=slicepreproc(datadir,'startSet',struct('type','start','value',1,'sample',1),'trlen_ms',5000,'width_raw_ms',5000,'width_ms',1000,'preprocFn',@(x,s,varargin) deal(squeeze(mean(reshape(x,[size(x,1),2,size(x,2)/2]),2)),[]));


                                % high-pass filtering
[data0,devents0,hdr,allevents]=sliceraw(datadir,'startSet',struct('type','start','value',1,'sample',1),'trlen_ms',5000);
                                % get filter coefficients
bands=1;
[B,A]=butter(6,bands*2/100,'high'); % get filter coefficients for butter IIR high-pass at .5hz
bands=10;
[B,A]=butter(6,bands*2/100,'low'); % get filter coefficients for butter IIR hi
[data,devents,hdr,allevents]=slicepreproc(datadir,'startSet',struct('type','start','value',1,'sample',1),'trlen_ms',5000,'width_raw_ms',5000,'width_ms',20,'preprocFn',@(x,s,varargin) deal(filter(B,A,x,s,2),[]));

                                % alternative calling convention
[data,devents,hdr,allevents]=slicepreproc(datadir,'startSet',struct('type','start','value',1,'sample',1),'trlen_ms',5000,'width_raw_ms',5000,'preprocFn',{'filterFilt' 'filter',{'butter',6,10,'low'}});


figure(1);clf;mcplot([data0(1).buf(2,:);data(1).buf(2,:);data0(1).buf(3,:);data(1).buf(3,:)]');

                                % minimal standard pre-processing
[data,devents,hdr,allevents]=slicepreproc(datadir,'startSet',struct('type','start','value',1,'sample',1),'trlen_ms',5000,'width_raw_ms',5000,'preprocFn',{'minimalPreprocFilter' 'bands',[1 10],'subsample',10});


% time-frequency decomposition, 4hz resolution, 10hz feature rate
% N.B. we assume a 100hz sample rate
[data,devents,hdr,allevents]=slicepreproc(datadir,'startSet',struct('type','start','value',1,'sample',1),'trlen_ms',5000,'width_raw_ms',5000,'width_ms',250,'step_ms',100,'preprocFn',@(x,s) welchpsd(x,2,'width_samp',25));

% plot the resulting sliced TFR
clf;image3d(reshape(data(1).buf,[size(data(1).buf,1) size(data(1).buf,2)/50 50]),'xlabel','ch','ylabel','freq','zlabel','time');

