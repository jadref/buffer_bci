function [data,devents]=dataViewer(data,varargin);
% simple viewer for ERPs based on matching buffer events
%
% dataViewer(data,varargin)
%
% Options
%  hdr       - [struct] header file for this data to be viewed
%  detrend   - [bool] flag if we detrend the data                   (true)
%  freqbands - [4x1] range to filter the data in before visualizing the ERP ([])
%  downsample- [float] frequence to downsample to before plotting   (128)
%  spatfilt  - 'str' spatial filter to use                          ('car')
%               one-of: 'none','car','slap','whiten'
%  badchrm   - [bool] do we do bad channel removal?                 (false)
%  badchthresh-[float] number for std-deviations to be marked as bad (3)
%  capFile   - [str] cap file to use to position the electrodes     ([])
%  welch_width_ms - [float] width of window to use for spectral analysis  (500)
%  sigProcOptsGui -- [bool] show the GUI to set signal processing options (true) 
%  maxEvents - [int] maximume number of events to store             (inf)
%                >1 - moving window ERP
%                0<maxEvents<1 - exp decay moving average rate to use
%  closeFig  - [bool] do we close the figure when we finish         (1)

%if ( exist('OCTAVE_VERSION','builtin') ) debug_on_error(1); else dbstop if error; end;
opts=struct('hdr',[],'fs',[],'ch_names',[],'verb',1,...
				'nSymbols',0,'maxEvents',[],'dataStd',3,...
				'trlen_ms',10000,'trlen_samp',[],'offset_ms',[],'offset_samp',[],...
				'detrend',1,'fftfilter',[],'freqbands',[],'downsample',128,'spatfilt','car',...
            'adaptspatialfiltFn','','whiten',0,'rmartch',0,'artCh',{{'EOG' 'AFz' 'EMG' 'AF3' 'FP1' 'FPz' 'FP2' 'AF4' '1'}},'rmemg',0,...
            'useradaptspatfiltFn','','adapthalflife_s',30,...
				'badchrm',0,'badchthresh',3,'badtrthresh',3,...
				'capFile',[],'overridechnms',0,...
				'welch_width_ms',1000,'spect_width_ms',500,'spectBaseline',1,...
				'redraw_ms',250,'lineWidth',1,'sigProcOptsGui',1,...
				'incrementalDraw',1,'closeFig',0);
[opts,varargin]=parseOpts(opts,varargin);
if ( isempty(opts.freqbands) && ~isempty(opts.fftfilter) ) opts.freqbands=opts.fftfilter; end;
wb=which('buffer'); if ( isempty(wb) || isempty(strfind('dataAcq',wb)) ); run(fullfile(fileparts(mfilename('fullpath')),'../utilities/initPaths.m')); end;
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
hdr=opts.hdr;

if ( nargin<1 ) data=[]; end;

% to auto set the color of the lines
linecols='brkgcmyk';


                           % get the data into a [ch x time (x epochs) ] format
if ( isempty(data) ) % ask for a file to open
  [fn,data]=uigetfile('header','Pick ftoffline raw savefile header file.'); drawnow;
end
if ( isstruct(data) ) % assume data.buf format
  if( isfield(data,'buf') ) data = cat(3,data.buf)
  else fprintf('expected data.buf format!\n');
  end;
elseif( ischar(data) ) % assume file-name to load data from.
  datadir=data;
  if( exist(datadir,'dir') )
        ;
  elseif( exist(datadir,'file') )
    datadir=fileparts(datadir);
  end
  hdr = read_buffer_offline_header(fullfile(datadir,'header'));
  data= read_buffer_offline_data(fullfile(datadir,'samples'),hdr);  
end

                                % get channel info for plotting
if( ~isempty(hdr) )
  if( isfield(hdr,'channel_names') )
    ch_names=hdr.channel_names;
  elseif( isfield(hdr,'labels') )
    ch_names=hdr.labels;
  elseif( isfield(hdr,'label') )
    ch_names=hdr.label;
  end
end
if( ~isempty(opts.ch_names) ) ch_names=opts.ch_names; end;

ch_pos=[]; ch_pos3d=[]; iseeg=true(numel(ch_names),1);
% get capFile info for positions
capFile=opts.capFile; overridechnms=opts.overridechnms; 
if(isempty(opts.capFile)) 
  [fn,pth]=uigetfile(fullfile(fileparts(mfilename('fullpath')),'../../resources/caps/*.txt'),'Pick cap-file');
  drawnow;
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
    iseeg=true(numel(ch_names),1);
  end
