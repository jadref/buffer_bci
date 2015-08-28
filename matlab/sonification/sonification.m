function []=sonification(clsfr,varargin)
% continuously apply this classifier to the new data
%
%  []=sonification(clsfr,varargin)
%
% Options:
%  buffhost, buffport, hdr
%  endType, endValue  -- event type and value to match to stop giving feedback
%  trlen_ms/samp -- [float] length of trial to apply classifier to               (500ms)
%                     if empty, then = windowFn size used in the classifier training
%  overlap       -- [float] fraction of trlen_samp between successive classifier predictions, i.e.
%                    prediction at, t, t+trlen_samp*overlap, t+2*(trlen_samp*overlap), ...
%  step_ms       -- [float] time between classifier predictions                 (100)
%  freqShift     -- [float 2x1] amount in hz to up-shift and spread the frequency for audio ([300 10])
%                          i.e. nf = of*freqShift(2) + freqShift(1)
%  volAlpha      -- [float] decay const for the auto-volume est                 (.99)
%                            alpha = exp(log(.5)/half-life)
wb=which('buffer'); if ( isempty(wb) || isempty(strfind('dataAcq',wb)) ); run('../../utilities/initPaths.m'); end;

opts=struct('buffhost','localhost','buffport',1972,'hdr',[],...
            'endType','stimulus.test','endValue','end','verb',0,...
            'trlen_ms',1000,'trlen_samp',[],'overlap',[],'step_ms',200,...
				'audiofs',2000,'freqShift',[50 10],'volAlpha',.99,...
            'timeout_ms',1000,'visualize',0); 
[opts,varargin]=parseOpts(opts,varargin);

% work out how much data we need to process
fs=[];
trlen_samp=opts.trlen_samp; 
if ( isempty(trlen_samp) ) 
  if ( ~isempty(opts.trlen_ms) ) 
    if(~isempty(opts.hdr)) fs=opts.hdr.fsample; 
    else opts.hdr=buffer('get_hdr',[],opts.buffhost,opts.buffport); fs=opts.hdr.fsample; 
    end;
    trlen_samp = opts.trlen_ms /1000 * fs; 
  end
end;

% get time to wait between classifier applications
if ( ~isempty(opts.step_ms) )
	if ( isempty(fs) )
	  if(~isempty(opts.hdr)) fs=opts.hdr.fsample; 
	  else opts.hdr=buffer('get_hdr',[],opts.buffhost,opts.buffport); fs=opts.hdr.fsample; 
	  end;
	end
  step_samp = round(opts.step_ms/1000 * fs);
else
  step_samp = round(trlen_samp * opts.overlap);
end

% get the current number of samples, so we can start from now
status=buffer('wait_dat',[-1 -1 -1],opts.buffhost,opts.buffport);
nEvents=status.nevents; nSamples=status.nsamples;

% pre-compute the stuff needed for the frequency filter
if ( isempty(fs) )
  if(~isempty(opts.hdr)) fs=opts.hdr.fsample; 
  else opts.hdr=buffer('get_hdr',[],opts.buffhost,opts.buffport); fs=opts.hdr.fsample; 
  end;
end
win        = mkFilter(trlen_samp,'hanning'); % hanning window for the raw EEG
eegfftbins = fftBins(trlen_samp,[],fs);
audioLen   = opts.audiofs * trlen_samp/fs; % the buffer of audio-data to store
audioStep  = opts.audiofs * step_samp/fs;  % the step-size for the audio data
audioBuf   = zeros(1,audioLen); % mono-buffer for the audio data
audiofftBuf= complex(audioBuf,audioBuf); % mono-buffer for fft of the audio
audiofftbins=fftBins(audioLen,[],opts.audiofs);

% strip 0Hz & nyquist bins as they cause problems
eegfftIdx  = true(size(eegfftbins)); 
eegfftIdx(1) = false; % 0Hz
eegfftIdx(abs(eegfftbins)==max(abs(eegfftbins)))=false; % nyquist
eegfftIdx  = find(eegfftIdx); 

