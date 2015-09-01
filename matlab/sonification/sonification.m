function [allDat,soundLine]=sonification(clsfr,varargin)
% continuously apply this classifier to the new data
%
%  [allDat]=sonification(clsfr,varargin)
%
% Options:
%  buffhost, buffport, hdr
%  endType, endValue  -- event type and value to match to stop giving feedback  ('stimulus.test','end')
%                   OR
%                    [int] max duraton in milliseconds to run.                   
%  trlen_ms/samp -- [float] length of trial to apply classifier to               (500ms)
%                     if empty, then = windowFn size used in the classifier training
%  overlap       -- [float] fraction of trlen_samp between successive classifier predictions, i.e.
%                    prediction at, t, t+trlen_samp*overlap, t+2*(trlen_samp*overlap), ...
%  step_ms       -- [float] time between classifier predictions                 (100)
%  freqShift     -- [float 2x1] amount in hz to up-shift and spread the frequency for audio ([300 10])
%                          i.e. nf = of*freqShift(2) + freqShift(1)
%  volAlpha      -- [float] decay const for the auto-volume est                 (.99)
%                            alpha = exp(log(.5)/half-life)
%  soundLine     -- [javaObj] java soundline object to play the sounds with     ([])
% Examples:
%    sonification(); % default sonification with average over filters
wb=which('buffer'); if ( isempty(wb) || isempty(strfind('dataAcq',wb)) ); run('../../utilities/initPaths.m'); end;

