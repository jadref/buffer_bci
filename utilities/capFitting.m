function [dat,key,state]=capFitting(varargin);
% simple EEG electrode quality check for cap fitting
%
% []=capFitting(varargin)
%
%Options:
%  updateInterval- [int] how often to redraw the electrode quality display in seconds (.5)
%  capFile       - [str] file to use to get electrode positions from ('1010')
%  overridechnms - [bool] capFile names over-ride buffer provided names (0)
%  verb          - [int] verbosity level (0)
%  mafactor      - [float] moving average factor for computing the electrode noise power, pow=ma*powold+pow;  (.1)
%  noiseband     - [2x1] lower and upper frequency to include in the noise power computation ([45 55])
%  noiseThresholds - [2x1] lower and upper noise power thresholds for the [green and red] colors ([.5 5])
%  badChThreshold - [float] minimum noise power, below which we assume the channel is disconnected (1e-8)
%  showOffset    - [bool] flag is show offset quality also
%  offsetThresholds - [2x1] lower and upper noise power thresholds for the [green and red] colors ([5 15])
%  timeOut_ms    - [int] timeOut to wait for data from the buffer (5000)
%  host,port     - [str] host and port where the buffer lives ('localhost',1972)
wb=which('buffer'); if ( isempty(wb) || isempty(strfind('dataAcq',wb)) ); run('../utilities/initPaths.m'); end;
opts=struct('updateInterval',.5,'capFile',[],'overridechnms',0,'verb',1,'mafactor',.1,...
    'noiseband',[45 55],'noiseThresholds',[.5 5],'offsetThresholds',[5 15],'badChThreshold',1e-8,'fig',[],...
    'host',[],'buffhost','localhost','port',[],'buffport',1972,'timeOut_ms',5000,'showOffset',true);
opts=parseOpts(opts,varargin);
host=opts.buffhost; if ( isempty(host) ); host=opts.host; end
port=opts.buffport; if ( isempty(port) ); port=opts.port; end;

% create the plot
fig=opts.fig; if ( isempty(fig) ); fig=figure(1); end;
set(fig,'units','normalized','position',[0 0 1 1],'MenuBar','none','Name','capFitting', 'Color',[1 1 1],'NumberTitle','off','Visible','on');
% use complete available figure area
set(get(fig,'Children'),'Position',[0 0 .9 1]);

% get channel info for plotting
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
    try 
        hdr=buffer('get_hdr',[]); 
    catch
        hdr=[];
    end;
    pause(1);
    if ( ~ishandle(fig) )
        warning('Stopped cap fitting before we connected to the buffer!');
        return; 
    end;
end;

capFile=opts.capFile; overridechnms=opts.overridechnms; 
if(isempty(capFile)) 
  [fn,pth]=uigetfile('../utilities/caps/*.txt','Pick cap-file'); capFile=fullfile(pth,fn);
  if ( isequal(fn,0) || isequal(pth,0) ); capFile='1010.txt'; end; % 1010 default if not selected
end
if ( ~isempty(strfind(capFile,'1010.txt')) ); overridechnms=0; else overridechnms=1; end; % force default override
di = addPosInfo(hdr.channel_names,capFile,overridechnms); % get 3d-coords
ch_pos=cat(2,di.extra.pos2d); ch_names=di.vals; % extract pos and channels names
iseeg=find([di.extra.iseeg]);  

% add number prefix to ch-names for display
for ci=1:numel(ch_names); ch_names{ci} = sprintf('%d %s',ci,ch_names{ci}); end;

% amplifier specific thresholds
if ( ~isempty(strfind(capFile,'tmsi')) ); thresh=[.0 .1 .2 5]; badchThresh=1e-4; overridechnms=1;
else;                                     thresh=[.5 3];  badchThresh=.5;   overridechnms=0;
end

% use complete available figure area
if (isempty(iseeg)) % cope with unrecog electrode positions
    iseeg=true(1,size(ch_pos,2)); for ei=1:numel(ch_names); if (isempty(ch_names{ei}));iseeg(ei)=false;end;end
    iseeg=find(iseeg);
    % put the electrodes on a rectangular grid
    set(gca,'xlim',[-1 1],'ylim',[-1 1]);
    w=ceil(sqrt(numel(iseeg)));h=ceil(numel(iseeg)/w);
    ws=linspace(-.9,.9,w); hs=linspace(-.9,.9,h);
    for i=1:numel(iseeg);
      [wi,hi]=ind2sub([w h],i);
      ch_pos(1,iseeg(i))=ws(wi);
      ch_pos(2,iseeg(i))=hs(hi);
    end
    hold on;
else
    % draw the head
    topohead(); 
    hold on;
end
set(gca,'visible','off');
text(mean(get(gca,'xlim')),max(get(gca,'ylim')),'Close window to continue.','FontUnits','normalized','fontsize',.1,'HorizontalAlignment','center');

% draw the channel names and electrodes
for i=1:numel(iseeg);
   ei=iseeg(i);
   % draw the electrodes
   elect_hdls(i) = rectangle('position',[ch_pos(1,ei)-.1 ch_pos(2,ei)-.1 .2 .2],'curvature',[1 1],'edgeColor',[1 0 0],'lineWidth',8);
   nm_hdls(i)    = text(ch_pos(1,ei),ch_pos(2,ei),ch_names{ei},'HorizontalAlignment','center','fontsize',.1,'FontUnits','normalized','Interpreter','none');
