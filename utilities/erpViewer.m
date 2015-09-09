function [rawEpochs,rawIds,key]=erpViewer(buffhost,buffport,varargin);
% simple viewer for ERPs based on matching buffer events
%
% [rawEpochs,rawIds,key]=erpViewer(buffhost,buffport,varargin)
%
% Options
%  cuePrefix - 'str' event type to match for an ERP to be stored    ('stimulus')
%  endType   - 'str' event type to match to say stop recording ERPs ('end.training')
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
opts=struct('cuePrefix','stimulus','endType','end.training','verb',1,...
				'nSymbols',0,'maxEvents',[],...
				'trlen_ms',1000,'trlen_samp',[],'offset_ms',[],'offset_samp',[],...
				'detrend',1,'fftfilter',[],'freqbands',[],'downsample',128,'spatfilt','car',...
				'badchrm',0,'badchthresh',3,'badtrthresh',3,...
				'capFile',[],'overridechnms',0,'welch_width_ms',500,...
				'redraw_ms',500,'lineWidth',2,'sigProcOptsGui',1);
[opts,varargin]=parseOpts(opts,varargin);
if ( nargin<1 || isempty(buffhost) ) buffhost='localhost'; end;
if ( nargin<2 || isempty(buffport) ) buffport=1972; end;
if ( isempty(opts.freqbands) && ~isempty(opts.fftfilter) ) opts.freqbands=opts.fftfilter; end;
if ( isstr(opts.endType) ) opts.endType={opts.endType}; end;
wb=which('buffer'); if ( isempty(wb) || isempty(strfind('dataAcq',wb)) ); run(fullfile(fileparts(mfilename('fullpath')),'../utilities/initPaths.m')); end;
if ( exist('OCTAVE_VERSION','builtin') ) % use best octave specific graphics facility
  if ( ~isempty(strmatch('qthandles',available_graphics_toolkits())) )
    graphics_toolkit('qthandles'); % use fast rendering library
  elseif ( ~isempty(strmatch('fltk',available_graphics_toolkits())) )
    graphics_toolkit('fltk'); % use fast rendering library
  end
  opts.sigProcOptsGui=0;
end

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

% extract channel info from hdr
ch_names=hdr.channel_names; ch_pos=[]; iseeg=true(numel(ch_names),1);
% get capFile info for positions
capFile=opts.capFile; overridechnms=opts.overridechnms; 
if(isempty(opts.capFile)) 
  [fn,pth]=uigetfile(fullfile(fileparts(mfilename('fullpath')),'../utilities/*.txt'),'Pick cap-file');
  drawnow;
  if ( ~isequal(fn,0) ) capFile=fullfile(pth,fn); end;
  %if ( isequal(fn,0) || isequal(pth,0) ) capFile='1010.txt'; end; % 1010 default if not selected
end
if ( ~isempty(strfind(capFile,'1010.txt')) ) overridechnms=0; else overridechnms=1; end; % force default override
if ( ~isempty(capFile) ) 
  di = addPosInfo(ch_names,capFile,overridechnms); % get 3d-coords
  ch_pos=cat(2,di.extra.pos2d); % extract pos and channels names
  ch_pos3d=cat(2,di.extra.pos3d);
  ch_names=di.vals; 
  iseeg=[di.extra.iseeg];
  if ( ~any(iseeg) ) % fall back on showing all data
    warning('Capfile didnt match any data channels -- no EEG?');
    ch_names=hdr.channel_names;
    ch_pos=[];
    iseeg=true(numel(ch_names),1);
  end
end

if ( isfield(hdr,'fSample') ) fs=hdr.fSample; else fs=hdr.fsample; end;
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
if ( ~isempty(maxEvents) )  rawEpochs= zeros(sum(iseeg),outsz(1),maxEvents); % stores the raw data
else                        rawEpochs= zeros(sum(iseeg),outsz(1),40); 
end
rawIds   = 0;
nTarget  = 0;
erp      = zeros(sum(iseeg),outsz(2),max(1,nCls)); % stores the pre-proc data used in the figures
isbad    = false(sum(iseeg),1);

% pre-compute the SLAP spatial filter
slapfilt=[];
if ( ~isempty(ch_pos) )       
  slapfilt=sphericalSplineInterpolate(ch_pos3d(:,iseeg),ch_pos3d(:,iseeg),[],[],'slap');%pre-compute the SLAP filter we'll use
else
  warning('Cant compute SLAP without channel positions!'); 
end