opts=struct('buffhost','localhost','buffport',1972,'hdr',[],...
            'endType','stimulus.test','endValue','end','verb',0,...
            'trlen_ms',1000,'trlen_samp',[],'overlap',[],'step_ms',200,...
				'audiofs',2000,'freqShift',[50 10],'volAlpha',.9999,...
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
nbytes=1;
soundLine = javaObject('soundline',opts.audiofs,audioStep*4,nbytes); % creat the playback object
maxVol   = ((2^(8*nbytes-1))-1)/2; % max vol depends on bit-depth of the audio stream

% plotting
if ( opts.visualize ) clf; h=plot(audioBuf,'lineWidth',2); end;

dv=[];
nEpochs=0;
sigAmp=-1;
endTest=false;
% get the current number of samples, so we can start from now
status=buffer('wait_dat',[-1 -1 -1],opts.buffhost,opts.buffport);
nEvents=status.nevents; 
nSamples=status.nsamples+step_samp;

t0=javaMethod('currentTimeMillis','java.lang.System');  t1=t0;
while( ~endTest )

  t1=javaMethod('currentTimeMillis','java.lang.System');
  ts=javaMethod('currentTimeMillis','java.lang.System');
  % block until new data to process
  endSamp=nSamples;
  status=buffer('wait_dat',[endSamp -1 opts.timeout_ms],opts.buffhost,opts.buffport);
  tf=javaMethod('currentTimeMillis','java.lang.System');
  if ( opts.verb>0 ) fprintf('%3d) wd=[%3d->%3d]=%3d\t',nEpochs,ts-t1,tf-t1,tf-ts); end;
  if ( status.nsamples < nSamples ) 
    fprintf('Buffer restart detected!'); 
    nSamples=status.nsamples;
    dv(:)=0;
    continue;
  end
    
  % logging stuff for when nothing is happening... 
  if ( opts.verb>=0 ) 
    t=javaMethod('currentTimeMillis','java.lang.System'); 
    if ( t-t1>=5*1000 ) 
      fprintf(' %3d seconds, %d samples %d events\r',t,status.nsamples,status.nevents);
      if ( ispc() ) drawnow; end; % re-draw display
      t1=t;
    end;
  end;
    
  % process any new data
  onSamples=nSamples;
  fin = onSamples:step_samp:status.nSamples; % window fin positions
  % fin of next trial for which not enough data yet
  if( ~isempty(fin) ) nSamples=fin(end)+step_samp; end 
  %fprintf('%3d)  ons=%d \t tgtSamp=%d \t ns=%d \t nstep=%d\n',...
  %        nEpochs,onSamples,endSamp,status.nSamples,numel(fin)); 
  for si = 1:numel(fin);    
    nEpochs=nEpochs+1;
    
    % get the data
	 ts=javaMethod('currentTimeMillis','java.lang.System');
    data = buffer('get_dat',[fin(si)-trlen_samp fin(si)-1],opts.buffhost,opts.buffport);
	 tf=javaMethod('currentTimeMillis','java.lang.System');
	 if ( opts.verb>0 )
		if ( si>1 ) fprintf('\n                        '); end;
		fprintf('gd [%3d->%3d]=%3d\t',ts-t1,tf-t1,tf-ts); 
	 end


    if ( opts.verb>1 ) fprintf('Got data @ %d->%d samp\n',fin(si)-trlen_samp,fin(si)-1); end;
      
	 % play the bit that is finished
	 ts=javaMethod('currentTimeMillis','java.lang.System');
	 soundLineToFill = soundLine.available();
	 soundLineToPlay = soundLine.getBufferSize() - soundLineToFill;
	 %fprintf('%d) soundToGo=%d\n',nEpochs,soundLineToGo);
	 % EEG is running ahead of the audio, so only actually play the last one
	 if ( si~=numel(fin) ) 
		 fprintf('%d) skipping some eeg\n',nEpochs);
	 else
		if ( soundLineToPlay > audioStep ) % only if enough in buffer to not run out before we add more
		  soundLine.write(audioBuf.*maxVol/sigAmp,0,audioStep); % send to the audio-device
		else	 % over fill audio buffer to give a bit of space for later lags...
		  fprintf('%d) running out of audio.....\n',nEpochs);
		  soundLine.write(audioBuf.*maxVol/sigAmp,0,min(numel(audioBuf),ceil(audioStep*2)));
		end
	 end
	 %saudio=audioBuf.*maxVol/sigAmp;
	 %fprintf('%d) audio range [%g,%g,%g](%g) sigAmp=%g\n',nEpochs,max(saudio),mean(saudio),min(saudio),std(saudio),sigAmp);
	 tf=javaMethod('currentTimeMillis','java.lang.System');
    if ( opts.verb>0 ) fprintf('aud [%3d->%3d]=%3d\t',ts-t1,tf-t1,tf-ts); end;

	 % shift away and add in the new data
	 allDat{nEpochs}=audioBuf(1:audioStep); % save the data for later comparsion
	 tmp = audioBuf(audioStep+1:end);

	 ts=javaMethod('currentTimeMillis','java.lang.System');
    % TODO: apply pre-processing pipeline to this events data
	 % BODGE: frequency shift
	 eeg          = sum(data.buf(:,1:trlen_samp),1)';
	 eeg          = detrend(eeg,1);
	 eeg          = eeg(:).*win(:);
	 eegfft       = fft(eeg,trlen_samp,1); % fft the 1st channel of the EEG
	 audiofftBuf(shiftfftIdx) = eegfft(eegfftIdx); % shift in frequency and insert in to audiofftbuffer
	 audioBuf    = real(ifft(audiofftBuf));  % convert back to time-domain
	 audioLim    = max(abs(audioBuf));%std(audioBuf);
	 if ( audioLim>0 ) 
		if ( sigAmp<0 ) sigAmp=audioLim*4;
		else            sigAmp=max(audioLim,opts.volAlpha*sigAmp); %slow decay if needed
		end
	 end
	 % clf;plot(linspace(0,1,numel(eeg)),eeg-mean(eeg)); hold on; plot(linspace(0,1,numel(audioBuf)),audioBuf,'g');
	 % inlude the old data for smoothing
	 audioBuf(1:numel(tmp))=audioBuf(1:numel(tmp))+tmp;
	 tf=javaMethod('currentTimeMillis','java.lang.System');
    if ( opts.verb>0 ) fprintf('fs [%3d->%3d]=%3d\t',ts-t1,tf-t1,tf-ts); end;

	 if ( opts.visualize ) set(h,'ydata',audioBuf);drawnow; end;
  end
  if ( opts.verb>0 )  fprintf('\n'); end;
    
  % deal with any events which have happened
  if ( ischar(opts.endType) && status.nevents > nEvents  )
    devents=buffer('get_evt',[nEvents status.nevents-1],opts.buffhost,opts.buffport);
    mi=matchEvents(devents,opts.endType,opts.endValue);
    if ( any(mi) ) fprintf('Got exit event. Stopping'); endTest=true; end;
    nEvents=status.nevents;
  elseif ( isnumeric(opts.endType) ) % time-based termination
	 t=javaMethod('currentTimeMillis','java.lang.System');
	 if ( t-t0 > opts.endType ) fprintf('Got to end time. Stopping'); endTest=true; end;
  end
end % while not endTest
soundLine.stop();
return;
%--------------------------------------
function testCase()
[allDat,soundLine]=sonification('endType',10000);%run for 10s
allDat=cat(2,allDat{:});
soundLine.write(allDat*255)
