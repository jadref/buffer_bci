function [rawEpochs,rawIds,key]=erpViewer(buffhost,buffport,varargin);
% simple viewer for ERPs based on matching buffer events
%
% [rawEpochs,rawIds,key]=erpViewer(buffhost,buffport,varargin)
%
opts=struct('cuePrefix','cue.','endType','end.training','verb',1,'nSymbols',0,'trlen_ms',1000,'trlen_samp',[],'detrend',1,'fftfilter',[],'freqbands',[],'spatfilt','car','capFile','1010','overridechnms',0,'welch_width_ms',500,'redraw_ms',500);
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
di = addPosInfo(hdr.channel_names,opts.capFile,opts.overridechnms); % get 3d-coords
ch_pos=cat(2,di.extra.pos2d); ch_names=di.vals; % extract pos and channels names
iseeg=[di.extra.iseeg];

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
filt=[];if ( ~isempty(opts.freqbands)) filt=mkFilter(trlen_samp/2,opts.freqbands,fs/trlen_samp);end

% recording the ERP data
key      = {};
nCls     = opts.nSymbols;
rawEpochs= zeros(sum(iseeg),trlen_samp); % stores the raw data
rawIds   = 0;
nTarget  = 0;
erp      = zeros(sum(iseeg),trlen_samp,max(1,nCls)); % stores the pre-proc data used in the figures

% make the figure window
clf;
fig=gcf;
set(fig,'Name','ER(s)P Viewer : close window to stop.','menubar','none','toolbar','none','doublebuffer','on');
hdls=image3d(erp,1,'plotPos',ch_pos(:,iseeg),'Xvals',ch_names(iseeg),'Yvals',times,'ylabel','time (s)','zlabel','class','disptype','plot','ticklabs','sw','legend','se','plotPosOpts.plotsposition',[.05 .08 .91 .85]);
zoomplots;

% make popup menu for selection of TD/FD
tdfdhdl=uicontrol(fig,'Style','popup','units','normalized','position',[.8 .9 .2 .1],'String','Time|Frequency');
pos=get(tdfdhdl,'position');
resethdl=uicontrol(fig,'Style','togglebutton','units','normalized','position',[pos(1)-.2 pos(2)+pos(4)*.4 .2 pos(4)*.6],'String','Reset');
vistype=1; ylabel='time (s)';  yvals=times; set(tdfdhdl,'value',vistype);
drawnow; % make sure the figure is visible

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
      
      % pre-process the data
      dat   = datai(ei).buf(iseeg,:);
      if ( opts.detrend ) dat=detrend(dat,2); end;
      if ( ~isempty(opts.spatfilt) ) 
        if ( strcmpi(opts.spatfilt,'car') ) dat=repop(dat,'-',mean(dat,1)); end
      end
      
      % store the 'raw' data
      nTarget=nTarget+1;
      rawIds(nTarget)=mi;
      rawEpochs(:,:,nTarget) = dat;
    end
  end

  % Now do MATLAB gui events
  curvistype=get(tdfdhdl,'value');
  if ( curvistype~=vistype ) % all to be updated!
    fprintf('vis switch detected\n');
    updateLines(1)=true; updateLines(:)=true;
    if ( curvistype==1 ) 
      ylabel='time (s)';  yvals=times; 
    elseif ( curvistype==2 ) 
      ylabel='freq (hz)'; yvals=freqs(freqIdx(1):freqIdx(2)); 
    else
      error('extra vistype');
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
    set(resethdl,'value',0); % pop the button back out
  end

  % compute the updated ERPs (if any)
  if ( any(updateLines) )
    damagedLines=find(updateLines(1:numel(key)));
    for mi=damagedLines(:)';
      ppdat=rawEpochs(:,:,rawIds==mi);
      if ( isempty(ppdat) ) erp(:,:,mi)=0; continue; end;
      if( curvistype==1 ) % time-domain
        if( ~isempty(filt)) ppdat=fftfilter(ppdat,filt,[],2); end;
      elseif( curvistype==2 ) % frequency domain
        ppdat=welchpsd(ppdat,2,'width_ms',opts.welch_width_ms,'fs',hdr.fsample,'aveType','amp');          
        ppdat = ppdat(:,freqIdx(1):freqIdx(2),:);                % select frequencies
      else
        error('extra vistype');
      end
      erp(:,:,mi) = mean(ppdat,3);
      if ( isnumeric(key{mi}) ) % line label -- including number of times seen
        label{mi}=sprintf('%g (%d)',key{mi},sum(rawIds(1:nTarget)==mi));
      else
        label{mi}=sprintf('%s (%d)',key{mi},sum(rawIds(1:nTarget)==mi));
      end
    end
    vistype=curvistype;
  
    % and update the plot
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
run ../utilities/initPaths;

% start the buffer proxy
% dataAcq/startSignalProxy
erpViewer([],[],'cuePrefix','keyboard');