shiftfftIdx = zeros(numel(eegfftIdx),1); % index in audiofftbins for eegfftbins
shiftfftFreq= zeros(numel(eegfftIdx),1); % freq of shifted bin
freqShift=opts.freqShift; if ( numel(freqShift)<2 ) freqShift(2)=1; end;
for i=1:numel(eegfftIdx); 
  freqi=eegfftbins(eegfftIdx(i));
  shiftfreqi = sign(freqi)*(abs(freqi)*freqShift(2)+freqShift(1)); % move away from orgin
  [ans,shiftfftIdx(i)] = min(abs(shiftfreqi-audiofftbins)); % closest matching in audio
  shiftfftFreq(i)=audiofftbins(shiftfftIdx(i));
end

% init the java audio output
% buffer big enough to allow non-blocking fill
javaaddpath(fileparts(mfilename('fullpath'))); % add this directory to java path
soundLine = javaObject('soundline',opts.audiofs,2*audioLen); % creat the playback object

% plotting
if ( opts.visualize ) clf; h=plot(audioBuf,'lineWidth',2); end;

dv=[];
nEpochs=0;
vol=-1;
endTest=false;
tic;t1=0;
while( ~endTest )

  % block until new data to process
  status=buffer('wait_dat',[nSamples+trlen_samp -1 opts.timeout_ms],opts.buffhost,opts.buffport);
  if ( status.nsamples < nSamples ) 
    fprintf('Buffer restart detected!'); 
    nSamples=status.nsamples;
    dv(:)=0;
    continue;
  end
    
  % logging stuff for when nothing is happening... 
  if ( opts.verb>=0 ) 
    t=toc;
    if ( t-t1>=5 ) 
      fprintf(' %5.3f seconds, %d samples %d events\r',t,status.nsamples,status.nevents);
      if ( ispc() ) drawnow; end; % re-draw display
      t1=t;
    end;
  end;
    
  % process any new data
  onSamples=nSamples;
  start = onSamples:step_samp:status.nsamples-trlen_samp-1; % window start positions
  if( ~isempty(start) ) nSamples=start(end)+step_samp; end % start of next trial for which not enough data yet
  for si = 1:numel(start);    
    nEpochs=nEpochs+1;
    
    % get the data
    data = buffer('get_dat',[start(si) start(si)+trlen_samp-1],opts.buffhost,opts.buffport);
      
    if ( opts.verb>1 ) fprintf('Got data @ %d->%d samp\n',start(si),start(si)+trlen_samp-1); end;
      
	 % play the bit that is finished
	 soundLine.write(audioBuf.*128/vol,0,audioStep); % send to the audio-device
	 % shift away and add in the new data
	 tmp = audioBuf(audioStep+1:end);

    % TODO: apply pre-processing pipeline to this events data
	 % BODGE: frequency shift
	 eeg          = sum(data.buf(:,1:trlen_samp),1)';
	 eeg          = detrend(eeg,1);
	 eeg          = eeg(:).*win(:);
	 eegfft       = fft(eeg,trlen_samp,1); % fft the 1st channel of the EEG
	 audiofftBuf(shiftfftIdx) = eegfft(eegfftIdx); % shift in frequency and insert in to audiofftbuffer
	 audioBuf     = real(ifft(audiofftBuf));  % convert back to time-domain
	 audioVol      = std(audioBuf);
	 if ( audioVol>0 ) 
		if ( vol<0 ) vol=std(audioBuf);
		else         vol=(1-opts.volAlpha)*std(audioBuf) + opts.volAlpha * vol;
		end
	 end
	 % clf;plot(linspace(0,1,numel(eeg)),eeg-mean(eeg)); hold on; plot(linspace(0,1,numel(audioBuf)),audioBuf,'g');
	 % inlude the old data for smoothing
	 audioBuf(1:numel(tmp))=audioBuf(1:numel(tmp))+tmp;
	 if ( opts.visualize ) set(h,'ydata',audioBuf);drawnow; end;
  end
    
  % deal with any events which have happened
  if ( status.nevents > nEvents )
    devents=buffer('get_evt',[nEvents status.nevents-1],opts.buffhost,opts.buffport);
    mi=matchEvents(devents,opts.endType,opts.endValue);
    if ( any(mi) ) fprintf('Got exit event. Stopping'); endTest=true; end;
    nEvents=status.nevents;
  end
end % while not endTest
soundLine.stop();
return;
%--------------------------------------
function testCase()
cont_applyClsfr(clsfr,'overlap',.1)
% smooth output with standardising filter, such that mean=0 and variance=1 over last 100 predictions
cont_applyClsfr(clsfr,'predFilt',@(x,s) stdFilt(x,s,exp(log(.5)/100)));
