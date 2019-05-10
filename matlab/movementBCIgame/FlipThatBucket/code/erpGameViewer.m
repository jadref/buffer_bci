function [data, devents] = erpGameViewer(buffhost,buffport)
% simple viewer for ERPs based on matching buffer events

% define parameters
trlen_ms = 0;
intention = -0.25;
linewidth = 1.5;
plot_min = -3.5;
plot_max = 1;
rp_ymin = -10;
rp_ymax = 5;
offset_ms = [-5000 3000];
welch_width_ms = 500;
freqbands = [0.1 0.2 45 47];
freqbands_emg = [{30 47} {53 97} {103 160}]; %[47 51 250 256];
plot_nms = {'Brain ERD (C3)', 'Brain RP (Cz)', 'Muscle (arm)'};
cuePrefix = 'move';
cueValue = 'scientist';
endType = 'experiment.end';
redraw_ms = 250;
verb = 1;
badchthresh = 3.5;
badtrthresh = 3.5;
maxEvents = 150; % remember up to 50 trials
timeout_ms = 250; 
spect_width_ms = 500;
freqRange = [8 30];
ylabel_f = 'freq (Hz)';  
ylabel_t = 'time (s)';
linecols='brkgcmyk';
emg_chan1 = 'EMG1'; % EDITED
emg_chan2 = 'EMG2';% EDITED
erd_chan = 'C3';% EDITED
rp_chan = 'Cz';% EDITED
downsampleFr = []; % downsample to 128Hz
nrEEG = 14; % channels 1:nrEEG are considered EEG channels  EDITED

% define the buffer
if (nargin<1 || isempty(buffhost)) 
    buffhost = 'localhost'; 
end
if (nargin<2 || isempty(buffport)) 
    buffport = 1972;
end
wb = which('buffer'); 
if (isempty(wb) || isempty(strfind('dataAcq',wb))); 
    cd(fullfile('~','buffer_bci','matlab','utilities'));
    initPaths;
end
if (ischar(buffport)) 
    buffport=toi(buffport); 
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
capFile= 'cap_porti_16ch_flipThatBucket.txt';  % get our capfile
    
if (~isempty(capFile)) 
  overridechnms = 1; %default -- assume cap-file is mapping from wires->name+pos
  if (~isempty(strfind(capFile,'cap_porti_16ch_flipThatBucket.txt')) || ~isempty(strfind(capFile,'subset'))) 
     overridechnms = 0; % capFile is just position-info / channel-subset selection
  end 
  di = addPosInfo(ch_names,capFile,overridechnms,0,1); % get 3d-coords
  ch_pos = cat(2,di.extra.pos2d); % extract pos and channels names
  ch_pos3d = cat(2,di.extra.pos3d);
  ch_names = di.vals; %EDITED
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
if(~isempty(downsampleFr)) % update the plotting info
  outsz(2) = min(outsz(2),floor(outsz(1)*downsampleFr/fs)); 
  times = (1:outsz(2))./downsampleFr + offset_samp(1)/fs;
end

% recording the ERP data
key      = {};
label    = {};
nCls     = 0;                      
rawEpochs = zeros(sum(iseeg),outsz(1),maxEvents); 
rawIds   = 0;
nTarget  = 0;
rp      = zeros(1,outsz(2),max(1,nCls)); % stores the pre-proc data used in the figures
emg      = zeros(1,outsz(2),max(1,nCls)); % stores the pre-proc data used in the figures
isbadch  = false(nrEEG,1);
spectIdx = 0;
% spectogram

[ppspect,start_samp,spectFreqs] = spectrogram(rawEpochs(1:nrEEG,:,1),2,'width_ms',spect_width_ms,'fs',fs);
spectFreqInd = find(spectFreqs > freqRange(1) & spectFreqs < freqRange(2));
erd(:,:,:,1) = ppspect(1,spectFreqInd,:); % subset to freq range of interest and average over trials
times_f = linspace(times(1),times(end),size(erd,3));
spectEpochs = zeros(1,numel(spectFreqInd),size(erd,3),1); 
base_period_f = find(times_f >= -3.500 & times_f <= -2.500);