end

if ( isfield(hdr,'fSample') );
  fs=hdr.fSample;
elseif( isfield(hdr,'fsample') )
  fs=hdr.fsample;
elseif( isfield(hdr,'Fs') )
  fs=hdr.Fs;
end;
if ( isempty(fs) ) fs=opts.fs; end;
trlen_samp=opts.trlen_samp;
if ( isempty(trlen_samp) && ~isempty(opts.trlen_ms) )
  trlen_samp=round(opts.trlen_ms*fs/1000);
  if( size(data,2)>trlen_samp*10 ) % BODGE: slice into bits...
    nep  = floor(size(data,2)/trlen_samp);
    fprintf('Cutting data into %d epochs of %gms\n',nep,opts.trlen_ms);
    data = reshape(data(:,1:nep*trlen_samp),[size(data,1),trlen_samp,nep]);
  end  
else
  trlen_samp = size(data,2); 
end;


times=(1:trlen_samp)./fs; % include the offset
freqs=0:1000/opts.welch_width_ms:fs/2;
if ( ~isempty(opts.freqbands) )
  freqIdx=getfreqIdx(freqs,opts.freqbands);
else
  opts.freqbands=[1 freqs(end)];
  freqIdx=[1 numel(freqs)];
end

% make the spectral filter
outsz=trlen_samp; outsz(2)=outsz(1);
filt=[]; if ( ~isempty(opts.freqbands)) filt=mkFilter(outsz(1)/2,opts.freqbands,fs/outsz(1));end
if(~isempty(opts.downsample)) % update the plotting info
  outsz(2)=min(outsz(2),floor(outsz(1)*opts.downsample/fs)); 
  times   =(1:outsz(2))./opts.downsample;
end;
isbadch  = false(sum(iseeg),1);

% pre-compute the SLAP spatial filter
slapfilt=[];
if ( ~isempty(ch_pos) )       
  slapfilt=sphericalSplineInterpolate(ch_pos3d(:,iseeg),ch_pos3d(:,iseeg),[],[],'slap');%pre-compute the SLAP filter we'll use
else
  warning('Cant compute SLAP without channel positions!'); 
end


% recording the ERP data
rawdat    = zeros(sum(iseeg),outsz(1));
ppdat     = zeros(sum(iseeg),outsz(2));
% and the spectrogram version
[ppspect,start_samp,spectFreqs]=spectrogram(rawdat,2,'width_ms',opts.spect_width_ms,'fs',fs);
spectFreqIdx =getfreqIdx(spectFreqs,opts.freqbands);
ppspect=ppspect(:,spectFreqIdx(1):spectFreqIdx(2),:); % subset to freq range of interest
start_s=-start_samp(end:-1:1)/fs;
% and the data summary statistics
                             % pre-compute the channel power properties
                             % track the covariance properties of the data
                             % N.B. total weight up to step n = 1-(adaptHL)^n
covDat= data;
                       % detrend and CAR to remove obvious external artifacts
covDat=repop(covDat,'-',mean(covDat,2)); covDat=repop(covDat,'-',mean(covDat,1));
chPow = covDat(:,:)*covDat(:,:)'./size(covDat,2)./size(covDat,3);
whtstate=[]; eogstate=[]; emgstate=[]; usersfstate=[];
isbadch   = false(sum(iseeg),1);

adaptHL   = opts.adapthalflife_s.*trlen_samp; % half-life for updating the adaptive filters
adaptAlpha= exp(log(.5)./adaptHL);


% make the figure window
fig=figure(1);clf;
set(fig,'Name','Data Viewer : t=time, f=freq, s=spect, p=power, <=back >=forward q,close window=quit','menubar','none','toolbar','none','doublebuffer','on');
plotPos=ch_pos; if ( ~isempty(plotPos) ) plotPos=plotPos(:,iseeg); end;
% add number prefix to ch-names for display
plot_nms={}; for ci=1:numel(ch_names); plot_nms{ci} = sprintf('%d %s',ci,ch_names{ci}); end;plot_nms=plot_nms(iseeg);
hdls=image3d(ppspect,1,'plotPos',plotPos,'Xvals',plot_nms,'yvals',spectFreqs(spectFreqIdx(1):spectFreqIdx(2)),'ylabel','freq (hz)','zvals',start_s,'zlabel','time (s)','disptype','imaget','colorbar',1,'ticklabs','sw','legend',0,'plotPosOpts.plotsposition',[.05 .08 .91 .85]);
cbarhdl=[]; 
if ( strcmpi(get(hdls(end),'Tag'),'colorbar') ) 
  cbarhdl=hdls(end); hdls(end)=[]; cbarpos=get(cbarhdl,'position');
  set(findobj(cbarhdl),'visible','off'); % store and make invisible
