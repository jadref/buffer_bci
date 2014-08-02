function [rawEpochs,rawIds,key]=erpViewer(buffhost,buffport,varargin);
% simple viewer for ERPs based on matching buffer events
%
% [rawEpochs,rawIds,key]=erpViewer(buffhost,buffport,varargin)
%
opts=struct('cuePrefix','cue.','endType','end.training','verb',1,'nSymbols',0,'trlen_ms',1000,'trlen_samp',[],'detrend',1,'fftfilter',[],'freqbands',[],'downsample',128,'spatfilt','car','badchrm',0,'capFile',[],'overridechnms',0,'welch_width_ms',500,'redraw_ms',500);
[opts,varargin]=parseOpts(opts,varargin);
if ( nargin<1 || isempty(buffhost) ) buffhost='localhost'; end;
if ( nargin<2 || isempty(buffport) ) buffport=1972; end;
if ( isempty(opts.freqbands) && ~isempty(opts.fftfilter) ) opts.freqbands=opts.fftfilter; end;
if ( isstr(opts.endType) ) opts.endType={opts.endType}; end;

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
  [fn,pth]=uigetfile('../utilities/*.txt','Pick cap-file'); drawnow;
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
times=(1:trlen_samp)./fs;
freqs=0:1000/opts.welch_width_ms:fs/2;
if ( ~isempty(opts.freqbands) )
  [ans,freqIdx(1)]=min(abs(freqs-opts.freqbands(1))); 
  [ans,freqIdx(2)]=min(abs(freqs-opts.freqbands(max(end,2))));
else
  freqIdx=[1 numel(freqs)];
end

% make the spectral filter
filt=[]; if ( ~isempty(opts.freqbands)) filt=mkFilter(trlen_samp/2,opts.freqbands,fs/trlen_samp);end
outsz=[trlen_samp trlen_samp];if(~isempty(opts.downsample)) outsz(2)=min(outsz(2),round(trlen_samp*opts.downsample/fs)); end;

% recording the ERP data
key      = {};
label    = {};
nCls     = opts.nSymbols;
rawEpochs= zeros(sum(iseeg),trlen_samp); % stores the raw data
rawIds   = 0;
nTarget  = 0;
erp      = zeros(sum(iseeg),trlen_samp,max(1,nCls)); % stores the pre-proc data used in the figures

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
hdls=image3d(erp,1,'plotPos',ch_pos(:,iseeg),'Xvals',ch_names(iseeg),'Yvals',times,'ylabel','time (s)','zlabel','class','disptype','plot','ticklabs','sw','legend','se','plotPosOpts.plotsposition',[.05 .08 .91 .85]);

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
ppopts.preproctype='none';if(opts.detrend)preproctype='detrend'; end;
ppopts.spatfilttype=opts.spatfilt;
ppopts.freqbands=opts.freqbands;

% pre-call buffer_waitData to cache its options
[datai,deventsi,state,waitDatopts]=buffer_waitData(buffhost,buffport,[],'startSet',{opts.cuePrefix},'trlen_samp',trlen_samp,'exitSet',{opts.redraw_ms 'data' opts.endType{:}},'verb',opts.verb,varargin{:},'getOpts',1);

