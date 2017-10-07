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
%                oneof: 'none','car','whiten'
%              OR
%                [nCh x nCh] matrix giving directly the spatial filter coefficients
%  capFile    -- [str] capFile name to get the electrode positions from      ('1010')
%  overridechnms -- [bool] flag if we use the channel names from the capFile rather than the buffer (0)
%  welch_width_ms -- [single] size in time of the welch window                      (1000ms) 
%                      -> defines the frequency resolution for the frequency view of the data.   
%  spect_width_ms -- [single] size in time of the welch window for the spectrogram  (500ms) 
%                      -> defines the frequency resolution for the frequency view of the data.   
%  freqbands  -- [2x1] frequency bands to display in the freq-domain plot    (opts.fftfilter)
%  noisebands -- [2x1] frequency bands to display for the 50 Hz noise plot   ([45 47 53 55])
%  sigProcOptsGui -- [bool] show the on-line option changing gui             (1)
%  drawHead   -- [bool] flag if we should draw the background head           (true)
%  adapthalflife_s -- [1x1] or [4x1] exp-smoothing half-life in seconds for the adaptive filtering functions  (15)
%                      if 4 given then they are in order: [badchrm,whiten,artchrm,emgrm]
%  artChBands -- [4x1] band-pass filter specification as additional pre-processing for the artifact channel ([.5 1 45 48])
%                      removal code.
%                      
% TODO:
%   [] - pre-process the raw-data including non-eeg channels, but only
%   display eeg-channels..
wb=which('buffer'); 
if ( isempty(wb) || isempty(strfind('dataAcq',wb)) ); 
    fprintf('Running %s\n',fullfile(fileparts(mfilename('fullpath')),'../utilities/initPaths.m')); 
    run(fullfile(fileparts(mfilename('fullpath')),'../utilities/initPaths.m')); 
end;
opts=struct('endType','end.training','verb',1,'timeOut_ms',1000,...
				'trlen_ms',5000,'trlen_samp',[],'updateFreq',4,...
				'detrend',1,'fftfilter',[.1 .3 45 47],'freqbands',[],'downsample',[],'spatfilt','car',...
            'adapthalflife_s',15,...
            'adaptspatialfiltFn','','whiten',0,'rmemg',0,...
            'rmartch',0,'artChBands',[.5 1 45 48],...
                        'artCh',{{'EOG' 'AFz' 'EMG' 'AF3' 'FP1' 'FPz' 'FP2' 'AF4' '1'}},...
            'useradaptspatfiltFn','',...
				'badchrm',0,'badchthresh',3,'capFile',[],'overridechnms',0,...
				'welch_width_ms',1000,'spect_width_ms',500,'spectBaseline',1,...
				'noisebands',[45 47 53 55],'noiseBins',[],'noisefracBins',[.2 1],...%[0 1.75],...
				'sigProcOptsGui',1,'dataStd',2.5,'drawHead',1);
opts=parseOpts(opts,varargin);
if ( nargin<1 || isempty(buffhost) ); buffhost='localhost'; end;
if ( nargin<2 || isempty(buffport) ); buffport=1972; end;
if ( isempty(opts.freqbands) && ~isempty(opts.fftfilter) ); opts.freqbands=opts.fftfilter; end;

if ( exist('OCTAVE_VERSION','builtin') ) % use best octave specific graphics facility
  opts.sigProcOptsGui=0;
  if ( ~isempty(strmatch('qt',available_graphics_toolkits())) )
	 graphics_toolkit('qt'); 
	 opts.sigProcOptsGui=1;
  elseif ( ~isempty(strmatch('qthandles',available_graphics_toolkits())) )
    graphics_toolkit('qthandles'); % use fast rendering library
  elseif ( ~isempty(strmatch('fltk',available_graphics_toolkits())) )
    graphics_toolkit('fltk'); % use fast rendering library
  end
end
if ( ischar(buffport) ) buffport=atoi(buffport); end;
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
drawHead=opts.drawHead; if ( isempty(drawHead) ) drawHead=true; end;
% extract channel info from hdr
ch_names=hdr.channel_names; ch_pos=[]; ch_pos3d=[]; iseeg=true(numel(ch_names),1);
% get capFile info for positions
capFile=opts.capFile; overridechnms=opts.overridechnms; 
if(isempty(opts.capFile)) 
  [fn,pth]=uigetfile(fullfile(fileparts(mfilename('fullpath')),'../../resources/caps/*.txt'),'Pick cap-file'); drawnow;
  if ( isequal(fn,0) || isequal(pth,0) ) capFile='1010.txt';  % 1010 default if not selected
  else                                   capFile=fullfile(pth,fn);
  end; 