end;


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
for hi=1:numel(hdls); 
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
axes('position',[0.25 .9 .5 .1],'units','normalized','visible','off','box','off','xlim',[-1 1],'ylim',[-1 1]);
titlehdl=text(0,0,sprintf('%d t=%10.1f s',0,0),'horizontalalignment','center','verticalalignment','bottom');

% make popup menu for selection of TD/FD
% make popup menu for selection of TD/FD
modehdl=[]; vistype=0; curvistype='time';
try
   modehdl=uicontrol(fig,'Style','popup','units','normalized','position',[.01 .9 .2 .1],'String','Time|Frequency|Spect|Power|Offset');
  set(modehdl,'value',1);
catch
end
colormap trafficlight; % red-green colormap for 50Hz pow
pos=get(modehdl,'position');
bwdhdl=uicontrol(fig,'Style','togglebutton','units','normalized','position',[pos(1)+pos(3)     pos(2)+pos(4)*.4 .05 pos(4)*.6],'String','<');
fwdhdl=uicontrol(fig,'Style','togglebutton','units','normalized','position',[pos(1)+pos(3)+.05 pos(2)+pos(4)*.4 .05 pos(4)*.6],'String','>');
vistype=1; ylabel='time (s)';  yvals=times; set(modehdl,'value',vistype);