endTraining=false;
while ( ~endTraining )

  % wait for events...
  [datai,deventsi,state]=buffer_waitData(buffhost,buffport,state,waitDatopts);
  
  if ( ~ishandle(fig) ) break; end;
  
  updateLines=false(numel(key),1);
  keep=true(numel(deventsi),1);
  for ei=1:numel(deventsi);
      event=deventsi(ei);
      if( strmatch(opts.endType,event.type) )
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
        rawIds(nTarget)=mi;
        rawEpochs(:,:,nTarget) = datai(ei).buf(iseeg,:);      
      end
    end

    % Now do MATLAB gui events
    modekey=[]; if ( ~isempty(modehdl) ) modekey=get(modehdl,'value'); end;
    if ( ~isempty(get(fig,'userdata')) ) modekey=get(fig,'userdata'); end; % modekey-overrides drop-down
    if ( ~isempty(modekey) )
      switch ( modekey );
       case {1,'t'}; tmp=1;curvistype='time';
       case {2,'f'}; tmp=2;curvistype='freq';
       case {3,'p'}; tmp=3;curvistype='power';
       case {4,'s'}; tmp=4;curvistype='spect';
       case {'r'};   resetval=true; set(resethdl,'value',resetval); % press the reset button
       case 'q'; break;
      end;
      set(fig,'userdata',[]);
      if ( ~isempty(modehdl) ) set(modehdl,'value',tmp); end;
    end

    %---------------------------------------------------------------------------------
    % Do visualisation mode switching work
    if ( curvistype~=vistype ) % all to be updated!
      fprintf('vis switch detected\n');
      updateLines(1)=true; updateLines(:)=true;
      switch( curvistype )
       case {1,'time'}; ylabel='time (s)';  yvals=times; 
       case {2,'freq'}; ylabel='freq (hz)'; yvals=freqs(freqIdx(1):freqIdx(2)); 
       otherwise; error('extra vistype');
      end    
      % reset stored ERP info
      erp=zeros(sum(iseeg),numel(yvals),max(1,numel(key)));
    end; 

    resetval=get(resethdl,'value');
    if ( resetval ) 
      fprintf('reset detected\n');
      key={}; nTarget=0; rawIds=[];
      erp=zeros(sum(iseeg),numel(yvals),1);
      updateLines(1)=true; updateLines(:)=true; % everything must be re-drawn
      resetval=0;
      set(resethdl,'value',resetval); % pop the button back out
    end

    %---------------------------------------------------------------------------------
    % compute the updated ERPs (if any)
    if ( any(updateLines) )
      damagedLines=find(updateLines(1:numel(key)));
      for mi=damagedLines(:)';
        ppdat=rawEpochs(:,:,rawIds==mi);
        if ( isempty(ppdat) ) erp(:,:,mi)=0; continue; end;

        % pre-process the data
        switch(lower(ppopts.preproctype));
         case 'none';   
         case 'center'; ppdat=repop(ppdat,'-',mean(ppdat,2));
         case 'detrend';ppdat=detrend(ppdat,2);
         otherwise; warning(sprintf('Unrecognised pre-proc type: %s',lower(ppopts.preproctype)));
        end
      
        switch(lower(ppopts.spatfilttype))
         case 'none';
         case 'car';    ppdat=repop(ppdat,'-',mean(ppdat,1));
         case 'slap';   if ( ~isempty(slapfilt) ) ppdat=tprod(ppdat,[-1 2 3],slapfilt,[-1 1]); end;
         case 'whiten'; 
         otherwise; warning(sprintf('Unrecognised spatial filter type : %s',ppopts.spatfilttype));
        end
      
        % compute the visualisation
        switch (curvistype) 
        
         case 'time'; % time-domain, spectral filter
          if ( ~isempty(filt) )      ppdat=fftfilter(ppdat,filt,outsz,2);  % N.B. downsample at same time
          elseif ( ~isempty(outsz) ) ppdat=subsample(ppdat,outsz(2),2);    % manual downsample
          end
        
         case 'freq'; % freq-domain
          ppdat = welchpsd(ppdat,2,'width_ms',opts.welch_width_ms,'fs',hdr.fsample,'aveType','amp');
          ppdat = ppdat(:,freqIdx(1):freqIdx(2),:);
        
         otherwise; error('Unrecognised visualisation type: ');
        end

        erp(:,:,mi) = mean(ppdat,3);
        if ( isnumeric(key{mi}) ) % line label -- including number of times seen
          label{mi}=sprintf('%g (%d)',key{mi},sum(rawIds(1:nTarget)==mi));
        else
          label{mi}=sprintf('%s (%d)',key{mi},sum(rawIds(1:nTarget)==mi));
        end
      end
      vistype=curvistype;
    
      %---------------------------------------------------------------------------------
      % Update the plot
      hdls=image3d(erp,1,'handles',hdls,'Xvals',ch_names(iseeg),'Yvals',yvals,'ylabel',ylabel,'zlabel','class','disptype','plot','ticklabs','sw','Zvals',label(1:numel(key)));
    end
    drawnow;      
  end
if ( ishandle(fig) ) close(fig); end;
if( nargout>0 ) 
  rawIds=rawIds(1:nTarget);
  rawEpochs=rawEpochs(:,:,1:nTarget);
end
return;
%-----------------------
function testCase();
%Add necessary paths
run ../utilities/initPaths.m;

% start the buffer proxy
% dataAcq/startSignalProxy
erpViewer([],[],'cuePrefix','keyboard');