end
if ( ~isempty(capFile) ) 
  overridechnms=1; %default -- assume cap-file is mapping from wires->name+pos
  if ( ~isempty(strfind(capFile,'1010.txt')) || ~isempty(strfind(capFile,'subset')) ) 
     overridechnms=0; % capFile is just position-info / channel-subset selection
  end; 
  di = addPosInfo(ch_names,capFile,overridechnms,0,1); % get 3d-coords
  ch_pos=cat(2,di.extra.pos2d); % extract pos and channels names
  ch_pos3d=cat(2,di.extra.pos3d);
  ch_names=di.vals; 
  iseeg=[di.extra.iseeg];
  if ( ~any(iseeg) || ~isempty(strfind(capFile,'showAll.txt')) ) % fall back on showing all data
    warning('Capfile didnt match any data channels -- no EEG?');
    ch_names=hdr.channel_names;
    ch_pos=[];
	 drawHead=false;
    iseeg=true(numel(ch_names),1);
  end
end

if ( isfield(hdr,'fSample') ); fs=hdr.fSample; else fs=hdr.fsample; end;
trlen_samp=opts.trlen_samp;
if ( isempty(trlen_samp) && ~isempty(opts.trlen_ms) ); trlen_samp=round(opts.trlen_ms*fs/1000); end;
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
freqIdx =getfreqIdx(freqs,opts.freqbands);
noiseIdx=getfreqIdx(freqs,opts.noisebands);

% make the spectral filter
filt=[]; if ( ~isempty(opts.freqbands)); filt=mkFilter(trlen_samp/2,opts.freqbands,fs/trlen_samp);end
outsz=[trlen_samp trlen_samp];if(~isempty(opts.downsample)); outsz(2)=min(outsz(2),round(trlen_samp*opts.downsample/fs)); end;
  
% recording the ERP data
rawdat    = zeros(sum(iseeg),outsz(1));
ppdat     = zeros(sum(iseeg),outsz(2));
% and the spectrogram version
[ppspect,start_samp,spectFreqs]=spectrogram(rawdat,2,'width_ms',opts.spect_width_ms,'fs',hdr.fsample);
spectFreqIdx =getfreqIdx(spectFreqs,opts.freqbands);
ppspect=ppspect(:,spectFreqIdx(1):spectFreqIdx(2),:); % subset to freq range of interest
start_s=-start_samp(end:-1:1)/hdr.fsample;
% and the data summary statistics
chPow     = zeros(sum(iseeg),1);
adaptHL   = opts.adapthalflife_s.*opts.updateFreq; % half-life for updating the adaptive filters
adaptAlpha= exp(log(.5)./adaptHL);
whtstate=[]; eogstate=[]; emgstate=[]; usersfstate=[];
isbadch   = false(sum(iseeg),1);

% pre-compute the SLAP spatial filter
slapfilt=[];
if ( ~isempty(ch_pos) )       
  slapfilt=sphericalSplineInterpolate(ch_pos3d(:,iseeg),ch_pos3d(:,iseeg),[],[],'slap');%pre-compute the SLAP filter we'll use
else
  warning('Cant compute SLAP without channel positions!'); 
end
% check format of the useradapsfFn
if( ~isempty(opts.useradaptspatfiltFn) && ~iscell(opts.useradaptspatfiltFn) ) 
   opts.useradaptspatfiltFn={opts.useradaptspatfiltFn}; 
end

% make the figure window
fig=figure(1);clf;
set(fig,'Name','Sig-Viewer : t=Time, f=Freq, p=Power, 5=50Hz power, n=Noise Fraction, s=Spectrogram, o=Offset, close window=Exit','menubar','none','toolbar','none','doublebuffer','on');
axes('position',[0 0 1 1]);
if( drawHead ) topohead(); end;
set(gca,'visible','off','nextplot','add');
plotPos=ch_pos; if ( ~isempty(plotPos) ); plotPos=plotPos(:,iseeg); end;
% add number prefix to ch-names for display
plot_nms={}; for ci=1:numel(ch_names); plot_nms{ci} = sprintf('%d %s',ci,ch_names{ci}); end;plot_nms=plot_nms(iseeg);