% make the figure window
fig = figure(1); clf;
set(fig,'Name','ER(s)P Viewer (close window = quit)','menubar','none','toolbar','none','doublebuffer','on');
updatePlot(linecols,intention,ylabel_t,times_f,spectFreqs,spectFreqInd,erd,ylabel_f,plot_min,plot_max,plot_nms,times,rp,rp_ymin, rp_ymax,emg, nCls, label,linewidth);
resethdl = uicontrol(fig,'Style','togglebutton','units','normalized','position',[0.8 0.94 .2 0.06],'String','Reset');

% empty buffer
[datai,deventsi,state,waitDatopts] = buffer_waitData(buffhost,buffport,[],'startSet',{cuePrefix cueValue},'offset_samp',offset_samp,'exitSet',{redraw_ms 'data' endType},'verb',verb,1,'timeOut_ms',timeout_ms);
fprintf('Waiting for events of type: %s\n %s\n',cuePrefix,cueValue);
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
        rawEpochs = zeros(sum(iseeg),outsz(1),maxEvents); 
        rp      = zeros(1,outsz(2),1); % stores the pre-proc data used in the figures
        emg      = zeros(1,outsz(2),1); % stores the pre-proc data used in the figures
        % spectogram
        [ppspect,start_samp,spectFreqs] = spectrogram(rawEpochs(1:nrEEG,:,end),2,'width_ms',spect_width_ms,'fs',fs);
        spectIdx = 0;
        spectFreqInd = find(spectFreqs > freqRange(1) & spectFreqs < freqRange(2));
        erd(:,:,:,1) = ppspect(1,spectFreqInd,:); % subset to freq range of interest and average over trials
        spectEpochs = zeros(1,numel(spectFreqInd),size(erd,3),1); 
        
        % draw figure again
        updatePlot(linecols,intention,ylabel_t,times_f,spectFreqs,spectFreqInd,erd,ylabel_f,plot_min,plot_max,plot_nms,times,rp,rp_ymin, rp_ymax,emg, nCls, label,linewidth);
        resethdl = uicontrol(fig,'Style','togglebutton','units','normalized','position',[0.8 0.94 .2 0.06],'String','Reset');
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
        % CAR on all data
        carmean = mean(rawEpochs(1:nrEEG,:,:),1);
        
        ppdat = rawEpochs(1:nrEEG,:,:); % only EEG

        % common pre-processing ERP & ERD
        % (1) mastoid reference
        %masIdx(1)= find(strcmp(ch_names,ref_chan1));
        %masIdx(2)= find(strcmp(ch_names,ref_chan2));
        %ppdat = repop(ppdat,'-',mean(ppdat(masIdx,:,:),1));
        ppdat = repop(ppdat,'-',carmean);

        % (2) center the data (demean)
        ppdat = repop(ppdat,'-',mean(ppdat,2)); 

       % (6) filter
       ppdat_RP = fftfilter(ppdat,filt,outsz,2,0);
      
       % (7) baseline
       ppdat_RP = repop(ppdat_RP,'-',mean(ppdat_RP(:,base_period,:),2));

       % EMG
       % (A) Only keep EMG channels and subtract bipolar EMG channels  
       emg_ch(1) = find(strcmp(ch_names,emg_chan1));
       emg_ch(2) = find(strcmp(ch_names,emg_chan2));
       cardat_emg = repop(rawEpochs(emg_ch,:,:),'-',carmean);
       %ppdat_EMG = rawEpochs(emg_ch(1),:,:)-rawEpochs(emg_ch(2),:,:);
       ppdat_EMG = cardat_emg(1,:,:)-cardat_emg(2,:,:);
       % (B) demean
       ppdat_EMG = repop(ppdat_EMG,'-',mean(ppdat_EMG,2)); 
       % (C) filter
       ppdat_EMG = fftfilter(ppdat_EMG,filt_emg,outsz,2,0);
       % (D) take absolute value
       ppdat_EMG = abs(ppdat_EMG);
      
       % calculate ERP for every class
       for mi=1:nCls
           ppdatmi_RP = ppdat_RP(:,:,rawIds==mi); % get this class data
           ppdatmi_ERD = ppdat(:,:,rawIds==mi); % get this class data
           ppdatmi_EMG = ppdat_EMG(:,:,rawIds==mi); % get this class data

           % Calculate ERD
           ppspectmi = spectrogram(ppdatmi_ERD(:,:,end),2,'width_ms',spect_width_ms,'fs',fs);
           % baseline spectogram
           ppspectmi = repop(ppspectmi,'-',median(ppspectmi(:,:,base_period_f,:),3));
           spectIdx = spectIdx+1;
           spectEpochs(:,:,:,spectIdx) = ppspectmi(find(strcmp(ch_names,erd_chan)),spectFreqInd,:);
           erd(:,:,:,mi) = median(spectEpochs,4);
           rp(:,:,mi) = median(ppdatmi_RP(find(strcmp(ch_names,rp_chan)),:,:),3);
           emg(:,:,mi) = median(ppdatmi_EMG,3);

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
           updatePlot(linecols,intention,ylabel_t,times_f,spectFreqs,spectFreqInd,erd,ylabel_f,plot_min,plot_max,plot_nms,times,rp,rp_ymin, rp_ymax,emg, nCls, label,linewidth)

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

