function []=sigViewer(buffhost,buffport,varargin);
% simple eegviewer function
%
% eegViewer(buffhost,buffport,varargin)
%
% Inputs:
%  buffhost -- host name where the buffer is
%  buffport -- port to connect to
% Options:
%  endType -- event type which means stop viewing eeg   ('end.training')
%  trlen_ms/trlen_samp -- amount of data to plot for each channel (5000ms)
%  updateFreq -- [single] frequency to re-draw the display           (4)
%  detrend    -- [bool]  detrend the data before plotting            (1)
%  fftfilter  -- [4x1] spectral filter to apply to the data before plotting ([.1 .3 45 47])
%  downsample -- [single] frequency to downsample to before drawing display (128)
%  spatfilt   -- 'str' name of type of spatial filtering to do to the data   ('car')
%  capFile    -- [str] capFile name to get the electrode positions from      ('1010')
%  overridechnms -- [bool] flag if we use the channel names from the capFile rather than the buffer (0)
%  welch_width_ms -- [single] size in time of the welch window               (500ms) 
%                      -> defines the frequency resolution for the frequency view of the data.   
%  freqbands  -- [2x1] frequency bands to display in the freq-domain plot    (opts.fftfilter)
%  noisebands -- [2x1] frequency bands to display for the 50 Hz noise plot   ([45 47 53 55])
wb=which('buffer'); if ( isempty(wb) || isempty(strfind('dataAcq',wb)) ) run('../utilities/initPaths.m'); end;
opts=struct('endType','end.training','verb',1,'trlen_ms',5000,'trlen_samp',[],'updateFreq',4,'detrend',1,'fftfilter',[.1 .3 45 47],'freqbands',[],'downsample',128,'spatfilt','car','capFile',[],'overridechnms',0,'welch_width_ms',500,'noisebands',[45 47 53 55],'noiseBins',[0 1],'timeOut_ms',1000);
opts=parseOpts(opts,varargin);
if ( nargin<1 || isempty(buffhost) ) buffhost='localhost'; end;
if ( nargin<2 || isempty(buffport) ) buffport=1972; end;
if ( isempty(opts.freqbands) && ~isempty(opts.fftfilter) ) opts.freqbands=opts.fftfilter; end;

% get channel info for plotting
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
  try 
    hdr=buffer('get_hdr',[],buffhost,buffport); 
  catch
    hdr=[];
    fprintf('Invalid header info... waiting.\n');
  end;
  pause(1);
end;
capFile=opts.capFile; overridechnms=opts.overridechnms; 
if(isempty(opts.capFile)) 
  [fn,pth]=uigetfile('../utilities/*.txt','Pick cap-file'); capFile=fullfile(pth,fn);
  if ( isequal(fn,0) || isequal(pth,0) ) capFile='1010.txt'; end; % 1010 default if not selected
end
if ( ~isempty(strfind(capFile,'1010.txt')) ) overridechnms=0; else overridechnms=1; end; % force default override
di = addPosInfo(hdr.channel_names,capFile,overridechnms); % get 3d-coords
ch_pos=cat(2,di.extra.pos2d); ch_names=di.vals; % extract pos and channels names
iseeg=[di.extra.iseeg];

if ( isfield(hdr,'fSample') ) fs=hdr.fSample; else fs=hdr.fsample; end;
trlen_samp=opts.trlen_samp;
if ( isempty(trlen_samp) && ~isempty(opts.trlen_ms) ) trlen_samp=round(opts.trlen_ms*fs/1000); end;
update_samp=ceil(fs/opts.updateFreq);
trlen_samp=ceil(trlen_samp/update_samp)*update_samp;
fprintf('tr_samp = %d update_samp = %d\n',trlen_samp,update_samp);
blkIdx = trlen_samp-update_samp; % index for where new data gets inserted
if ( isempty(opts.downsample) || opts.downsample>fs ) 
    times=(-trlen_samp+1:0)./fs;
else
    times=(-ceil((trlen_samp+1)*opts.downsample/fs):0)/opts.downsample;
end
freqs=0:1000/opts.welch_width_ms:fs/2;
[ans,freqIdx(1)]=min(abs(freqs-opts.freqbands(1))); 
[ans,freqIdx(2)]=min(abs(freqs-opts.freqbands(max(end,2))));
[ans,noiseIdx(1)]=min(abs(freqs-opts.noisebands(1))); 
[ans,noiseIdx(2)]=min(abs(freqs-opts.noisebands(max(end,2))));

