function [data,devents]=erpViewer(buffhost,buffport,varargin);
% simple viewer for ERPs based on matching buffer events
%
% [data,events]=erpViewer(buffhost,buffport,varargin)
%
% Options
%  cuePrefix - 'str' event type to match for an ERP to be stored    ('stimulus')
%  endType   - 'str' event type to match to say stop recording ERPs ('end.training')
%               OR
%              {'type1' 'type2'} set of types any of which can match
%               OR
%              {{'type1' 'type2'} {'val'}} set of type,values both of which should match
%  trlen_ms/samp  - [int] length of data after to cue to record     (1000)
%  offset_ms/samp - [2x1] offset from [cue cue+trlen] to record data([]) 
%                    i.e. actual data is from [cue+offset(1) : cue+trlen+offset(2)]
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
opts=struct('cuePrefix','stimulus.target','endType','end.training','verb',1,...
				'nSymbols',0,'maxEvents',[],...
				'trlen_ms',1000,'trlen_samp',[],'offset_ms',[],'offset_samp',[],...
				'detrend',1,'fftfilter',[],'freqbands',[],'downsample',128,'spatfilt','car',...
            'adaptspatialfiltFn','','whiten',0,'rmartch',0,'artCh',{{'EOG' 'AFz' 'EMG' 'AF3' 'FP1' 'FPz' 'FP2' 'AF4' '1'}},'rmemg',0,...
            'useradaptspatfiltFn','','adapthalflife_s',30,...
				'badchrm',0,'badchthresh',3,'badtrthresh',3,...
				'capFile',[],'overridechnms',0,'welch_width_ms',500,...
				'redraw_ms',250,'lineWidth',1,'sigProcOptsGui',1,...
            'dataStd',2.5,...
				'incrementalDraw',1,'closeFig',0);
[opts,varargin]=parseOpts(opts,varargin);
if ( nargin<1 || isempty(buffhost) ) buffhost='localhost'; end;
if ( nargin<2 || isempty(buffport) ) buffport=1972; end;
if ( isempty(opts.freqbands) && ~isempty(opts.fftfilter) ) opts.freqbands=opts.fftfilter; end;
if ( ischar(opts.endType) ) opts.endType={opts.endType}; 
elseif ( iscell(opts.endType) && numel(opts.endType)>0 && ~iscell(opts.endType{1}) )
  opts.endType={opts.endType}; % ensure correct nesting so opts.endType{:} expands to type,value pair
end;
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
if ( ischar(buffport) ) buffport=atoi(buffport); end;
fprintf('Connection to buffer on %s : %d\n',buffhost,buffport);

% to auto set the color of the lines
linecols='brkgcmyk';

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
ch_names=hdr.channel_names; ch_pos=[]; ch_pos3d=[]; iseeg=true(numel(ch_names),1);
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

if ( isfield(hdr,'fSample') ); fs=hdr.fSample; else fs=hdr.fsample; end;
trlen_samp=opts.trlen_samp;
if ( isempty(trlen_samp) && ~isempty(opts.trlen_ms) ) trlen_samp=round(opts.trlen_ms*fs/1000); end;
offset_samp=opts.offset_samp;
if ( isempty(offset_samp) && ~isempty(opts.offset_ms) ) offset_samp=round(opts.offset_ms*fs/1000); end;
if ( isempty(offset_samp) ) offset_samp=[0 0]; end;
times=((1+offset_samp(1)):(trlen_samp+offset_samp(2)))./fs; % include the offset
freqs=0:1000/opts.welch_width_ms:fs/2;
if ( ~isempty(opts.freqbands) )
  freqIdx=getfreqIdx(freqs,opts.freqbands);
else
  opts.freqbands=[1 freqs(end)];
  freqIdx=[1 numel(freqs)];
end

% make the spectral filter
outsz=trlen_samp-offset_samp(1)+offset_samp(2); outsz(2)=outsz(1);
filt=[]; if ( ~isempty(opts.freqbands)) filt=mkFilter(outsz(1)/2,opts.freqbands,fs/outsz(1));end
if(~isempty(opts.downsample)) % update the plotting info
  outsz(2)=min(outsz(2),floor(outsz(1)*opts.downsample/fs)); 
  times   =(1:outsz(2))./opts.downsample + offset_samp(1)/fs;
end;

% recording the ERP data
maxEvents = opts.maxEvents;
key      = {};
label    = {};
nCls     = opts.nSymbols;
if ( ~isempty(maxEvents) && ~(isnan(maxEvents) || isinf(maxEvents)) )  
  rawEpochs= zeros(sum(iseeg),outsz(1),maxEvents); % stores the raw data
else                        
  rawEpochs= zeros(sum(iseeg),outsz(1),40); 