hdls=image3d(ppspect,1,'plotPos',plotPos,'Xvals',plot_nms,'yvals',spectFreqs(spectFreqIdx(1):spectFreqIdx(2)),'ylabel','freq (hz)','zvals',start_s,'zlabel','time (s)','disptype','imaget','colorbar',1,'ticklabs','sw','legend',0,'plotPosOpts.plotsposition',[.05 .08 .91 .85]);
cbarhdl=[]; 
if ( strcmpi(get(hdls(end),'Tag'),'colorbar') ) 
  cbarhdl=hdls(end); hdls(end)=[]; cbarpos=get(cbarhdl,'position');
  set(findobj(cbarhdl),'visible','off'); % store and make invisible
end;

% install listener for key-press mode change
set(fig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
set(fig,'userdata',[]);
drawnow; % make sure the figure is visible

% make popup menu for selection of TD/FD
modehdl=[]; vistype=0; curvistype='time';
try
   modehdl=uicontrol(fig,'Style','popup','units','normalized','position',[.01 .9 .2 .1],'String','Time|Frequency|50Hz|Noisefrac|Spect|Power|Offset');
  set(modehdl,'value',1);
catch
end
colormap trafficlight; % red-green colormap for 50Hz pow

% extract the lines so we can directly update them.
datlim=[inf -inf];
for hi=1:numel(hdls); 
    set(hdls(hi),'nextplot','add'); % all plots hold on.  Needed for OCTAVE
    xhdl=get(hdls(hi),'xlabel');
    if( ~isempty(xhdl) && isempty(get(xhdl,'string')) )
        set(xhdl,'visible','off');
        yhdl=get(hdls(hi),'ylabel'); if(~isempty(yhdl))set(yhdl,'visible','off');end
    end
end; 
for hi=1:size(ppdat,1); 
  cldhdls = get(hdls(hi),'children');
  img_hdls(hi)=findobj(cldhdls,'type','image');%set(line_hdls(hi),'linewidth',1);
  %img_hdls(hi)=line(hdls(hi),'xdata',[1 1],'ydata',[1 1],'cdata',1,'CDataMapping','scaled','parent',hdls(hi),'visible','off');
  line_hdls(hi)=line([1 1],[1 1],'parent',hdls(hi),'visible','on','linewidth',1);
  set(hdls(hi),'ydir','normal'); % undo the dir reset by image
  % set the drawing oder so the title is always on top
  %if ( exist('OCTAVE_VERSION','builtin') ) % in octave have to manually convert arrays..  
  %  set(hdls(hi),'children',[get(hdls(hi),'title');get(hdls(hi),'children')]);
  %end
  datlimi=get(hdls(hi),'ylim');datlim(1)=min(datlim(1),datlimi(1)); datlim(2)=max(datlim(2),datlimi(2));
end;

ppopts.badchrm=opts.badchrm;
ppopts.badchthresh=opts.badchthresh;
if(opts.detrend); ppopts.detrend=1; end;
if ( ischar(opts.spatfilt) && ~isempty(opts.spatfilt) ) ppopts.(opts.spatfilt)=1; end;
if ( ischar(opts.adaptspatialfiltFn) && ~isempty(opts.adaptspatialfiltFn) ) 
   ppopts.(opts.adaptspatialfiltFn)=1; 
end;
ppopts.whiten =opts.whiten;
ppopts.rmartch=opts.rmartch;
ppopts.rmemg  =opts.rmemg;
ppopts.freqbands=opts.freqbands;
damage=false(5,1);
optsFigh=[];
if ( isequal(opts.sigProcOptsGui,1) )
  try;
    optsFigh=sigProcOptsFig();
  % set defaults to match input options  
  set(findobj(optsFigh,'tag','lowcutoff'),'string',sprintf('%g',ppopts.freqbands(1)));
  set(findobj(optsFigh,'tag','highcutoff'),'string',sprintf('%g',ppopts.freqbands(end)));  
  % set the graphics objects to match the inputs
  fn=fieldnames(ppopts);
  for fi=1:numel(fn);
    go=findobj(optsFigh,'tag',fn{fi});
    if(ishandle(go)) set(go,'value',ppopts.(fn{fi})); end;
  end
  ppopts=getSigProcOpts(optsFigh);

   % turn of the usersf option if no function name given in input options set
  if( isempty(opts.useradaptspatfiltFn) ) 
     set(findobj(optsFigh,'tag','usersf'),'visible','off'); 
  end;  
  catch;
  end
end

%oldPoint = get(fig,'currentpoint'); % initial mouse position
endTraining=false; state=[]; nUpdate=0;
status=buffer('wait_dat',[-1 -1 -1],buffhost,buffport); cursamp=status.nSamples;
while ( ~endTraining )  

  %------------------------------------------------------------------------
  % wait for new data, 
  % N.B. wait_data returns based on Number of samples, get_data uses sample index = #samples-1

  status=buffer('wait_dat',[cursamp+update_samp+1 inf opts.timeOut_ms],buffhost,buffport);
  if( status.nSamples < cursamp+update_samp )
    fprintf('Buffer stall detected...\n');
    pause(1);
    cursamp=status.nSamples;
    if ( ~ishandle(fig) ); break; else continue; end;
  elseif ( status.nSamples > cursamp+5*fs) % missed a 5 seconds of data
	 fprintf('Warning: Cant keep up with the data!\n%d Dropped samples...\n',status.nSamples-update_samp-1-cursamp);
    cursamp=status.nSamples - update_samp-1; % jump to the current time
  end;
  dat    =buffer('get_dat',[cursamp cursamp+update_samp-1],buffhost,buffport);
  cursamp=cursamp+update_samp;
  nUpdate=nUpdate+1;
  
  % shift and insert into the data buffer
  rawdat(:,  1      : blkIdx) =rawdat(:,update_samp+1:end);
  rawdat(:,blkIdx+1 : end)    =dat.buf(iseeg,:);

  %if ( cursamp-hdr.nSamples > hdr.fSample*30 ) keyboard; end;
  if ( opts.verb>0 ); fprintf('.'); end;
  if ( ~ishandle(fig) ); break; end;

  %------------------------------------------------------------------------
  % Get updated user input
  % switch visualization mode if wanted
  modekey=[]; if ( ~isempty(modehdl) ); modekey=get(modehdl,'value'); end;
  if ( ~isempty(get(fig,'userdata')) ); modekey=get(fig,'userdata'); end; % key-overrides drop-down
  if ( ~isempty(modekey) )
    switch ( modekey(1) );
     case {1,'t'}; modekey=1;curvistype='time';
     case {2,'f'}; modekey=2;curvistype='freq';
     case {3,'5'}; modekey=3;curvistype='50hz';
     case {4,'n'}; modekey=4;curvistype='noisefrac';          
     case {5,'s'}; modekey=5;curvistype='spect';
	  case {6,'p'}; modekey=6;curvistype='power';
	  case {7,'o'}; modekey=7;curvistype='offset';
     case {'x','q'};     break;
     otherwise;    modekey=1;
    end;
    set(fig,'userdata',[]);
    if ( ~isempty(modehdl) ); set(modehdl,'value',modekey); end;
  end
  % process mouse clicks
  %if ( ~isequal(get(fig,'currentpoint'),oldPoint) )
%	  oldPoint = get(fig,'currentpoint');
%	  fprintf('Click at [%d,%d]',oldPoint);
%	  % find any axes we are within
%	  for hi=1:numel(hdls);
%		 apos=get(hdls(hi),'position')
%	  end
%  end

  % get updated sig-proc parameters if needed
  if ( ~isempty(optsFigh) && ishandle(optsFigh) )
	 try
		[ppopts,damage]=getSigProcOpts(optsFigh,ppopts);
	 catch;
	 end;
    % compute updated spectral filter information, if needed
    if ( damage(4) ) % freq range changed
      filt=[];
      if ( ~isempty(ppopts.freqbands) ) % filter bands given
        filt=mkFilter(trlen_samp/2,ppopts.freqbands,fs/trlen_samp); 
      end
      freqIdx =getfreqIdx(freqs,ppopts.freqbands);
		spectFreqIdx=getfreqIdx(spectFreqs,ppopts.freqbands);
    end
  end

  %------------------------------------------------------------------------
  % pre-process the data
  ppdat = rawdat;
  if ( ~any(strcmpi(curvistype,{'offset'})) ) % no detrend for offset comp
	 if( (isfield(ppopts,'center') && ppopts.center)  ) 
            ppdat=repop(ppdat,'-',mean(ppdat,2)); 
    end;
    if( (isfield(ppopts,'detrend') && ppopts.detrend) ) 
        ppdat=detrend(ppdat,2); 
    end;
  end
  
  % track the covariance properties of the data
  % N.B. total weight up to step n = 1-(adaptHL)^n
  covDat= rawdat(:,blkIdx+1:end); 
  % detrend and CAR to remove obvious external artifacts
  covDat=repop(covDat,'-',mean(covDat,2)); covDat=repop(covDat,'-',mean(covDat,1));
  chPow = (adaptAlpha(min(end,1)))*chPow    +     (1-adaptAlpha(min(end,1)))*sum(covDat.*covDat,2)./(size(covDat,2));
  
  %-------------------------------------------------------------------------------------
  % bad-channel removal + spatial filtering
  % BODGE: 50Hz power doesn't do any spatial filtering, or bad-channel removal
  if ( ~any(strcmpi(curvistype,{'50hz','offset','noisefrac'})) ) 

    % bad channel removal
    oisbadch=isbadch;
    if ( ( ppopts.badchrm>0 || strcmp(ppopts.badchrm,'1') ) && ppopts.badchthresh>0 )
       if ( opts.verb > 1 )
          fprintf('%s < %g  %g\n',sprintf('%g ',chPow),mean(chPow)+ppopts.badchthresh*std(chPow),ppopts.badchthresh);
       end
      isbadch(:)=false; % start no-channels are bad
      for i=1:3;
        isbadch = chPow>(mean(chPow(~isbadch))+ppopts.badchthresh*std(chPow(~isbadch))) | chPow<eps;
      end
      ppdat(isbadch,:)=0; % zero out the bad channels
    else
       isbadch(:)=false; % bad-ch-rm turned off=> all channels are good
    end
    
    % give feedback on which channels are marked as bad
    for hi=find(oisbadch(:)~=isbadch(:))';
       th=[];
       try;
          th = get(hdls(hi),'title');
       catch; 
       end
       if ( ~isempty(th) ) 
          tstr=get(th,'string'); 
          if(isbadch(hi))
             if ( ~strcmpi(tstr(max(end-5,1):end),' (bad)')) set(th,'string',[tstr ' (bad)']); end
          elseif ( ~isbadch(hi) )
             if (strcmpi(tstr(max(end-5,1):end),' (bad)'));  set(th,'string',tstr(1:end-6)); end;
          end
       end
    end
    
    % spatial filter
    if( (isfield(ppopts,'car') && ppopts.car) ) 
		 if ( sum(~isbadch)>1 ) 
			ppdat(~isbadch,:,:)=repop(ppdat(~isbadch,:,:),'-',mean(ppdat(~isbadch,:,:),1));
		 end
    end
    if( (isfield(ppopts,'slap') && ppopts.slap) ) 
      if ( ~isempty(slapfilt) ) % only use and update from the good channels
        ppdat(~isbadch,:,:)=tprod(ppdat(~isbadch,:,:),[-1 2 3],slapfilt(~isbadch,~isbadch),[-1 1]); 
      end;
    end
	 if ( isnumeric(opts.spatfilt) ) % use the user-specified spatial filter matrix
		ppdat(~isbadch,:,:)=tprod(ppdat,[-1 2 3],opts.spatfilt,[-1 1]);      
	 end

                                % adaptive spatial filter
    ch_nameseeg=ch_names(iseeg); 
    ch_pos3deeg=[]; if (~isempty(ch_pos3d)) ch_pos3deeg=ch_pos3d(:,iseeg); end;
    if( isfield(ppopts,'whiten') && ppopts.whiten ) % symetric-whitener
      [ppdat,whtstate]=adaptWhitenFilt(ppdat,whtstate,'covFilt',adaptAlpha(min(end,2)),'ch_names',ch_nameseeg);
    else % clear state if turned off
      whtstate=[];
    end
    if( isfield(ppopts,'rmartch') && ppopts.rmartch ) % artifact channel regression
      % N.B. important for this regression to ensure only the pure artifact signal goes into the correlation hence
      %      set frequency bands to extract the artifact component of the signal
      [ppdat,eogstate]=artChRegress(ppdat,eogstate,[],opts.artCh,'covFilt',adaptAlpha(min(end,3)),'bands',opts.artChBands,'fs',fs,'ch_names',ch_nameseeg,'ch_pos',ch_pos3deeg);
    else
      eogstate=[];
    end
    if( isfield(ppopts,'rmemg') && ppopts.rmemg ) % artifact channel regression
      [ppdat,emgstate]=rmEMGFilt(ppdat,emgstate,[],'covFilt',adaptAlpha(min(end,4)),'ch_names',ch_nameseeg,'ch_pos',ch_pos3deeg);
    else
      emgstate=[];
    end    
    if( ~isempty(opts.useradaptspatfiltFn) && isfield(ppopts,'usersf') && ppopts.usersf ) % user specified option
      [ppdat,usersfstate]=feval(opts.useradaptspatfiltFn{1},ppdat,usersfstate,opts.useradaptspatfiltFn{2:end},'covFilt',adaptAlpha(min(end,5)),'ch_names',ch_nameseeg,'ch_pos',ch_pos3deeg);
    else
      usersfstate=[];
    end    

    
  end
  
  %-------------------------------------------------------------------------------------
  % Spectral filter and feature extraction
  switch (curvistype) 
    
   case 'time'; % time-domain, spectral filter -----------------------------------
    if ( ~isempty(filt) && ~all(abs(1-filt(1:end-1))<1e-6)); 
            ppdat=fftfilter(ppdat,filt,outsz,2);  % N.B. downsample at same time
    elseif ( ~isempty(outsz) && outsz(2)<size(ppdat,2) ); 
            ppdat=subsample(ppdat,outsz(2),2); % manual downsample
    end

   case 'offset'; % time-domain, spectral filter -----------------------------------
	  ppdat = mean(ppdat,2); % ave over time
	  ppdat = ppdat - mean(ppdat,1); % ave deviation to global average
    
   case 'freq'; % freq-domain  -----------------------------------
    ppdat = welchpsd(ppdat,2,'width_ms',opts.welch_width_ms,'fs',hdr.fsample,'aveType','db');
    ppdat = ppdat(:,freqIdx(1):freqIdx(2)); % select the target frequencies

   case 'power'; % power in the passed range  -----------------------------------
    ppdat = welchpsd(ppdat,2,'width_ms',opts.welch_width_ms,'fs',hdr.fsample,'aveType','amp');
    ppdat = ppdat(:,freqIdx(1):freqIdx(2)); % select the target frequencies
	 ppdat = sum(ppdat,2)/size(ppdat,2); % average over all the frequencies

   case '50hz'; % 50Hz power, N.B. on the last 2s data only!  -----------------------------------
    ppdat = welchpsd(ppdat(:,find(times>-2,1):end),2,'width_ms',opts.welch_width_ms,'fs',hdr.fsample,'detrend',1,'aveType','amp');
    ppdat = sum(ppdat(:,noiseIdx(1):noiseIdx(2)),2)./max(1,(noiseIdx(2)-noiseIdx(1))); % ave power in this range
    ppdat = 20*log(max(ppdat,1e-12)); % convert to db

   case 'noisefrac'; % 50Hz power / total power, last 2s only ---------------------------------------
    ppdat = welchpsd(ppdat(:,find(times>-2,1):end),2,'width_ms',opts.welch_width_ms,'fs',hdr.fsample,'detrend',1,'aveType','amp');
    ppdat = sum(ppdat(:,noiseIdx(1):noiseIdx(2)),2)./sum(ppdat,2); % fractional power in 50hz band
    
   case 'spect'; % spectrogram  -----------------------------------
    ppdat = spectrogram(ppdat,2,'width_ms',opts.spect_width_ms,'fs',hdr.fsample);
    ppdat = ppdat(:,spectFreqIdx(1):spectFreqIdx(2),:);    
    % subtract the 'common-average' spectrum
    if ( opts.spectBaseline ); ppdat=repop(ppdat,'-',mean(mean(ppdat,3),1)); end

  end
  
  % compute useful range of data to show
  % add some artifact robustness, data-lim is mean+3std-dev
  datstats=[median(ppdat(:)) std(ppdat(:))]; % N.B. use median for outlier robustness
  datrange=[max(min(ppdat(:)),datstats(1)-opts.dataStd*datstats(2)) ...
            min(datstats(1)+opts.dataStd*datstats(2),max(ppdat(:)))];

  %---------------------------------------------------------------------------------
  % Do visualisation mode switching work
  if ( ~isequal(vistype,curvistype) || any(damage(4)) ) % reset the axes
    datlim=datrange;
    if ( datlim(1)>=datlim(2) || any(isnan(datlim)) ); datlim=[-1 1]; end;
    switch ( vistype ) % do pre-work dependent on current mode, i.e. mode we're switching from
     case {'50hz','power','offset','noisefrac'}; % topo-plot mode, single color per electrode
      for hi=1:size(ppdat,1); % turn the tickmarks and label visible again
        ylabel('');
        if ( ~isempty(get(hdls(hi),'Xlabel')) && isequal(get(get(hdls(hi),'xlabel'),'visible'),'on') ) 
          set(hdls(hi),'xticklabelmode','auto','yticklabelmode','auto');
          xlabel(hdls(hi),'time (s)','visible','on');
        else
          xlabel(hdls(hi),'time (s)','visible','off');
        end
      end        
      if ( ~isempty(cbarhdl) ); set(findobj(cbarhdl),'visible','off'); end

     case 'spect'; if ( ~isempty(cbarhdl) ); set(findobj(cbarhdl),'visible','off'); end
    end
    
    % compute the current vis-types plot
    switch ( curvistype )       

     case 'time'; % time-domain -----------------------------------
      for hi=1:size(ppdat,1);
        xlabel(hdls(hi),'time (s)');
        ylabel(hdls(hi),'');
        set(hdls(hi),'xlim',[times(1) times(size(ppdat,2))],'ylim',datlim);            
      end
      set(img_hdls,'visible','off'); % make the colors invisible        
      set(line_hdls,'xdata',times(1:size(ppdat,2)),'visible','on');
      
     case 'freq'; % frequency domain -----------------------------------
      for hi=1:size(ppdat,1);
        xlabel(hdls(hi),'freq(hz)');
        ylabel(hdls(hi),'');
        set(hdls(hi),'xlim',freqs([freqIdx(1) freqIdx(2)]),'ylim',datlim);
      end
      set(img_hdls,'visible','off'); % make the colors invisible        
      set(line_hdls,'xdata',freqs(freqIdx(1):freqIdx(2)),'visible','on');
      
     case {'50hz','power','offset','noisefrac'}; % 50Hz Power all the same axes -----------------------------------
       if ( strcmpi(curvistype,'50hz') && ~isempty(opts.noiseBins) ) % fix the color range for the 50hz power plots
         datlim=[opts.noiseBins(1) opts.noiseBins(end)];
       end;
       if ( strcmpi(curvistype,'noisefrac') && ~isempty(opts.noisefracBins) ) % fix the color range for the 50hz power plots
         datlim=[opts.noisefracBins(1) opts.noisefracBins(end)];
       end;
      set(hdls,'xlim',[.5 1.5],'ylim',[.5 1.5],'clim',datlim);
      set(line_hdls,'visible','off');
      set(img_hdls,'cdata',1,'xdata',[1 1],'ydata',[1 1],'visible','on'); %make the color images visible
      for hi=1:size(ppdat,1); % make the tickmarks and axes label invisible
        if ( ~isempty(get(hdls(hi),'Xlabel')) && isequal(get(get(hdls(hi),'xlabel'),'visible'),'on') ) 
          set(hdls(hi),'xticklabel',[],'yticklabel',[]);
        end
        switch curvistype;
			 case '50hz';   xlabel(hdls(hi),'50Hz Power');
			 case 'noisefrac';xlabel(hdls(hi),'Noise Fraction');
			 case 'power';  xlabel(hdls(hi),'Signal Amplitude');
			 case 'offset'; xlabel(hdls(hi),'offset');
		  end
        ylabel(hdls(hi),'');
      end
      if ( ~isempty(cbarhdl) ) 
        set(cbarhdl,'position',cbarpos); % ARGH! octave moves the cbar if axes are changed!
        set(findobj(cbarhdl),'visible','on');
        set(get(cbarhdl,'children'),'ydata',datlim);set(cbarhdl,'ylim',datlim); 
      end;
      
     case 'spect'; % spectrogram -----------------------------------
      set(hdls,'xlim',start_s([1 end]),...
			      'ylim',spectFreqs([spectFreqIdx(1) spectFreqIdx(2)]),...
			      'clim',datlim); % all the same axes
      set(line_hdls,'visible','off');
      % make the color images visible, in the right place with the right axes positions
      set(img_hdls,'xdata',start_s([1 end]),...
   			       'ydata',spectFreqs([spectFreqIdx(1) spectFreqIdx(2)]),...
			          'visible','on');      
      for hi=1:numel(hdls); xlabel(hdls(hi),'time (s)'); ylabel(hdls(hi),'freq (hz)');end;
      if ( ~isempty(cbarhdl) ) 
        set(cbarhdl,'position',cbarpos); % ARGH! octave moves the cbar if axes are changed!
        set(findobj(cbarhdl),'visible','on'); 
        set(get(cbarhdl,'children'),'ydata',datlim);set(cbarhdl,'ylim',datlim); 
      end;
    
    end

    vistype=curvistype;


  %---------------------------------------------------------------------------------
  % same visualizaton - update the axes limits (if needed)
  else % adapt the axes to the data
    if ( abs(datlim(1)-datrange(1))>.3*diff(datrange) ...
			|| abs(datlim(2)-datrange(2))>.3*diff(datrange) )
      if ( isequal(datrange,[0 0]) || all(isnan(datrange)) || all(isinf(datrange)) ) 
                 %fprintf('Warning: Clims are equal -- reset to clim+/- .5');
        datrange=.5*[-1 1]; 
      elseif ( datrange(1)==datrange(2) ) 
        datrange=datrange(1)+.5*[-1 1];
      elseif ( isnan(datrange(1)) || isinf(datrange(1)) )
		  datrange(1) = datrange(2)-1;
		elseif ( isnan(datrange(2)) || isinf(datrange(2)) )
		  datrange(2) = datrange(1)+1;
		end;         
      if ( strcmpi(curvistype,'50hz') && ~isempty(opts.noiseBins) ) % fix the color range for the 50hz power plots
         datrange=[opts.noiseBins(1) opts.noiseBins(end)];
      end;
      if ( strcmpi(curvistype,'noisefrac') && ~isempty(opts.noisefracBins) )% fix the color range for the 50hz power plots
         datrange=[opts.noisefracBins(1) opts.noisefracBins(end)];
      end;

		                          % spectrogram, power - datalim is color range
      if ( any(strcmpi(curvistype,{'spect','power','offset','50Hz','noisefrac'})) )
        datlim=datrange; set(hdls(1:size(ppdat,1)),'clim',datlim);
                                % update the colorbar info
        if ( ~isempty(cbarhdl) ); 
           set(get(cbarhdl,'children'),'ydata',datlim);
           set(cbarhdl,'ylim',datlim); 
        end;
      else % lines - datalim is y-range
        datlim=datrange; set(hdls(1:size(ppdat,1)),'ylim',datlim);
      end
    end
  end
  
  % update the plot
  switch ( curvistype ) 
    
   case {'time','freq'}; % td/fd -- just update the line info
    for hi=1:size(ppdat,1);
      set(line_hdls(hi),'ydata',ppdat(hi,:));
    end
    
   case {'50hz','spect','power','offset','noisefrac'}; % 50Hz/spectrogram -- update the image data
    % map from raw power into the colormap we're using, not needed as we use the auto-scaling function
    %ppdat=max(opts.noiseBins(1),min(ppdat,opts.noiseBins(end)))./(opts.noiseBins(end)-opts.noiseBins(1))*size(colormap,1);
    for hi=1:size(ppdat,1);
      set(img_hdls(hi),'cdata',shiftdim(ppdat(hi,:,:)));
    end
  end
  drawnow;
end
% close the options figure as well
if ( exist('optsFigh') && ishandle(optsFigh) ); close(optsFigh); end;
drawnow;
return;

function freqIdx=getfreqIdx(freqs,freqbands)
if ( nargin<1 || isempty(freqbands) ); freqIdx=[1 numel(freqs)]; return; end;
[ans,freqIdx(1)]=min(abs(freqs-max(freqs(1),freqbands(1)))); 
[ans,freqIdx(2)]=min(abs(freqs-min(freqs(end),freqbands(end))));

%-----------------------
function testCase();
% start the buffer proxy
% dataAcq/startSignalProxy
sigViewer();

% with user-specified adaptive filter function
sigViewer([],[],'useradaptspatfiltFn','adaptWhitenFilt'); 
sigViewer([],[],'useradaptspatfiltFn',{'xchRegress' 'xchInd',[-.5 .5]}); 