% make the figure window
clf;
fig=gcf;
set(fig,'Name','ER(s)P Viewer : t=time, f=freq, r=rest, q,close window=quit','menubar','none','toolbar','none','doublebuffer','on');
plotPos=ch_pos; if ( ~isempty(plotPos) ) plotPos=plotPos(:,iseeg); end;
hdls=image3d(erp,1,'plotPos',plotPos,'Xvals',ch_names(iseeg),'Yvals',times,'ylabel','time (s)','zlabel','class','disptype','plot','ticklabs','sw','legend','se','plotPosOpts.plotsposition',[.05 .08 .91 .85],'lineWidth',opts.lineWidth);

% make popup menu for selection of TD/FD
modehdl=uicontrol(fig,'Style','popup','units','normalized','position',[.8 .9 .2 .1],'String','Time|Frequency');
pos=get(modehdl,'position');
resethdl=uicontrol(fig,'Style','togglebutton','units','normalized','position',[pos(1)-.2 pos(2)+pos(4)*.4 .2 pos(4)*.6],'String','Reset');
vistype=1; ylabel='time (s)';  yvals=times; set(modehdl,'value',vistype);
if ( ~exist('OCTAVE_VERSION','builtin') ) % in octave have to manually convert arrays..
  zoomplots;
end
% install listener for key-press mode change
set(fig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
set(fig,'userdata',[]);
drawnow; % make sure the figure is visible

ppopts.badchrm=opts.badchrm;
ppopts.preproctype='none';if(opts.detrend)ppopts.preproctype='detrend'; end;
ppopts.spatfilttype=opts.spatfilt;
ppopts.freqbands=opts.freqbands;
optsFighandles=[];
if ( isequal(opts.sigProcOptsGui,1) )
  optsFigh=sigProcOptsFig();
  optsFighandles=guihandles(optsFigh);
  set(optsFighandles.lowcutoff,'string',sprintf('%g',ppopts.freqbands(1)));
  set(optsFighandles.highcutoff,'string',sprintf('%g',ppopts.freqbands(end)));  
  for h=get(optsFighandles.spatfilt,'children')'; 
    if ( strcmpi(get(h,'string'),ppopts.spatfilttype) ) set(h,'value',1); break;end; 
  end;
  for h=get(optsFighandles.preproc,'children')'; 
    if ( strcmpi(get(h,'string'),ppopts.preproctype) ) set(h,'value',1); break;end; 
  end;
  set(optsFighandles.badchrm,'value',ppopts.badchrm);
  ppopts=getSigProcOpts(optsFighandles);
end

% pre-call buffer_waitData to cache its options
[datai,deventsi,state,waitDatopts]=buffer_waitData(buffhost,buffport,[],'startSet',{opts.cuePrefix},'trlen_samp',trlen_samp,'offset_samp',offset_samp,'exitSet',{opts.redraw_ms 'data' opts.endType{:}},'verb',opts.verb,varargin{:},'getOpts',1);

fprintf("Waiting for events of type: %s\n",opts.cuePrefix);

endTraining=false;
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
    if ( ~isempty(modehdl) ) set(modehdl,'value',modekey); end;
  end
  % get updated sig-proc parameters if needed
  if ( ~isempty(optsFighandles) && ishandle(optsFighandles.figure1) )
    [ppopts,damage]=getSigProcOpts(optsFighandles,ppopts);
    % compute updated spectral filter information, if needed
    if ( any(damage) ) % re-draw all
      fprintf('Redraw all detected\n');
      updateLines(1)=true; updateLines(:)=true; 
    end; 
    if ( damage(4) )
      filt=[];
      if ( ~isempty(ppopts.freqbands) ) % filter bands given
        filt=mkFilter(trlen_samp/2,ppopts.freqbands,fs/trlen_samp); 
      end
      freqIdx =getfreqIdx(freqs,ppopts.freqbands);
    end
  end
  resetval=get(resethdl,'value');
  if ( resetval ) 
    fprintf('reset detected\n');
    key={}; nTarget=0; rawIds=[];
    erp=zeros(sum(iseeg),numel(yvals),1);
    updateLines(1)=true; updateLines(:)=true; % everything must be re-drawn
    resetval=0;
    set(resethdl,'value',resetval); % pop the button back out
  end
  
  keep=true(numel(deventsi),1);
  for ei=1:numel(deventsi);
      event=deventsi(ei);
      if( ~isempty(strmatch(event.type,opts.endType)) )
        % end-training event
        keep(ei:end)=false;
        endTraining=true; % mark to finish
        fprintf('Discarding all subsequent events: exit\n');
        break;
      else
        val = event.value;      
        mi=[]; 
        if ( ~isempty(key) ) % match if we've seen this key before 
          for ki=1:numel(key) if ( isequal(val,key{ki}) ) mi=ki; break; end; end; 
        end;
        if ( isempty(mi) ) % new class to average
          key{end+1}=val;
          mi=numel(key);
          erp(:,:,mi)=0;
          nCls       =mi;
        end;
        updateLines(mi)=true;
      
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
      switch(lower(ppopts.preproctype));
       case 'none';   
       case 'center'; ppdat=repop(ppdat,'-',mean(ppdat,2));
       case 'detrend';ppdat=detrend(ppdat,2);
       otherwise; warning(sprintf('Unrecognised pre-proc type: %s',lower(ppopts.preproctype)));
      end
        
      % bad-channel identify and remove
      if( ~isempty(ppopts.badchrm) && ppopts.badchrm>0 )
        isbadch=idOutliers(rawEpochs,1,opts.badchthresh);
        % set the data in this channel to 0
        ppdat(isbadch,:)=0;
        
        % bad-ch rm also implies bad trial
        isbadtr=idOutliers(ppdat,3,opts.badtrthresh);
        ppdat(:,:,isbadtr)=0;
      end
      
      for mi=damagedLines(:)';
        ppdatmi=ppdat(:,:,rawIds==mi);
        if ( isempty(ppdatmi) ) erp(:,:,mi)=0; continue; end;

        % spatial filter
        switch(lower(ppopts.spatfilttype))
         case 'none';
         case 'car';    ppdatmi(~isbad,:,:)=repop(ppdatmi(~isbad,:,:),'-',mean(ppdatmi(~isbad,:,:),1));
         case 'slap';   
          if ( ~isempty(slapfilt) ) % only use and update from the good channels
            ppdatmi(~isbad,:,:)=tprod(ppdatmi(~isbad,:,:),[-1 2 3],slapfilt(~isbad,~isbad),[-1 1]); 
          end;
         case 'whiten'; [W,D,ppdatmi(~isbad,:,:)]=whiten(ppdatmi(~isbad,:,:),1,'opt',1,0,1); %symetric whiten
         otherwise; warning(sprintf('Unrecognised spatial filter type : %s',ppopts.spatfilttype));
        end        
        
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

        erp(:,:,mi) = sum(ppdatmi,3)./size(ppdatmi,3);
        if ( isnumeric(key{mi}) ) % line label -- including number of times seen
          label{mi}=sprintf('%g (%d)',key{mi},sum(rawIds(1:nTarget)==mi));
        else
          label{mi}=sprintf('%s (%d)',key{mi},sum(rawIds(1:nTarget)==mi));
        end
      end
      vistype=curvistype;
    
      %---------------------------------------------------------------------------------
      % Update the plot
      hdls=image3d(erp,1,'handles',hdls,'Xvals',ch_names(iseeg),'Yvals',yvals,'ylabel',ylabel,'zlabel','class','disptype','plot','ticklabs','sw','Zvals',label(1:numel(key)),'lineWidth',opts.lineWidth);
    end
    drawnow;      
  end
if ( ishandle(fig) ) close(fig); end;
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

function [sigprocopts,damage]=getSigProcOpts(optsFighandles,oldopts)
% get the current options from the sig-proc-opts figure
sigprocopts.badchrm=get(optsFighandles.badchrm,'value');
sigprocopts.spatfilttype=get(get(optsFighandles.spatfilt,'SelectedObject'),'String');
sigprocopts.preproctype=get(get(optsFighandles.preproc,'SelectedObject'),'String');
sigprocopts.freqbands=[str2num(get(optsFighandles.lowcutoff,'string')) ...
                    str2num(get(optsFighandles.highcutoff,'string'))];  
if ( numel(sigprocopts.freqbands)>4 ) sigprocopts.freqbands=sigprocopts.freqbands(1:min(end,4));
elseif ( numel(sigprocopts.freqbands)<2 ) sigprocopts.freqbands=[];
end;
damage=false(4,1);
if( nargout>1 && nargin>1) 
  if ( isstruct(oldopts) )
    damage(1)= ~isequal(oldopts.badchrm,sigprocopts.badchrm);
    damage(2)= ~isequal(oldopts.spatfilttype,sigprocopts.spatfilttype);
    damage(3)= ~isequal(oldopts.preproctype,sigprocopts.preproctype);
    damage(4)= ~isequal(oldopts.freqbands,sigprocopts.freqbands);
  end
end


%-----------------------
function testCase();
%Add necessary paths
run ../utilities/initPaths.m;

% start the buffer proxy
% dataAcq/startSignalProxy
erpViewer([],[],'cuePrefix','keyboard');