end
rawIds   = 0;
nTarget  = 0;
erp      = zeros(sum(iseeg),outsz(2),max(1,nCls)); % stores the pre-proc data used in the figures
adaptHL   = opts.adapthalflife_s./(times(end)-times(1)); % half-life for updating the adaptive filters
adaptAlpha= exp(log(.5)./adaptHL);
whtstate=[]; eogstate=[]; emgstate=[]; usersfstate=[];
isbadch  = false(sum(iseeg),1);

% pre-compute the SLAP spatial filter
slapfilt=[];
if ( ~isempty(ch_pos) )       
  slapfilt=sphericalSplineInterpolate(ch_pos3d(:,iseeg),ch_pos3d(:,iseeg),[],[],'slap');%pre-compute the SLAP filter we'll use
else
  warning('Cant compute SLAP without channel positions!'); 
end

% make the figure window
fig=figure(1);clf;
set(fig,'Name','ER(s)P Viewer : t=time, f=freq, r=rest, q,close window=quit','menubar','none','toolbar','none','doublebuffer','on');
plotPos=ch_pos; if ( ~isempty(plotPos) ) plotPos=plotPos(:,iseeg); end;
% add number prefix to ch-names for display
plot_nms={}; for ci=1:numel(ch_names); plot_nms{ci} = sprintf('%d %s',ci,ch_names{ci}); end;plot_nms=plot_nms(iseeg);
hdls=image3d(erp,1,'plotPos',plotPos,'Xvals',plot_nms,'Yvals',times,'ylabel','time (s)','disptype','plot','ticklabs','sw','legend','se','plotPosOpts.plotsposition',[.05 .08 .91 .85],'lineWidth',opts.lineWidth);

% make popup menu for selection of TD/FD
modehdl=uicontrol(fig,'Style','popup','units','normalized','position',[.8 .9 .2 .1],'String','Time|Frequency');
pos=get(modehdl,'position');
resethdl=uicontrol(fig,'Style','togglebutton','units','normalized','position',[pos(1)-.2 pos(2)+pos(4)*.4 .2 pos(4)*.6],'String','Reset');
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

% pre-call buffer_waitData to cache its options
endType=opts.endType;if(numel(opts.endType)>0 && iscell(opts.endType{1})) endType=opts.endType{1}; end
[datai,deventsi,state,waitDatopts]=buffer_waitData(buffhost,buffport,[],'startSet',{opts.cuePrefix},'trlen_samp',trlen_samp,'offset_samp',offset_samp,'exitSet',{opts.redraw_ms 'data' endType},'verb',opts.verb,varargin{:},'getOpts',1);

fprintf('Waiting for events of type: %s\n',opts.cuePrefix);

