function [data, devents] = erpViewer(buffhost,buffport)
% simple viewer for ERPs based on matching buffer events

% define parameters
trlen_ms = 0;
linewidth = 1.5;
plot_min = -0.1;
plot_max = 0.9;
offset_ms = [-5000 2000];
freqbands = [0.1 0.2 30 40];
cuePrefix = 'stimulus';
endType = 'experiment.end';
redraw_ms = 250;
verb = 1;
maxEvents = 150; % remember up to 150 trials
timeout_ms = 250;   
linecols='brkgcmyk';
erp_chan = {'Cz','Pz','Oz'}; 
downsampleFr = []; % downsample

% define the buffer
if (nargin<1 || isempty(buffhost)) 
    buffhost = 'localhost'; 
end
if (nargin<2 || isempty(buffport)) 
    buffport = 1972;
end
wb = which('buffer'); 
if (isempty(wb) || isempty(strfind('dataAcq',wb))); 
    cd('../utilities/');
    initPaths;
end
if (ischar(buffport)) 
    buffport=toi(buffport); 
end
fprintf('Connection to buffer on %s : %d\n',buffhost,buffport);

% get channel info for plotting
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
iseeg = true(numel(ch_names),1);
% get capFile info for positions
capFile= 'cap_tmsi_mobita_16ch.txt';  % get our capfile
    
if (~isempty(capFile)) 
  overridechnms = 1; %default -- assume cap-file is mapping from wires->name+pos
  if (~isempty(strfind(capFile,'cap_tmsi_mobita_16ch.txt')) || ~isempty(strfind(capFile,'subset'))) 
     overridechnms = 0; % capFile is just position-info / channel-subset selection
  end 
  di = addPosInfo(ch_names,capFile,overridechnms,0,1); % get 3d-coords
  ch_names = di.vals; 
  iseeg = [di.extra.iseeg];
  if (~any(iseeg) || ~isempty(strfind(capFile,'showAll.txt'))) % fall back on showing all data
    warning('Capfile didnt match any data channels -- no EEG?');
    ch_names = hdr.channel_names;
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
base_period = find(times >= -0.1 & times <= 0);

% make the spectral filter
outsz = trlen_samp-offset_samp(1)+offset_samp(2); 
outsz(2) = outsz(1);
filt=[]; 
if (~isempty(freqbands)) 
    filt = mkFilter(outsz(1)/2, freqbands, fs/outsz(1));
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
erp      = zeros(sum(iseeg),outsz(2),max(1,nCls)); % stores the pre-proc data used in the figures

% make the figure window
fig = figure(1); clf;
set(fig,'Name','ERP Viewer (close window = quit)','menubar','none','toolbar','none','doublebuffer','on');
updatePlot(linecols,plot_min,plot_max,erp_chan,times,erp,nCls,label,linewidth,ch_names);
resethdl = uicontrol(fig,'Style','togglebutton','units','normalized','position',[0.8 0.94 .2 0.06],'String','Reset');

% empty buffer
[datai,deventsi,state,waitDatopts] = buffer_waitData(buffhost,buffport,[],'startSet',cuePrefix,'offset_samp',offset_samp,'exitSet',{redraw_ms 'data' endType},'verb',verb,1,'timeOut_ms',timeout_ms);
fprintf('Waiting for events of type: %s\n',cuePrefix);
data = {}; 
devents = []; % for returning the data/events
endTraining = false;

% start loop
while (~endTraining) 
    drawnow; % update screen
    
    % check reset button
    resetval = get(resethdl,'value');
    if (resetval)   
        label    = {};
        nCls     = 0;                         
        fprintf('reset detected\n');
        key = {}; 
        nTarget = 0; 
        rawIds = []; 
        devents = [];
        rawEpochs = zeros(sum(iseeg),outsz(1),maxEvents); 
        erp      = zeros(sum(iseeg),outsz(2),max(1,nCls)); % stores the pre-proc data used in the figures
        
        % draw figure again
        updatePlot(linecols,plot_min,plot_max,erp_chan,times,erp,nCls,label,linewidth,ch_names);        
        resethdl = uicontrol(fig,'Style','togglebutton','units','normalized','position',[0.8 0.94 .2 0.06],'String','Reset');
        resetval = 0;
        set(resethdl,'value',resetval); % pop the button back out
    end
    
    % wait for events...
    [datai,deventsi,state] = buffer_waitData(buffhost,buffport,state,waitDatopts);
    
    % loop through trials
    newClass = false;
    for ei=1:numel(deventsi);
        event=deventsi(ei);
        if(matchEvents(event,endType))
            % end-training event
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
             erp(:,:,mi)= 0;
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
        carmean = mean(rawEpochs(:,:,:),1);
        
        ppdat = rawEpochs(:,:,:); % only EEG

        % common pre-processing ERP & ERD
        ppdat = repop(ppdat,'-',carmean);

        % (2) center the data (demean)
        ppdat = repop(ppdat,'-',mean(ppdat,2)); 

       % (6) filter
       ppdat_ERP = fftfilter(ppdat,filt,outsz,2,0);
      
       % (7) baseline
       ppdat_ERP = repop(ppdat_ERP,'-',mean(ppdat_ERP(:,base_period,:),2));
      
       % calculate ERP for every class
       for mi=1:nCls
           ppdatmi_ERP = ppdat_ERP(:,:,rawIds==mi); % get this class data
           erp(:,:,mi) = median(ppdatmi_ERP,3);

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
           updatePlot(linecols,plot_min,plot_max,erp_chan,times,erp,nCls,label,linewidth,ch_names);
           
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

function updatePlot(linecols,plot_min,plot_max,erp_chan,times,erp,nCls,label,linewidth,ch_names)
    for ch=1:numel(erp_chan)
        chan_idx = find(strcmp(ch_names,erp_chan(ch)));
        subplot(numel(erp_chan),1,ch);
        for mi=1:nCls
             plot(times,erp(chan_idx,:,mi),linecols(mi),'LineWidth',linewidth); 
             hold on;
        end
        ylabel('amplitude (mV)'); xlim([plot_min plot_max]);
        plot([0 0], ylim,'k','LineWidth',linewidth); hold off;
        title(erp_chan{ch})
    end
    if ~isempty(label)
        legend(label);
    end
    hold off;
    xlabel('time (s)');     
end