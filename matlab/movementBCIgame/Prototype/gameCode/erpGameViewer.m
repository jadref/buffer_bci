function [data, devents] = erpGameViewer(buffhost,buffport)
% simple viewer for ERPs based on matching buffer events

% define parameters
trlen_ms = 5000;
offset_ms = [-3500 -1000];
welch_width_ms = 500;
freqbands = [0.1 0.2 47 60];
freqbands_emg = [47 51 250 256];
plot_nms = {'Brain ERD (C3)', 'Brain RP (Cz)', 'Muscle (arm)'};
downsample = 128;
plotPos = [1 3;  1 2; 1 1];
lineWidth = 1;
cuePrefix = 'stimulus.target';
cueValue = 'move';
endType = 'end.training';
redraw_ms = 250;
verb = 1;
badchthresh = 3.5;
badtrthresh = 3.5;
maxEvents = 50; % remember up to 50 trials
timeout_ms = 250; 
spect_width_ms = 500;
freqRange = [8 30];
ylabel_f = 'freq (Hz)';  
ylabel_t = 'time (s)';
linecols='brkgcmyk';
emg_chan1 = 'noise1'
emg_chan2 = 'noise2'
erd_chan = 'sin10.0Hz';
rp_chan = 'noise1';
ref_chan1 = 'noise1';
ref_chan2 = 'noise2';

% define the buffer
if (nargin<1 || isempty(buffhost)) 
    buffhost = 'localhost'; 
end
if (nargin<2 || isempty(buffport)) 
    buffport = 1972;
end
wb = which('buffer'); 
if (isempty(wb) || isempty(strfind('dataAcq',wb))); 
    run(fullfile('..','..','..','utilities','initPaths.m')); 
end
if (ischar(buffport)) 
    buffport=atoi(buffport); 
end
fprintf('Connection to buffer on %s : %d\n',buffhost,buffport);

% get channel info for plotting
hdr=[];
    hdr=buffer('get_hdr',[],buffhost,buffport); 
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
  try 
    hdr=buffer('get_hdr',[],buffhost,buffport); 
  catch
    hdr=[];
    fprintf('Invalid header info... waiting.\n');
  end;
  pause(1);
end;

% extract channel info from hdr
ch_names = hdr.channel_names; 
ch_pos = []; 
ch_pos3d = []; 
iseeg = true(numel(ch_names),1);
% get capFile info for positions
capFile = []; 
overridechnms = []; 
capFile='1010.txt';  % 1010 default if not selected
    
if (~isempty(capFile)) 
  overridechnms = 1; %default -- assume cap-file is mapping from wires->name+pos
  if (~isempty(strfind(capFile,'1010.txt')) || ~isempty(strfind(capFile,'subset'))) 
     overridechnms = 0; % capFile is just position-info / channel-subset selection
  end 
  di = addPosInfo(ch_names,capFile,overridechnms,0,1); % get 3d-coords
  ch_pos = cat(2,di.extra.pos2d); % extract pos and channels names
  ch_pos3d = cat(2,di.extra.pos3d);
  ch_names = di.vals; 
  iseeg = [di.extra.iseeg];
  if (~any(iseeg) || ~isempty(strfind(capFile,'showAll.txt'))) % fall back on showing all data
    warning('Capfile didnt match any data channels -- no EEG?');
    ch_names = hdr.channel_names;
    ch_pos = [];
    iseeg = true(numel(ch_names),1);
  end
end

if (isfield(hdr,'fSample'))
    fs=hdr.fSample; 
else
    fs=hdr.fsample;
end
trlen_samp=[];
if (isempty(trlen_samp) && ~isempty(trlen_ms)) 
    trlen_samp=round(trlen_ms*fs/1000); 
end
offset_samp=[];
if (isempty(offset_samp) && ~isempty(offset_ms)) 
    offset_samp=round(offset_ms*fs/1000); 
end
if (isempty(offset_samp)) 
    offset_samp=[0 0]; 
end
times=((1+offset_samp(1)):(trlen_samp+offset_samp(2)))./fs; % include the offset
base_period = find(times >= -3.500 & times <= -2.500);
freqs=0:1000/welch_width_ms:fs/2;
if (~isempty(freqbands))
  freqIdx=getfreqIdx(freqs,freqbands);