% install listener for key-press mode change
set(fig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
set(fig,'userdata',[]);
drawnow; % make sure the figure is visible

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

curvistype=vistype;
endTraining=false;
nepoch = 1; deltaEpoch=0;
rawdat = data(iseeg,:,1);
tic;
while ( ~endTraining )

  deltaEpoch=0;
  updateLines=false; % reset what needs to be re-drawn

  % wait for key presses
  
  if ( ~ishandle(fig) ) break; end;
  % Now do MATLAB gui events
  modekey=[]; if ( ~isempty(modehdl) ) modekey=get(modehdl,'value'); end;
  if ( ~isempty(get(fig,'userdata')) ) modekey=get(fig,'userdata'); end; % modekey-overrides drop-down
  if ( ~isempty(modekey) )
    switch ( modekey(1) );
     case {1,'t'}; modekey=1;curvistype='time';
     case {2,'f'}; modekey=2;curvistype='freq';
     case {3,'s'}; modekey=3;curvistype='spect';
	  case {4,'p'}; modekey=4;curvistype='power';
	  case {5,'o'}; modekey=5;curvistype='offset';
     case {'<',','};   deltaEpoch=-1; modekey=[];
     case {'>','.'};   deltaEpoch= 1; modekey=[];
       case {'m' };    deltaEpoch=-10; modekey=[];
         case {'/'};   deltaEpoch=+10; modekey=[];
     case {'x','q'};     break;
     otherwise;    modekey=1;
    end;
    set(fig,'userdata',[]);
    if ( ~isempty(modehdl) && ~isempty(modekey) );
      set(modehdl,'value',modekey);
    end;
  end
  if( get(fwdhdl,'value')>0 ) deltaEpoch = +1; set(fwdhdl,'value',0); end;
  if( get(bwdhdl,'value')>0 ) deltaEpoch = -1; set(bwdhdl,'value',0); end;
  % get updated sig-proc parameters if needed
  if ( ~isempty(optsFigh) && ishandle(optsFigh) )
	 try
		[ppopts,damage]=getSigProcOpts(optsFigh,ppopts);
	 catch;
	 end;
    if ( any(damage) ) % re-draw all
      fprintf('Redraw all detected\n');
      updateLines(1)=true; updateLines(:)=true; 
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

                                % get the next data-segment
  if( deltaEpoch ~=0 )
    nepoch = min(size(data,3),max(1,nepoch+deltaEpoch));
    rawdat = data(iseeg,:,nepoch);
    set(titlehdl,'string',sprintf('%d t=%10.1f s',nepoch,nepoch*size(data,2)./fs));
    updateLines(:) = true;
    damage(4)      = true;
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
    ppdat = welchpsd(ppdat,2,'width_ms',opts.welch_width_ms,'fs',fs,'aveType','db');
    ppdat = ppdat(:,freqIdx(1):freqIdx(2)); % select the target frequencies

   case 'power'; % power in the passed range  -----------------------------------
    ppdat = welchpsd(ppdat,2,'width_ms',opts.welch_width_ms,'fs',fs,'aveType','amp');
    ppdat = ppdat(:,freqIdx(1):freqIdx(2)); % select the target frequencies
	 ppdat = sum(ppdat,2)/size(ppdat,2); % average over all the frequencies

   case '50hz'; % 50Hz power, N.B. on the last 2s data only!  -----------------------------------
    ppdat = welchpsd(ppdat(:,find(times>-2,1):end),2,'width_ms',opts.welch_width_ms,'fs',fs,'detrend',1,'aveType','amp');
    ppdat = sum(ppdat(:,noiseIdx(1):noiseIdx(2)),2)./max(1,(noiseIdx(2)-noiseIdx(1))); % ave power in this range
    ppdat = 20*log(max(ppdat,1e-12)); % convert to db

   case 'noisefrac'; % 50Hz power / total power, last 2s only ---------------------------------------
    ppdat = welchpsd(ppdat(:,find(times>-2,1):end),2,'width_ms',opts.welch_width_ms,'fs',fs,'detrend',1,'aveType','amp');
    ppdat = sum(ppdat(:,noiseIdx(1):noiseIdx(2)),2)./sum(ppdat,2); % fractional power in 50hz band
    
   case 'spect'; % spectrogram  -----------------------------------
    ppdat = spectrogram(ppdat,2,'width_ms',opts.spect_width_ms,'fs',fs);
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
        axes(hdls(hi));
        ylabel('');
        if ( ~isempty(get(hdls(hi),'Xlabel')) && isequal(get(get(hdls(hi),'xlabel'),'visible'),'on') ) 
          set(hdls(hi),'xticklabelmode','auto','yticklabelmode','auto');
          xlabel('time (s)','visible','on');
        else
          xlabel('time (s)','visible','off');
        end
      end        
      if ( ~isempty(cbarhdl) ); set(findobj(cbarhdl),'visible','off'); end

     case 'spect'; if ( ~isempty(cbarhdl) ); set(findobj(cbarhdl),'visible','off'); end
    end
    
    % compute the current vis-types plot
    switch ( curvistype )       

     case 'time'; % time-domain -----------------------------------
      for hi=1:numel(hdls);
        set(hdls(hi),'xlim',[times(1) times(size(ppdat,2))],'ylim',datlim);
        xlabel('time (s)');
        ylabel('');
      end
      set(img_hdls,'visible','off'); % make the colors invisible        
      set(line_hdls,'xdata',times(1:size(ppdat,2)),'visible','on');
      
     case 'freq'; % frequency domain -----------------------------------
      for hi=1:numel(hdls);
        set(hdls(hi),'xlim',freqs([freqIdx(1) freqIdx(2)]),'ylim',datlim);
        xlabel('freq (hz)');
        ylabel('');        
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
      for hi=1:numel(hdls); % make the tickmarks and axes label invisible
        axes(hdls(hi));
        if ( ~isempty(get(hdls(hi),'Xlabel')) && isequal(get(get(hdls(hi),'xlabel'),'visible'),'on') ) 
          set(hdls(hi),'xticklabel',[],'yticklabel',[]);
        end
        switch curvistype;
			 case '50hz';   xlabel('50Hz Power');
			 case 'noisefrac';xlabel('Noise Fraction');
			 case 'power';  xlabel('Signal Amplitude');
			 case 'offset'; xlabel('offset');
		  end
        ylabel('');
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
      for hi=1:numel(hdls);
        axes(hdls(hi));
        try;
            xlabel('time (s)');
            ylabel('freq (hz)');
        catch;
        end;
      end;
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
    ppdat = welchpsd(ppdat,2,'width_ms',opts.welch_width_ms,'fs',fs,'aveType','db');
    ppdat = ppdat(:,freqIdx(1):freqIdx(2)); % select the target frequencies

   case 'power'; % power in the passed range  -----------------------------------
    ppdat = welchpsd(ppdat,2,'width_ms',opts.welch_width_ms,'fs',fs,'aveType','amp');
    ppdat = ppdat(:,freqIdx(1):freqIdx(2)); % select the target frequencies
	 ppdat = sum(ppdat,2)/size(ppdat,2); % average over all the frequencies

   case '50hz'; % 50Hz power, N.B. on the last 2s data only!  -----------------------------------
    ppdat = welchpsd(ppdat(:,find(times>-2,1):end),2,'width_ms',opts.welch_width_ms,'fs',fs,'detrend',1,'aveType','amp');
    ppdat = sum(ppdat(:,noiseIdx(1):noiseIdx(2)),2)./max(1,(noiseIdx(2)-noiseIdx(1))); % ave power in this range
    ppdat = 20*log(max(ppdat,1e-12)); % convert to db

   case 'noisefrac'; % 50Hz power / total power, last 2s only ---------------------------------------
    ppdat = welchpsd(ppdat(:,find(times>-2,1):end),2,'width_ms',opts.welch_width_ms,'fs',fs,'detrend',1,'aveType','amp');
    ppdat = sum(ppdat(:,noiseIdx(1):noiseIdx(2)),2)./sum(ppdat,2); % fractional power in 50hz band
    
   case 'spect'; % spectrogram  -----------------------------------
    ppdat = spectrogram(ppdat,2,'width_ms',opts.spect_width_ms,'fs',fs);
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
        axes(hdls(hi));
        ylabel('');
        if ( ~isempty(get(hdls(hi),'Xlabel')) && isequal(get(get(hdls(hi),'xlabel'),'visible'),'on') ) 
          set(hdls(hi),'xticklabelmode','auto','yticklabelmode','auto');
          xlabel('time (s)');set(hdls(hi),'visible','on');
        else
          xlabel('time (s)');set(hdls(hi),'visible','off');
        end
      end        
      if ( ~isempty(cbarhdl) ); set(findobj(cbarhdl),'visible','off'); end

     case 'spect'; if ( ~isempty(cbarhdl) ); set(findobj(cbarhdl),'visible','off'); end
    end
    
    % compute the current vis-types plot
    switch ( curvistype )       

     case 'time'; % time-domain -----------------------------------
       for hi=1:size(ppdat,1);
         axes(hdls(hi));
        xlabel('time (s)');ylabel('');
        set(hdls(hi),'xlim',[times(1) times(size(ppdat,2))],'ylim',datlim);          end
      set(img_hdls,'visible','off'); % make the colors invisible        
      set(line_hdls,'xdata',times(1:size(ppdat,2)),'visible','on');
      
     case 'freq'; % frequency domain -----------------------------------
       for hi=1:size(ppdat,1);
         axes(hdls(hi));
        xlabel('freq (hz)');ylabel('');
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
        axes(hdls(hi));
        if ( ~isempty(get(hdls(hi),'Xlabel')) && isequal(get(get(hdls(hi),'xlabel'),'visible'),'on') ) 
          set(hdls(hi),'xticklabel',[],'yticklabel',[]);
        end
        switch curvistype;
			 case '50hz';   xlabel('50Hz Power');
			 case 'noisefrac';xlabel('Noise Fraction');
			 case 'power';  xlabel('Signal Amplitude');
			 case 'offset'; xlabel('offset');
		  end
        ylabel('');
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
      for hi=1:numel(hdls);
        axes(hdls(hi));try; xlabel('time (s)');ylabel('freq (hz)'); catch; end;
      end;
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
    vistype=curvistype;
    % redraw, but not too fast
    if ( toc < opts.redraw_ms/1000 ) continue; else pause(.005); tic; end;
  end
if ( opts.closeFig && ishandle(fig) ) close(fig); end;
% close the options figure as well
if ( exist('optsFigh') && ishandle(optsFigh) ) close(optsFigh); end;

if( nargout>0 ) 
  rawIds=rawIds(1:nTarget);
  rawEpochs=rawEpochs(:,:,1:nTarget);
end
return;

function freqIdx=getfreqIdx(freqs,freqbands)
if ( nargin<1 || isempty(freqbands) ) freqIdx=[1 numel(freqs)]; return; end;
[ans,freqIdx(1)]=min(abs(freqs-max(freqs(1),freqbands(1)))); 
[ans,freqIdx(2)]=min(abs(freqs-min(freqs(end),freqbands(end))));

%-----------------------
function testCase();
%Add necessary paths
run ../utilities/initPaths.m;

% start the buffer proxy
% dataAcq/startSignalProxy
erpViewer([],[],'cuePrefix','keyboard');

