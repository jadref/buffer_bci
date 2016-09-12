function EMGcontroller(data,devents,varargin)
% Continuously decode EMG input to detect: rest, right hand movement, left
% hand movement, movement with both hands from ongoing EMG signals.
% EMG is recorded from two electrodes placed on the appropriate muscle of
% the left and right lower arm. The reference electrode is placed on the
% left earlobe/ankle/left wrist?
%
% Options:
%  buffhost, buffport, hdr
%  endType, endValue  -- event type and value to match to stop decoding
%                        audio signal
%  trlen_ms/samp -- [float] length of trial to use for decoding ([])
%  overlap       -- [float] fraction of trlen_samp between successive decodings, i.e.
%                    prediction at, t, t+trlen_samp*overlap, t+2*(trlen_samp*overlap), ...
%  step_ms       -- [float] time between decodings ([])

% Add all necessary paths
run ../utilities/initPaths.m;

opts=struct('buffhost','localhost','buffport',1972,'hdr',[],...
            'difficulty',1,...
            'endType','stimulus.test','endValue','end','verb',0,...
            'predEventType','classifier.prediction',...
            'trlen_ms',3000,'trlen_samp',[],'overlap',.5,'step_ms',500,...
            'predFilt',[],'timeout_ms',1000); % exp moving average constant, half-life=10 trials
[opts,varargin]=parseOpts(opts,varargin);

right = imread(fullfile('images','Right.png'));
left = imread(fullfile('images','Left.png'));
both = imread(fullfile('images','Both.png'));
relax = imread(fullfile('images','Relax.jpg'));
relax = imresize(relax,0.5);

% set threshold for movement
threshold = setEMGthreshold(data,devents,opts.hdr,opts.difficulty);

% %speed = both hands, rest = rest, jump = left hand, kick = right hand
cybathalon = struct('host','localhost','port',5555,'player',1,...
                    'cmdlabels',{{'jump' 'slide' 'speed' 'rest'}},'cmddict',[2 3 1 99],...
						  'cmdColors',[.6 0 .6;.6 .6 0;0 .5 0;.3 .3 .3]',...
                    'socket',[],'socketaddress',[]);
% open socket to the cybathalon game
[cybathalon.socket]=javaObject('java.net.DatagramSocket'); % create a UDP socket
cybathalon.socketaddress=javaObject('java.net.InetSocketAddress',cybathalon.host,cybathalon.port);
cybathalon.socket.connect(cybathalon.socketaddress); % connect to host/port
connectionWarned=0;

fig=figure(2);clf;
winColor=[0 0 0];
set(fig,'Name','Muscle Control','color',winColor,'menubar','none','toolbar','none','doublebuffer','on');
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',winColor,'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5]);

set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',[0.75 0.75 0.75],'visible','off');
set(txthdl,'string',{'Testing phase:' 'contract you muscles to control the game!'},'visible','on');

% set booleans for movement classes
rest = false; 
rightMove = false;
leftMove = false;
bothMove = false;

% create vector for saving data
history = [];

% if not explicitly given work out from the classifier information the trial length needed
% to apply the classifier
trlen_samp=opts.trlen_samp; 
if ( isempty(trlen_samp) ) 
  trlen_samp=0;
  if ( ~isempty(opts.trlen_ms) ) 
    if(~isempty(opts.hdr)) fs=opts.hdr.fsample; 
    else opts.hdr=buffer('get_hdr',[],opts.buffhost,opts.buffport); fs=opts.hdr.fsample; 
    end;
    trlen_samp = opts.trlen_ms /1000 * fs; 
  end
end

% get time to wait between classifier applications
if ( ~isempty(opts.step_ms) )
  if(~isempty(opts.hdr)) fs=opts.hdr.fsample; 
  else opts.hdr=buffer('get_hdr',[],opts.buffhost,opts.buffport); fs=opts.hdr.fsample; 
  end;
  step_samp = round(opts.step_ms/1000 * fs);
else
  step_samp = round(trlen_samp * opts.overlap);
end

% get the current number of samples, so we can start from now
status=buffer('wait_dat',[-1 -1 -1],opts.buffhost,opts.buffport);
nEvents=status.nevents; nSamples=status.nSamples; % most recent event/sample seen
endSample=nSamples+trlen_samp; % last sample of the first window to apply to