else
  opts.freqbands=[1 freqs(end)];
  freqIdx=[1 numel(freqs)];
end

% make the spectral filter
outsz = trlen_samp-offset_samp(1)+offset_samp(2); 
outsz(2) = outsz(1);
filt=[]; 
if (~isempty(freqbands)) 
    filt = mkFilter(outsz(1)/2, freqbands, fs/outsz(1));
end
if (~isempty(freqbands_emg)) 
    filt_emg = mkFilter(outsz(1)/2, freqbands_emg, fs/outsz(1));
end
if(~isempty(downsample)) % update the plotting info
  outsz(2) = min(outsz(2),floor(outsz(1)*downsample/fs)); 
  times = (1:outsz(2))./downsample + offset_samp(1)/fs;
end

% recording the ERP data
key      = {};
label    = {};
nCls     = 0;                      
rawEpochs = zeros(numel(ch_names),outsz(1),maxEvents); 
rawIds   = 0;
nTarget  = 0;
rp      = zeros(1,outsz(2),max(1,nCls)); % stores the pre-proc data used in the figures
emg      = zeros(1,outsz(2),max(1,nCls)); % stores the pre-proc data used in the figures
isbadch  = false(sum(iseeg),1);
% spectogram
[ppspect,start_samp,spectFreqs] = spectrogram(rawEpochs,2,'width_ms',spect_width_ms,'fs',hdr.fsample);
spectFreqInd = find(spectFreqs > freqRange(1) & spectFreqs < freqRange(2));
erd = sum(ppspect(1,spectFreqInd,:,:),4)./size(ppspect(1,:,:,:),4); % subset to freq range of interest and average over trials
times_f = linspace(times(1),times(end),size(erd,3));
base_period_f = find(times_f >= -3.500 & times_f <= -2.500);

% make the figure window
fig = figure(1); clf;
set(fig,'Name','ER(s)P Viewer (close window = quit)','menubar','none','toolbar','none','doublebuffer','on');
subplot(3,1,1);
imagesc(times_f,spectFreqs(spectFreqInd),squeeze(erd)); ylabel(ylabel_f); colorbar;
title(plot_nms{1})
subplot(3,1,2);
plot(times,rp); ylabel('amplitude (mV)'); xlim([times(1) times(end)]);
title(plot_nms{2})
subplot(3,1,3);
plot(times,emg); xlabel(ylabel_t); ylabel('amplitude (mV)'); xlim([times(1) times(end)]);
title(plot_nms{3})
resethdl = uicontrol(fig,'Style','togglebutton','units','normalized','position',[0.8 0.94 .2 0.06],'String','Reset');
drawnow; % make sure the figure is visible

% empty buffer
[datai,deventsi,state,waitDatopts] = buffer_waitData(buffhost,buffport,[],'startSet',{cuePrefix cueValue},'trlen_samp',trlen_samp,'offset_samp',offset_samp,'exitSet',{redraw_ms 'data' endType},'verb',verb,1,'timeOut_ms',timeout_ms);
fprintf('Waiting for events of type: %s\n  %s\n',cuePrefix, cueValue);
data = {}; 
devents = []; % for returning the data/events
endTraining = false;