% make the spectral filter
filt=[]; if ( ~isempty(opts.freqbands)) filt=mkFilter(trlen_samp/2,opts.freqbands,fs/trlen_samp);end
outsz=[trlen_samp trlen_samp];if(~isempty(opts.downsample)) outsz(2)=min(outsz(2),round(trlen_samp*opts.downsample/fs)); end;
  
% recording the ERP data
rawdat    = zeros(sum(iseeg),outsz(1));
ppdat     = zeros(sum(iseeg),outsz(2));
% and the spectrogram version
[ppspect,start_samp,freqs]=spectrogram(ppdat,2,'width_ms',opts.welch_width_ms,'fs',hdr.fsample);
ppspect=ppspect(:,freqIdx(1):freqIdx(2),:); % subset to freq range of interest
start_s=-start_samp(end:-1:1)/hdr.fsample;

% make the figure window
if ( exist('OCTAVE_VERSION','builtin') ) % in octave have to manually convert arrays..
  graphics_toolkit('fltk');
end
clf;
fig=gcf;
set(fig,'Name','Sig-Viewer : t=time, f=freq, p=50Hz power, s=spectrogram, q,close window=quit.','menubar','none','toolbar','none','doublebuffer','on');
axes('position',[0 0 1 1]); topohead();set(gca,'visible','off','nextplot','add');
hdls=image3d(ppspect,1,'plotPos',ch_pos(:,iseeg),'Xvals',ch_names,'yvals',freqs(freqIdx(1):freqIdx(2)),'ylabel','freq (hz)','zvals',start_s,'zlabel','time (s)','disptype','imaget','colorbar',1,'ticklabs','sw','legend',0,'plotPosOpts.plotsposition',[.05 .08 .91 .85]);
cbarhdl=[]; 
if ( strcmpi(get(hdls(end),'Tag'),'colorbar') ) 
  cbarhdl=hdls(end); hdls(end)=[]; cbarpos=get(cbarhdl,'outerposition');
  set(findobj(cbarhdl),'visible','off'); % store and make invisible
end;
if ( ~exist('OCTAVE_VERSION','builtin') ) % in octave have to manually convert arrays..
  zoomplots;