dv=[];
nEpochs=0; filtstate=[];
endTest=false;
tic;t0=0;t1=t0;
while( ~endTest )

   drawnow;
   if ( ~ishandle(fig) ) break; end;
  % block until new data to process
  status=buffer('wait_dat',[endSample -1 opts.timeout_ms],opts.buffhost,opts.buffport);
  if ( status.nSamples < nSamples ) 
    fprintf('Buffer restart detected!'); 
    nSamples =status.nSamples;
	 endSample=nSamples+trlen_samp;
    dv(:)=0;
    continue;
  end
  nSamples=status.nSamples; % keep track of last sample seen for re-start detection
    
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
  oendSample=endSample;
  fin = oendSample:step_samp:status.nSamples; % window start positions
  if( ~isempty(fin) ) endSample=fin(end)+step_samp; end %fin of next trial for which not enough data
  if ( numel(fin)>3 ) % drop frames if we can't keep up
	  fprintf('Warning: classifier cant keep up, dropping %d frames!\n',numel(fin)-1);
	  fin=fin(end);
  end
  for si = 1:numel(fin);    
    nEpochs=nEpochs+1;
    
    % get the data
    data = buffer('get_dat',[fin(si)-trlen_samp fin(si)-1],opts.buffhost,opts.buffport);
      
    if ( opts.verb>1 ) fprintf('Got data @ %d->%d samp\n',fin(si)-trlen_samp,fin(si)-1); end;
    
    % take only relevant EMG channels
    X = data.buf(1:4,:); % Check which channel to use... (channel 2 = up right muscle, 1 = bottom right muscle (closest to wrist), 4 = up left muscle, 3 = bottom left muscle (closest to wrist))
    
    % subtract bipolar EMG channels
    X(1,:) = data.buf(2,:)-data.buf(1,:); % right hand
    X(2,:) = data.buf(4,:)-data.buf(3,:); % left hand
    X(3:end,:) = [];
    
    % Filter
    freqband = [47 51 250 256];
    outsz=[size(X,2) size(X,2)];
    if (size(X,2)>10 && ~isempty(fs)) 
      len=size(X,2);
      filt=mkFilter(freqband,floor(len/2),fs/len);
      X   =fftfilter(X,filt,outsz,2,2);
    end
    
    % Rectify the signal = take absolute value
    X = abs(X);  
    %mean(mean(X))
    
    % Low pass filter the signal (cutoff =~ 15 Hz, since tau = 10ms for EMG), Welter et al., 2000; 1st order)
    for ch = 1:size(X,1) % Per channel
        [B,A] = butter(1,16/128,'low');
        X(ch,:) = filter(B,A,X(ch,:));  
    end
    
    % check for movement
    predTgt=[];
    aboveThresRight = find(X(2,:) > threshold);
    aboveThresLeft = find(X(1,:) > threshold);
    if ~isempty(aboveThresRight) && isempty(aboveThresLeft) % right hand movement
        rightMove = true;
        predTgt =  strcmp(cybathalon.cmdlabels,'kick');
        % send event if right movement was made
        maxSample = fin(si)-(length(X)-aboveThresRight(1));  %fin(si) is last sample, aboveTresh(1) is first sample above treshhold, Length(X)is current sample 
        
        sendEvent('rightMove',1,maxSample); %N.B. event sample is window-start!=(fin(si)-trlen_samp)
        fprintf('rightMove'); 
        subimage(right);
    elseif ~isempty(aboveThresLeft) && isempty(aboveThresRight) % left hand movement
        leftMove = true;
        predTgt =  strcmp(cybathalon.cmdlabels,'speed');
        % send event if left movement was made
        maxSample = fin(si)-(length(X)-aboveThresLeft(1));  %fin(si) is last sample, aboveTresh(1) is first sample above treshhold, Length(X)is current sample 

        sendEvent('leftMove',1,maxSample); %N.B. event sample is window-start!=(fin(si)-trlen_samp)
        fprintf('leftMove'); 
        subimage(left);
    elseif ~isempty(aboveThresRight) && ~isempty(aboveThresLeft) % both hands move
        bothMove = true;
        predTgt =  strcmp(cybathalon.cmdlabels,'jump');
        % send event if both hands move
        maxSample = fin(si)-(length(X)-aboveThresRight(1));  %fin(si) is last sample, aboveTresh(1) is first sample above treshhold, Length(X)is current sample 

        sendEvent('bothMove',1,maxSample); %N.B. event sample is window-start!=(fin(si)-trlen_samp)
        fprintf('bothMove'); 
        subimage(both);
    else % rest
        rest = true;
        % send event if both hands move
        maxSample = fin(si);  %fin(si) is last sample, aboveTresh(1) is first sample above treshhold, Length(X)is current sample 

        sendEvent('rest',1,maxSample); %N.B. event sample is window-start!=(fin(si)-trlen_samp)
        fprintf('rest'); 
        subimage(relax);
    end
    if ( ~isempty(predTgt) )
    try;
		cybathalon.socket.send(javaObject('java.net.DatagramPacket',uint8([10*cybathalon.player+cybathalon.cmddict(predTgt) 0]),1));
	 catch;
		if ( connectionWarned<10 )
		  connectionWarned=connectionWarned+1;
		  warning('Error sending to the Cybathalon game.  Is it running?\n');
		end
	 end
     end
    fprintf('\n');
  end
      
  if ( isnumeric(opts.endType) ) % time-based termination
	 t=toc;
	 if ( t-t0 > opts.endType ) fprintf('Got to end time. Stopping'); endTest=true; end;
  elseif( status.nevents > nEvents  ) % deal with any events which have happened
    devents=buffer('get_evt',[nEvents status.nevents-1],opts.buffhost,opts.buffport);
    mi=matchEvents(devents,opts.endType,opts.endValue);
    if ( any(mi) ) fprintf('Got exit event. Stopping'); endTest=true; end;
    nEvents=status.nevents;
  end
end % while not endTest
return;
%--------------------------------------
function testCase()
cont_applyClsfr(clsfr,'overlap',.1)
% bias adapting output smoothing, such that mean=0 over last 100 predictions
cont_applyClsfr(clsfr,'biasFilt',@(x,s) bialFilt(x,s,exp(log(.5)/100)));
% smooth output with standardising filter, such that mean=0 and variance=1 over last 100 predictions
cont_applyClsfr(clsfr,'predFilt',@(x,s) stdFilt(x,s,exp(log(.5)/100)));