function updatePlot(linecols,intention,ylabel_t,times_f,spectFreqs,spectFreqInd,erd,ylabel_f,plot_min,plot_max,plot_nms,times,rp,rp_ymin, rp_ymax,emg, nCls, label,linewidth)
    % update plot
    subplot(3,1,1);
    imagesc(times_f,spectFreqs(spectFreqInd),squeeze(erd(:,:,:,1))); ylabel(ylabel_f); xlim([plot_min plot_max]); caxis([-max(abs(erd(:))) max(abs(erd(:)))]);
    hold on; plot([0 0], [min(spectFreqs) max(spectFreqs)],'r','LineWidth',linewidth); 
    plot([intention intention], ylim,'k--','LineWidth',linewidth); hold off;
    title(plot_nms{1})
    subplot(3,1,2);
    for mi=1:nCls
         plot(times,rp(:,:,mi),linecols(mi),'LineWidth',linewidth); 
         hold on;
    end
    hold on;
    ylabel('amplitude (mV)'); xlim([plot_min plot_max]);
    plot([intention intention], ylim,'k--','LineWidth',linewidth);
    plot([0 0], ylim,'r','LineWidth',linewidth); hold off;
    title(plot_nms{2})
    subplot(3,1,3);
   % add class labels
    for mi=1:nCls
        emgPlot = plot(times,emg(:,:,mi),linecols(mi),'LineWidth',linewidth);
        hold on;
    end
    legend(label,'west');
    hold on;
   xlabel(ylabel_t); ylabel('amplitude (mV)'); xlim([plot_min plot_max]);
   plot([0 0], ylim,'r','LineWidth',linewidth); 
   plot([intention intention], ylim,'k--','LineWidth',linewidth); hold off;
   title(plot_nms{3})      
end

function freqIdx=getfreqIdx(freqs,freqbands)
if ( nargin<1 || isempty(freqbands) ) freqIdx=[1 numel(freqs)]; return; end;
[ans,freqIdx(1)]=min(abs(freqs-max(freqs(1),freqbands(1)))); 
[ans,freqIdx(2)]=min(abs(freqs-min(freqs(end),freqbands(end))));
end