end

% get bin locations
fftp=fftBins([],1,hdr.fsample,1);
% get locations we use to compute the power
[ans,bstart] = min(abs(fftp-opts.noiseband(1))); [ans,bend]=min(abs(fftp-opts.noiseband(2)));
noisebands = bstart:bend;
colors=trafficlight(64); %colors=colors(end:-1:1,:); % red at top, green at bottom

% compute the color thresholds
noiseBins=binPoss(size(colors,1),opts.noiseThresholds);
if ( opts.showOffset ) 
  offsetBins=binPoss(size(colors,1),opts.offsetThresholds); 
end
axes('outerposition',[.9 0 .1 1]);image(reshape(colors,[size(colors,1),1,size(colors,2)]));
set(gca,'ydir','normal','xtick',[],'yticklabel',round(noiseBins(get(gca,'ytick'))*100)/100);
title('50Hz power');

endTraining=false; 
key=[]; dat=[]; avepow=[]; nsamples=hdr.nsamples;
while ( ishandle(fig) ) % close figure to stop

   % wait for some new data
   endsamp = round(nsamples+opts.updateInterval*hdr.fsample);
   status=buffer('wait_dat',[endsamp -1 opts.timeOut_ms],host,port);
   if ( isempty(status) ); error('No data recieved'); return; 
   elseif ( status.nsamples < endsamp ); drawnow; continue; % not enough data yet
   end;
   dat   =buffer('get_dat',[nsamples endsamp],host,port);
   dat   =single(dat.buf);
   nsamples=status.nsamples;
   
   % fourier transform to get 50Hz power
   mu  = mean(dat,2);
   dat = dat-repmat(mu,1,size(dat,2)); % 0-mean first
   pow = abs(fft(dat,[],2))/size(dat,2);
   if ( isempty(avepow) ) 
      avepow=pow;
   else
      avepow = opts.mafactor*avepow + (1-opts.mafactor)*pow;
   end
   % get the noise power
   noisepow = mean(avepow(:,noisebands),2);
   if ( opts.verb>=0 ) 
     fprintf('%6.1f %s',median(mu(iseeg)),sprintf('%6.1f(%6.4f)\t',[mu(iseeg)-median(mu(iseeg)),noisepow(iseeg)]'));
     if ( ispc() ); fprintf('\n'); else fprintf('\r'); end;
   end;
   
   % update the plot
   electpow = noisepow(iseeg); 
   % exactly 0-noise power, means disconnected channel so make have infinite power
   electpow(mean(pow(iseeg,noisebands),2)<opts.badChThreshold)=inf;
   % map the power into the color range we're using
   electpow = min(max(electpow,noiseBins(1)),noiseBins(end));% limit to color range
   for ei=1:numel(electpow); 
     col(ei,:)=colors(electpow(ei)<=noiseBins(2:end) & electpow(ei)>=noiseBins(1:end-1),:);
   end   
   %col = colors(round((electpow-opts.noiseThresholds(1))/diff(opts.noiseThresholds)*(size(colors,1)-1))+1,:);
   if ( opts.showOffset )
      offset   = abs(mu(iseeg)-median(mu(iseeg)));
      offset   = min(max(offset,offsetBins(1)),offsetBins(end));
      for ei=1:numel(electpow); 
        ocol(ei,:)=colors(offset(ei)<=offsetBins(2:end) & offset(ei)>=offsetBins(1:end-1),:);
      end   
   else
      ocol=col;
   end
   % set the color
   if ( ishandle(fig) )
     for i=1:numel(elect_hdls); set(elect_hdls(i),'EdgeColor',col(i,:),'FaceColor',ocol(i,:)); end;
     drawnow;
   end
   % pause for some time to allow for <ctrl-c> without the buffer crashing
   pause(opts.timeOut_ms/2/1000);
end
return;
function bins=binPoss(N,pts)
nRange   =numel(pts)-1;
szRange  =floor(N/nRange);
bins=zeros(N,1);
for ri=1:nRange-1; 
  bins((ri-1)*szRange+(1:szRange+1))=linspace(pts(ri),pts(ri+1),szRange+1); 
end
ri=nRange;
bins((ri-1)*szRange+1:end)=linspace(pts(ri),pts(ri+1),numel(bins)-(ri-1)*szRange); 
return;

function rgb = trafficlight(n);
% trafficlight order colormap, i.e. green yellow red
if nargin == 0, n = size(get(gcf,'colormap'),1); end
m = fix(n/2);
step = 1/m;
ltop = ones(m+1,1);
stop = ones(m,1);
lbot = zeros(m+1,1);
sbot = zeros(m,1);
lup = (0:step:1)';
sup = (step/2:step:1)';
ldown = (1:-step:0)';
sdown = (1-step/2:-step:0)';
if n-2*m == 1
   rgb = ([lup ltop lbot;stop sdown sbot]);
else
   rgb = ([sup stop sbot;stop sdown sbot]);
end