data={}; devents=[]; % for returning the data/events
curvistype=vistype;
endTraining=false;
tic;
while ( ~endTraining )

  updateLines=false(numel(key),1); % reset what needs to be re-drawn

  % wait for events...
  [datai,deventsi,state]=buffer_waitData(buffhost,buffport,state,waitDatopts);
  
  if ( ~ishandle(fig) ) break; end;
  % Now do MATLAB gui events
  modekey=[]; if ( ~isempty(modehdl) ) modekey=get(modehdl,'value'); end;
  if ( ~isempty(get(fig,'userdata')) ) modekey=get(fig,'userdata'); end; % modekey-overrides drop-down
  if ( ~isempty(modekey) )
    switch ( modekey(1) );
     case {1,'t'}; modekey=1;curvistype='time';
     case {2,'f'}; modekey=2;curvistype='freq';
     case {'r'};   modekey=1;resetval=true; set(resethdl,'value',resetval); % press the reset button
     case 'q'; break;
     otherwise;    modekey=1;
    end;
    set(fig,'userdata',[]);
    if ( ~isempty(modehdl) ); set(modehdl,'value',modekey); end;
  end
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

  resetval=get(resethdl,'value');
  if ( resetval ) 
    fprintf('reset detected\n');
    key={}; nTarget=0; rawIds=[]; devents=[];
    erp=zeros(sum(iseeg),numel(yvals),1);
    updateLines(1)=true; updateLines(:)=true; % everything must be re-drawn
    resetval=0;set(resethdl,'value',resetval); % pop the button back out
  end
  
  newClass   =false;
  keep=true(numel(deventsi),1);
  for ei=1:numel(deventsi);
      event=deventsi(ei);
      if( any(matchEvents(event,opts.endType{:})) )
        % end-training event
        keep(ei:end)=false;
        endTraining=true; % mark to finish
        fprintf('Discarding all subsequent events: exit\n');
        break;
      else
		  if ( opts.verb>0 ) fprintf('.'); end; % indicate we've updated
        val = event.value;      
        mi=[]; 
        if ( ~isempty(key) ) % match if we've seen this key before 
          for ki=1:numel(key) if ( isequal(val,key{ki}) ) mi=ki; break; end; end; 
        end;
        if ( isempty(mi) ) % new class to average
			 newClass   =true;
          key{end+1} =val;
          mi         =numel(key);
          erp(:,:,mi)=0;
          nCls       =mi;
        end;
        updateLines(mi)=true;
      
		  if ( nargout>0 ) % store the data to return like buffer_waitdata
			  if ( isempty(devents) ) 
				 data={datai(ei)};        devents=event;
			  else
				 data(end+1)={datai(ei)}; devents(end+1) = event;
			 end
		  end
		  
        % store the 'raw' data
		  nTarget=nTarget+1;
		  if ( isempty(maxEvents) || nTarget < maxEvents ) 
			 insertIdx=nTarget;  % insert at end
		  else                       
			 insertIdx=mod(nTarget,maxEvents)+1; % ring buffer
		  end
		  rawIds(insertIdx)=mi;
		  rawEpochs(:,:,insertIdx) = datai(ei).buf(iseeg,:);      
      end
    end


    %---------------------------------------------------------------------------------
    % Do visualisation mode switching work
    if ( ~isequal(curvistype,vistype) ) % all to be updated!
      fprintf('vis switch detected\n');
      updateLines(1)=true; updateLines(:)=true;
    end; 
    if ( all(updateLines) )
      switch( curvistype )
       case {1,'time'}; ylabel='time (s)';  yvals=times; 
       case {2,'freq'}; ylabel='freq (hz)'; yvals=freqs(freqIdx(1):freqIdx(2)); 
       otherwise; error('extra vistype');
      end    
      % reset stored ERP info
      erp=zeros(sum(iseeg),numel(yvals),max(1,numel(key)));
    end

    %---------------------------------------------------------------------------------
    % compute the updated ERPs (if any)
    if ( any(updateLines) )
      damagedLines=find(updateLines(1:numel(key)));      
      ppdat=rawEpochs;
      % common pre-processing which needs access to all the data
      % pre-process the data
      if( (isfield(ppopts,'center') && ppopts.center)  ) 
         ppdat=repop(ppdat,'-',mean(ppdat,2)); 
      end;
      if( (isfield(ppopts,'detrend') && ppopts.detrend) ) 
         ppdat=detrend(ppdat,2); 
      end;
        
      % bad-channel identify and remove
      if( ( ppopts.badchrm>0 || strcmp(ppopts.badchrm,'1') ) && ppopts.badchthresh>0 )
        oisbadch = isbadch;
        isbadch=idOutliers(rawEpochs,1,ppopts.badchthresh);
        % set the data in this channel to 0
        ppdat(isbadch,:)=0;
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
                 if ( ~strcmp(tstr(max(end-5,1):end),' (bad)')) set(th,'string',[tstr ' (bad)']); end
              elseif ( ~isbadch(hi) )
                 if (strcmp(tstr(max(end-5,1):end),' (bad)'));  set(th,'string',tstr(1:end-6)); end;
              end
           end
        end
        
        % bad-ch rm also implies bad trial
        isbadtr=idOutliers(ppdat,3,opts.badtrthresh);
        ppdat(:,:,isbadtr)=0;
      end

        % TODO: This can be more efficient.... as we run the full pre-processing on all the data every time it's updated.....
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
      
    %--------------------------------------
    % re-plot the updated lines
      for mi=damagedLines(:)';
        ppdatmi=ppdat(:,:,rawIds==mi);
        if ( isempty(ppdatmi) ) erp(:,:,mi)=0; continue; end;

        
        % compute the visualisation
        switch (curvistype) 
        
         case 'time'; % time-domain, spectral filter
          if ( ~isempty(filt) )      ppdatmi=fftfilter(ppdatmi,filt,outsz,2);  % N.B. downsample at same time
          elseif ( ~isempty(outsz) ) ppdatmi=subsample(ppdatmi,outsz(2),2);    % manual downsample
          end
        
         case 'freq'; % freq-domain
          ppdatmi = welchpsd(ppdatmi,2,'width_ms',opts.welch_width_ms,'fs',hdr.fsample,'aveType','amp');
          ppdatmi = ppdatmi(:,freqIdx(1):freqIdx(2),:);
        
         otherwise; error('Unrecognised visualisation type: ');
        end
		  
		  erpmi = sum(ppdatmi,3)./size(ppdatmi,3);		  
		  if ( size(erpmi,2)==size(erp,2) )
			 erp(:,:,mi) = erpmi; 
		  else % BODGE: this should never happen..... but check for size mis-matches and fix if found
			 if ( size(erpmi,2) < size(erp,2) ) % erpmi smaller: pad with last entry to get full size
				erp(:,1:size(erpmi,2),mi)=erpmi;
				erp(:,size(erpmi,2)+1:end,mi) =repmat(erpmi(:,end),1,size(erp,2)-size(erpmi,2)); 
			 elseif ( size(erpmi,2)>size(erp,2) ) % erp smaller: only use this much
				erp(:,:,mi) = erpmi(:,1:size(erp,2));
			 end			 
		  end
        if ( isnumeric(key{mi}) ) % line label -- including number of times seen
          label{mi}=sprintf('%g (%d)',key{mi},sum(rawIds(1:nTarget)==mi));
        else
          label{mi}=sprintf('%s (%d)',key{mi},sum(rawIds(1:nTarget)==mi));
        end		  
      end
    end
    %---------------------------------------------------------------------------------
    % Update the plot
	incrementalDraw = opts.incrementalDraw && isequal(vistype,curvistype);
	if ( exist('OCTAVE_VERSION','builtin') ) incrementalDraw = incrementalDraw & ~newClass ; end;
    if ( incrementalDraw ) % update the changed lines only
          % compute useful range of data to show, with some artifact robustness, data-lim is mean+3std-dev
          datstats=[mean(erp(:)) std(erp(:))];
          datrange=[max(min(erp(:)),datstats(1)-opts.dataStd*datstats(2)) ...
                    min(datstats(1)+opts.dataStd*datstats(2),max(erp(:)))];      
          % update each plot in turn
          for hi=1:size(erp,1);
             % update the plot
              xlim=get(hdls(hi),'xlim');
              if( xlim(1)~=yvals(1) || xlim(2)~=yvals(end) ) set(hdls(hi),'xlim',[yvals(1) yvals(end)]);end
              ylim=get(hdls(hi),'ylim');
              %if ( size(rawEpochs,3)>100 ) keyboard; end;
              if ( abs(ylim(1)-datrange(1))>.2*diff(datrange) || abs(ylim(2)-datrange(2))>.2*diff(datrange) )
                 if ( datrange(1)==datrange(2) ) datrange=datrange(1) + .5*[-1 1]; end;
                 set(hdls(hi),'ylim',datrange);
              end

              % update the lines
              line_hdls=findobj(get(hdls(hi),'children'),'type','line');
              linenames=get(line_hdls,'displayname'); % get names of all lines to find the one to update
		      for mi=find(updateLines(:))';
                  if ( mi<=numel(key) ) % if existing line, so update in-place
                    keymi=key{mi}; if ( isnumeric(keymi) ) keymi=sprintf('%g',keymi); end;
                    li = strmatch(keymi,linenames);
                    if ( isempty(li) ) 
                            li=find(strcmp('',linenames),1);
                            if ( isempty(li) ) li=strmatch('data',linenames); if(~isempty(li))li=li(1); end; end;
                            if ( isempty(li) ) li=find(strcmp(sprintf('%d',mi),linenames),1); end;
                    end
                  else % line without key, turn it off
                    if ( size(line_hdls,1)>=mi && ishandle(line_hdls(mi)) )
                      set(line_hdls(mi),'visible','off');
                      set(line_hdls(mi),'displayName','');
                    end;
                    continue;
                  end
				  if( size(line_hdls,1)>=mi && ~isempty(li) && ishandle(line_hdls(li)) && ~isequal(line_hdls(li),0) )
                 set(line_hdls(li),'xdata',yvals,'ydata',erp(hi,:,mi),'displayname',label{mi},'visible','on','color',linecols(mod(mi-1,numel(linecols))+1));
				  else % add a new line
                 set(hdls(hi),'nextplot','add');
                 line_hdls(mi)=plot(yvals,erp(hi,:,mi),'parent',hdls(hi),...
                                    'color',linecols(mod(mi-1,numel(linecols))+1),...
                                    'linewidth',opts.lineWidth,'displayname',label{mi});
                 set(hdls(hi),'nextplot','replace');
              end
			 end
		  end
		                          % update the legend
		  if ( numel(hdls)>size(erp,1) && ishandle(hdls(end)) && any(strcmp(get(hdls(end),'type'),{'axes','legend'})) ) % legend is a normal set of axes
           pos=get(hdls(end),'position');
           legend(hdls(end-1),'off'); hdls(end) = legend(hdls(end-1),'show'); set(hdls(end),'position',pos);
		  end
	else % redraw the whole from scratch
      hdls=image3d(erp,1,'handles',hdls,'Xvals',ch_names(iseeg),'Yvals',yvals,'ylabel',ylabel,'disptype','plot','ticklabs','sw','Zvals',label(1:numel(key)),'lineWidth',opts.lineWidth);
      if ( numel(hdls)>size(erp,1) && ~ishandle(hdls(end)) )
        hdls(end)=[];
      end;  
    end
    vistype=curvistype;
    % redraw, but not too fast
    if ( toc < opts.redraw_ms/1000 ) continue; else drawnow; tic; end;
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