% start loop
while (~endTraining) 
    drawnow; % update screen
    
    % check reset button
    resetval = get(resethdl,'value');
    if (resetval) 
        fprintf('reset detected\n');
        key = {}; 
        nTarget = 0; 
        rawIds = []; 
        devents = [];
        rawEpochs = zeros(numel(ch_names),outsz(1),maxEvents); 
        rp      = zeros(1,outsz(2),1); % stores the pre-proc data used in the figures
        emg      = zeros(1,outsz(2),1); % stores the pre-proc data used in the figures
        % spectogram
        [ppspect,start_samp,spectFreqs] = spectrogram(rawEpochs,2,'width_ms',spect_width_ms,'fs',hdr.fsample);
        spectFreqInd = find(spectFreqs > freqRange(1) & spectFreqs < freqRange(2));
        erd = sum(ppspect(1,spectFreqInd,:,:),4)./size(ppspect(1,:,:,:),4); % subset to freq range of interest and average over trials
        
        % draw figure again
        subplot(3,1,1);
        imagesc(times_f,spectFreqs(spectFreqInd),squeeze(erd)); ylabel(ylabel_f); colorbar;
        title(plot_nms{1})
        subplot(3,1,2);
        plot(times,rp); ylabel('amplitude (mV)'); xlim([times(1) times(end)]);
        title(plot_nms{2})
        subplot(3,1,3);
        plot(times,emg); xlabel(ylabel_t); ylabel('amplitude (mV)'); xlim([times(1) times(end)]);
        title(plot_nms{3})
        
        resetval = 0;
        set(resethdl,'value',resetval); % pop the button back out
    end
    
    % wait for events...
    [datai,deventsi,state] = buffer_waitData(buffhost,buffport,state,waitDatopts);
    
    % loop through trials
    newClass = false;
    keep = true(numel(deventsi),1);
    for ei=1:numel(deventsi);
        event=deventsi(ei);
        if(matchEvents(event,endType))
            % end-training event
            keep(ei:end)=false;
            endTraining=true; % mark to finish
            fprintf('Discarding all subsequent events: exit\n');
            break;
        end
        
        val = event.value;      
        mi=[]; 
        if (~isempty(key)) % match if we've seen this key before 
            for ki=1:numel(key) 
                if (isequal(val,key{ki}))
                    mi=ki; 
                    break; 
                end 
            end 
        end
        
        if (isempty(mi)) % new class to average
			 newClass = true;
             key{end+1} = val;
             mi         = numel(key);
             rp(:,:,mi)= 0;
             erd(:,:,:,mi) = 0;
             emg(:,:,mi) = 0;
             nCls       = mi;
        end
        
        % store the data to return like buffer_waitdata
        if (isempty(devents)) 
           data = {datai(ei)};        
           devents = event;
        else
           data(end+1) = {datai(ei)}; 
           devents(end+1) = event;
        end

        % store the 'raw' data
        nTarget=nTarget+1;
        if (nTarget < maxEvents) 
            insertIdx=nTarget;  % insert at end
        else                       
             insertIdx=mod(nTarget,maxEvents); % ring buffer
        end
        rawIds(insertIdx)=mi;
        rawEpochs(:,:,insertIdx) = datai(ei).buf(iseeg,:); 
    end
    
    if ~isempty(deventsi) % only bother if something has changed and concerns move data
        ppdat = rawEpochs;

        % common pre-processing ERP & ERD
        % (1) mastoid reference
        masIdx(1)= find(strcmp(ch_names,ref_chan1));
        masIdx(2)= find(strcmp(ch_names,ref_chan2));
        ppdat(~isbadch,:,:) = repop(ppdat,'-',mean(ppdat(masIdx,:,:),1));

        % (2) center the data (demean)
        ppdat = repop(ppdat,'-',mean(ppdat,2)); 

        % (3) filter
        ppdat = fftfilter(ppdat(iseeg,:,:),filt,outsz,2,0);

        % (4) bad-channel identify and remove
        oisbadch = isbadch;
        isbadch = idOutliers(rawEpochs(iseeg,:,:),1,badchthresh);
        % set the data in this channel to 0
        ppdat(isbadch,:) = 0;
        % give feedback on which channels are marked as bad
        for hi=find(oisbadch(:)~=isbadch(:))';
           th=[];
           try
              th = get(hdls(hi),'title');
           catch
           end
           if (~isempty(th)) 
              tstr=get(th,'string'); 
              if(isbadch(hi))
                 if (~strcmp(tstr(max(end-5,1):end),' (bad)')) 
                     set(th,'string',[tstr ' (bad)']); 
                 end
              elseif (~isbadch(hi))
                 if (strcmp(tstr(max(end-5,1):end),' (bad)'));  
                     set(th,'string',tstr(1:end-6)); 
                 end
              end
           end

            % bad-ch rm also implies bad trial
            isbadtr = idOutliers(ppdat,3,badtrthresh);
            ppdat(:,:,isbadtr) = 0;
        end

       % (5) baseline
       ppdat_RP = repop(ppdat,'-',mean(ppdat(:,base_period,:),2));

       % EMG
       % (A) Only keep EMG channels and subtract bipolar EMG channels  
       emg_ch(1) = find(strcmp(ch_names,emg_chan1));
       emg_ch(2) = find(strcmp(ch_names,emg_chan2));
       ppdat_EMG = ppdat(emg_ch(1),:,:)-ppdat(emg_ch(2),:,:);
       % (B) filter
       ppdat_EMG = fftfilter(ppdat_EMG,filt_emg,outsz,2,0);
       % (C) take absolute value
       ppdat_EMG = abs(ppdat_EMG);
       % (D) low pass filter
       for ie = 1:size(ppdat_EMG,3) % Per epoch
           [B,A] = butter(1,16/128,'low');
           ppdat_EMG(:,:,ie) = filter(B,A,ppdat_EMG(:,:,ie));                        
       end

       % calculate ERP for every class
       for mi=1:nCls
           ppdatmi_RP = ppdat_RP(:,:,rawIds==mi); % get this class data
           ppdatmi_ERD = ppdat(:,:,rawIds==mi); % get this class data
           ppdatmi_EMG = ppdat_EMG(:,:,rawIds==mi); % get this class data

           % Calculate ERD
           ppspectmi = spectrogram(ppdatmi_ERD,2,'width_ms',spect_width_ms,'fs',hdr.fsample);
           % baseline spectogram
           ppspectmi = repop(ppspectmi,'-',mean(ppspectmi(:,:,base_period_f,:),3));

           % Calculate ERP
           erd(:,:,:,mi) = sum(ppspectmi(find(strcmp(ch_names,erd_chan)),spectFreqInd,:,:),4)./size(ppspectmi(1,:,:,:),4);
           rp(:,:,mi) = sum(ppdatmi_RP(find(strcmp(ch_names,rp_chan)),:,:),3)./size(ppdatmi_RP(2,:,:),3);
           emg(:,:,mi) = sum(ppdatmi_EMG,3)./size(ppdatmi_EMG,3);    

           if ( isnumeric(key{mi}) ) % line label -- including number of times seen
              label{mi}=sprintf('%g (%d)',key{mi},sum(rawIds(1:nTarget)==mi));
            else
              label{mi}=sprintf('%s (%d)',key{mi},sum(rawIds(1:nTarget)==mi));
           end	
       end

       % check whether figure still exists
       if (~ishandle(fig)) 
            break; 
       else
           % redraw whole image
           subplot(3,1,1)
           imagesc(times_f,spectFreqs(spectFreqInd),squeeze(erd(:,:,:,1))); ylabel(ylabel_f);
           title(plot_nms{1})
           subplot(3,1,2)
           for mi=1:nCls
                plot(times,rp(:,:,mi),linecols(mi)); 
                hold on;
           end
           hold off;
           ylabel('amplitude (mV)'); xlim([times(1) times(end)]);
           title(plot_nms{2})
           subplot(3,1,3) 
           for mi=1:nCls
                emgPlot = plot(times,emg(:,:,mi),linecols(mi));
                hold on;
           end
           hold off;
           xlabel(ylabel_t); ylabel('amplitude (mV)'); xlim([times(1) times(end)]);
           title(plot_nms{3})
           % add class labels
           legend(label);

           % indicate we've updated
           if (verb>0 ) 
               fprintf('.'); 
           end 
       end
    end
end

close(fig);

if(nargout>0) 
   rawIds = rawIds(1:nTarget);
   rawEpochs = rawEpochs(:,:,1:nTarget);
end

return
end

function freqIdx=getfreqIdx(freqs,freqbands)
if ( nargin<1 || isempty(freqbands) ) freqIdx=[1 numel(freqs)]; return; end;
[ans,freqIdx(1)]=min(abs(freqs-max(freqs(1),freqbands(1)))); 
[ans,freqIdx(2)]=min(abs(freqs-min(freqs(end),freqbands(end))));
end