end
% install listener for key-press mode change
set(fig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
set(fig,'userdata',[]);
drawnow; % make sure the figure is visible

% make popup menu for selection of TD/FD
modehdl=[]; vistype=0; curvistype='time';
if ( ~exist('OCTAVE_VERSION','builtin') ) % in octave have to manually convert arrays..
  modehdl=uicontrol(fig,'Style','popup','units','normalized','position',[.8 .9 .2 .1],'String','Time|Frequency|50Hz|Spect');
  set(modehdl,'value',1);
end
colormap trafficlight; % red-green colormap for 50Hz pow

% extract the lines so we can directly update them.
datlim=[inf -inf];
for hi=1:numel(hdls); set(hdls(hi),'nextplot','add'); end; % all plots hold on.  Needed for OCTAVE
for hi=1:size(ppdat,1); 
  cldhdls = get(hdls(hi),'children');
  img_hdls(hi)=findobj(cldhdls,'type','image');%set(line_hdls(hi),'linewidth',1);
  %img_hdls(hi)=line(hdls(hi),'xdata',[1 1],'ydata',[1 1],'cdata',1,'CDataMapping','scaled','parent',hdls(hi),'visible','off');
  line_hdls(hi)=line([1 1],[1 1],'parent',hdls(hi),'visible','on','linewidth',1);
  set(hdls(hi),'ydir','normal'); % undo the dir reset by image
  % set the drawing oder so the title is always on top
  if ( ~exist('OCTAVE_VERSION','builtin') ) % in octave have to manually convert arrays..  
    set(hdls(hi),'children',[get(hdls(hi),'title');get(hdls(hi),'children')]);
  end
  datlimi=get(hdls(hi),'ylim');datlim(1)=min(datlim(1),datlimi(1)); datlim(2)=max(datlim(2),datlimi(2));
end;


endTraining=false; state=[];
cursamp=hdr.nSamples;
while ( ~endTraining )  
  % wait for new data to be available
  status=buffer('wait_dat',[cursamp+update_samp inf opts.timeOut_ms],buffhost,buffport);
  if( status.nSamples < cursamp+update_samp )
    fprintf('Buffer stall detected...\n');
    pause(1);
    cursamp=status.nSamples;
    if ( ~ishandle(fig) ) break; else continue; end;
  elseif ( status.nSamples > cursamp+update_samp*2 ) % missed a whole update window
    cursamp=status.nSamples - update_samp-1; % jump to the current time
  end;
  dat   =buffer('get_dat',[cursamp+1 cursamp+update_samp],buffhost,buffport);
  cursamp = cursamp+update_samp;
  
  if ( opts.verb>0 ) fprintf('.'); end;
  if ( ~ishandle(fig) ) break; end;
  
  % shift and insert into the data buffer
  rawdat(:,1:blkIdx)=rawdat(:,update_samp+1:end);
  rawdat(:,blkIdx+1:end)=dat.buf(iseeg,:);
  
  % pre-process the data
  ppdat = rawdat;
  if ( opts.detrend ) ppdat=detrend(ppdat,2); end;
  if ( ~isempty(opts.spatfilt) ) 
    if ( strcmpi(opts.spatfilt,'car') ) ppdat=repop(ppdat,'-',mean(ppdat,1)); end
  end

  % switch visualization mode if wanted
  key=[]; if ( ~isempty(modehdl) ) key=get(modehdl,'value'); end;
  if ( ~isempty(get(fig,'userdata')) ) key=get(fig,'userdata'); end; % key-overrides drop-down
  if ( ~isempty(key) )
    switch ( key );
     case {1,'t'}; tmp=1;curvistype='time';
     case {2,'f'}; tmp=2;curvistype='freq';
     case {3,'p'}; tmp=3;curvistype='power';
     case {4,'s'}; tmp=4;curvistype='spect';
     case 'q'; break;
    end;
    set(fig,'userdata',[]);
    if ( ~isempty(modehdl) ) set(modehdl,'value',tmp); end;
  end
  switch (curvistype) 
    
   case 'time'; % time-domain, spectral filter
    if ( ~isempty(filt) )      ppdat=fftfilter(ppdat,filt,outsz,2);  % N.B. downsample at same time
    elseif ( ~isempty(outsz) ) ppdat=subsample(ppdat,outsz(2),2); % manual downsample
    end
    
   case 'freq'; % freq-domain
    ppdat = welchpsd(ppdat,2,'width_ms',opts.welch_width_ms,'fs',hdr.fsample,'aveType','db');
    ppdat = ppdat(:,freqIdx(1):freqIdx(2));
    
   case 'power'; % 50Hz power, N.B. on the last 2s data only!
    ppdat = welchpsd(ppdat(:,find(times>-2,1):end),2,'width_ms',opts.welch_width_ms,'fs',hdr.fsample,'aveType','db');
    ppdat = mean(ppdat(:,freqIdx(1):freqIdx(2)),2); % ave power in this range
    
   case 'spect'; % spectrogram
    ppdat = spectrogram(ppdat,2,'width_ms',opts.welch_width_ms,'fs',hdr.fsample);
    ppdat = ppdat(:,freqIdx(1):freqIdx(2),:);    
    
  end
  
  datrange=[min(ppdat(:)),max(ppdat(:))];
  if ( ~isequal(vistype,curvistype) ) % reset the axes
    datlim=datrange;
    if ( datlim(1)>=datlim(2) || any(isnan(datlim)) ) datlim=[-1 1]; end;
    set(hdls,'ylim',datlim);
    switch ( vistype ) % do pre-work dependent on current mode
     case 'power'; % 50hz power
      for hi=1:size(ppdat,1); % turn the tickmarks and label visible again
        if ( ~isempty(get(hdls(hi),'Xlabel')) && isequal(get(get(hdls(hi),'xlabel'),'visible'),'on') ) 
          set(hdls(hi),'xticklabelmode','auto','yticklabelmode','auto');
        end
        xlabel(hdls(hi),'time (s)');
        ylabel('');
      end        
      if ( ~isempty(cbarhdl) ) set(findobj(cbarhdl),'visible','off'); end
     case 'spect'; if ( ~isempty(cbarhdl) ) set(findobj(cbarhdl),'visible','off'); end
    end
    switch ( curvistype ) 
      
     case 'time'; % time-domain
      for hi=1:size(ppdat,1);
        xlabel(hdls(hi),'time (s)');
        ylabel(hdls(hi),'');
        set(hdls(hi),'xlim',[times(1) times(size(ppdat,2))]);            
      end
      set(img_hdls,'visible','off'); % make the colors invisible        
      set(line_hdls,'xdata',times(1:size(ppdat,2)),'visible','on');
      
     case 'freq'; % frequency domain
      for hi=1:size(ppdat,1);
        xlabel(hdls(hi),'freq(hz)');
        ylabel(hdls(hi),'');
        set(hdls(hi),'xlim',freqs([freqIdx(1) freqIdx(2)]));
      end
      set(img_hdls,'visible','off'); % make the colors invisible        
      set(line_hdls,'xdata',freqs(freqIdx(1):freqIdx(2)),'visible','on');
      
     case 'power'; % 50Hz Power
                   % all the same axes
      datlim=[opts.noiseBins(1) opts.noiseBins(end)];
      set(hdls,'xlim',[.5 1.5],'ylim',[.5 1.5],'clim',datlim);
      set(line_hdls,'visible','off');
      set(img_hdls,'cdata',1,'xdata',[1 1],'ydata',[1 1],'visible','on'); % make the color images visible
      for hi=1:size(ppdat,1); % make the tickmarks and axes label invisible
        if ( ~isempty(get(hdls(hi),'Xlabel')) && isequal(get(get(hdls(hi),'xlabel'),'visible'),'on') ) 
          set(hdls(hi),'xticklabel',[],'yticklabel',[]);
        end
        xlabel(hdls(hi),'50Hz Power');
        ylabel(hdls(hi),'');
      end
      if ( ~isempty(cbarhdl) ) 
        set(cbarhdl,'outerposition',cbarpos); % ARGH! octave moves the cbar if axes are changed!
        set(findobj(cbarhdl),'visible','on');
        set(get(cbarhdl,'children'),'ydata',datlim);set(cbarhdl,'ylim',datlim); 
      end;
      
     case 'spect'; % spectrogram
      set(hdls,'xlim',start_s([1 end]),'ylim',freqs([freqIdx(1) freqIdx(2)])); % all the same axes
      set(line_hdls,'visible','off');
      % make the color images visible, in the right place with the right axes positions
      set(img_hdls,'xdata',start_s([1 end]),'ydata',freqs([freqIdx(1) freqIdx(2)]),'visible','on');      
      for hi=1:numel(hdls); xlabel(hdls(hi),'time (s)'); ylabel(hdls(hi),'freq (hz)');end;
      datlim=[0 max(abs(ppdat(:)))];
      if ( ~isempty(cbarhdl) ) 
        set(findobj(cbarhdl),'visible','on'); 
        set(get(cbarhdl,'children'),'ydata',datlim);set(cbarhdl,'ylim',datlim); 
        set(cbarhdl,'outerposition',cbarpos); 
      end;
    
    end
    vistype=curvistype;
  else % adapt the axes to the data
    if ( ~isequal(curvistype,'power') )
      if ( datrange(1)<datlim(1)-diff(datlim)*.2 || datrange(1)>datlim(1)+diff(datlim)*.2 || ...
           datrange(2)>datlim(2)+diff(datlim)*.2 || datrange(2)<datlim(2)-diff(datlim)*.2 )
        if ( isequal(datrange,[0 0]) ) 
          %fprintf('Warning: Clims are equal -- reset to clim+/- .5');
          datrange=.5*[-1 1]; 
        elseif ( datrange(1)==datrange(2) ) 
          datrange=datrange(1)+.5*[-1 1];
        end;         
        if ( isequal(curvistype,'spect') ) % spectrogram, datalim is color range
          datlim=datrange; set(hdls(1:size(ppdat,1)),'clim',datlim);
          % update the colorbar info
          if ( ~isempty(cbarhdl) ) set(get(cbarhdl,'children'),'ydata',datlim);set(cbarhdl,'ylim',datlim); end;
        else % lines - datalim is y-range
          datlim=datrange; set(hdls(1:size(ppdat,1)),'ylim',datlim);
        end
      end
    end
  end
  
  % update the plot
  switch ( curvistype ) 
    
   case {'time','freq'}; % td/fd -- just update the line info
    for hi=1:size(ppdat,1);
      set(line_hdls(hi),'ydata',ppdat(hi,:));
    end
    
   case {'power','spect'}; % 50Hz/spectrogram -- change the color of the image
                           % map from raw power into the colormap we're using, not needed as we use the auto-scaling function
                           %ppdat=max(opts.noiseBins(1),min(ppdat,opts.noiseBins(end)))./(opts.noiseBins(end)-opts.noiseBins(1))*size(colormap,1);
    for hi=1:size(ppdat,1);
      set(img_hdls(hi),'cdata',shiftdim(ppdat(hi,:,:)));
    end
  end
  % if ( ~exist('OCTAVE_VERSION','builtin') ) % in octave have to manually convert arrays..
  %   set(fig,'userdata',[]); % hack to force redraw?
  % end
  drawnow;
end
return;
%-----------------------
function testCase();
% start the buffer proxy
% dataAcq/startSignalProxy
sigViewer();

