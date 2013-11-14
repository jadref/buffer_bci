function []=eegViewer(buffhost,buffport,varargin);
opts=struct('endType','end.training','verb',1,'trlen_ms',5000,'trlen_samp',[],'updateFreq',4,'detrend',1,'fftfilter',[.1 .3 45 47],'freqbands',[],'downsample',128,'spatfilt','car','capFile','1010','overridechnms',0,'welch_width_ms',500);
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
di = addPosInfo(hdr.channel_names,opts.capFile,opts.overridechnms); % get 3d-coords
ch_pos=cat(2,di.extra.pos2d); ch_names=di.vals; % extract pos and channels names
iseeg=[di.extra.iseeg];

if ( isfield(hdr,'fSample') ) fs=hdr.fSample; else fs=hdr.fsample; end;
trlen_samp=opts.trlen_samp;
if ( isempty(trlen_samp) && ~isempty(opts.trlen_ms) ) trlen_samp=round(opts.trlen_ms*fs/1000); end;
update_samp=ceil(fs/opts.updateFreq);
trlen_samp=ceil(trlen_samp/update_samp)*update_samp;
fprintf('tr_samp = %d update_samp = %d\n',trlen_samp,update_samp);
blkIdx = trlen_samp-update_samp; % index for where new data gets inserted
if ( isempty(opts.downsample) ) 
    times=(1:trlen_samp)./fs;
else
    times=(1:ceil(trlen_samp*opts.downsample/fs))/opts.downsample;
end
freqs=0:1000/opts.welch_width_ms:fs/2;
[ans,freqIdx(1)]=min(abs(freqs-opts.freqbands(1))); 
[ans,freqIdx(2)]=min(abs(freqs-opts.freqbands(max(end,2))));

% make the spectral filter
filt=[]; if ( ~isempty(opts.freqbands)) filt=mkFilter(trlen_samp/2,opts.freqbands,fs/trlen_samp);end
outsz=[trlen_samp trlen_samp];if(~isempty(opts.downsample)) outsz(2)=min(outsz(2),round(trlen_samp*opts.downsample/fs)); end;
  
% recording the ERP data
rawdat    = zeros(sum(iseeg),outsz(1));
ppdat     = zeros(sum(iseeg),outsz(2));

% make the figure window
clf;
fig=gcf;
set(fig,'Name','EEG Viewer : close window to stop.','menubar','none','toolbar','none','doublebuffer','on');
hdls=image3d(ppdat,1,'plotPos',ch_pos(:,iseeg),'Xvals',ch_names,'Yvals',times,'ylabel','time (s)','zlabel','class','disptype','plot','ticklabs','sw','legend',0,'plotPosOpts.plotsposition',[.05 .08 .91 .85]);
zoomplots;
drawnow; % make sure the figure is visible

% make popup menu for selection of TD/FD
tdfdhdl=uicontrol(fig,'Style','popup','units','normalized','position',[.8 .9 .2 .1],'String','Time|Frequency');
vistype=get(tdfdhdl,'value');

% extract the lines so we can directly update them.
ylim=[inf -inf];
for hi=1:size(ppdat,1); 
   lines(hi)=findobj(get(hdls(hi),'children'),'type','line'); 
   ylimi=get(hdls(hi),'ylim');ylim(1)=min(ylim(1),ylimi(1)); ylim(2)=max(ylim(2),ylimi(2));
end;

endTraining=false; state=[];
cursamp=hdr.nSamples;
while ( ~endTraining )  
   % wait for new data to be available
   status=buffer('wait_dat',[cursamp+update_samp inf inf],buffhost,buffport);
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

   % switch to frequency domain visualization if wanted
   curvistype=get(tdfdhdl,'value');
   switch (curvistype) 
     case 1; % time-domain, spectral filter
       if ( ~isempty(filt) )      ppdat=fftfilter(ppdat,filt,outsz,2);  % N.B. downsample at same time
       elseif ( ~isempty(outsz) ) ppdat=subsample(ppdat,outsz(2),2); % manual downsample
       end
     case 2; % freq-domain
       ppdat = welchpsd(ppdat,2,'width_ms',opts.welch_width_ms,'fs',hdr.fsample,'aveType','db');
       ppdat = ppdat(:,freqIdx(1):freqIdx(2));
   end
   
   yrange=[min(ppdat(:)),max(ppdat(:))];
   if ( vistype~=curvistype ) % reset the axes
      ylim=yrange;
      if ( ylim(1)>=ylim(2) || any(isnan(ylim)) ) ylim=[-1 1]; end;
      set(hdls(1:size(ppdat,1)),'ylim',ylim);
      if ( curvistype==1 ) % time-domain
         for hi=1:size(ppdat,1);
            if ( ~isempty(get(hdls(hi),'Xlabel')) ) xlabel(hdls(hi),'time (s)'); end
         end
         set(lines,'xdata',times(1:size(ppdat,2)));
         set(hdls,'xlim',[times(1) times(end)]);
      else      
         for hi=1:size(ppdat,1);
            if ( ~isempty(get(hdls(hi),'Xlabel')) ) xlabel(hdls(hi),'freq(hz)'); end;
         end
         set(lines,'xdata',freqs(freqIdx(1):freqIdx(2)));
         set(hdls,'xlim',freqs([freqIdx(1) freqIdx(2)]));
      end
      vistype=curvistype;
   else % adapt the axes to the data
      if ( yrange(1)<ylim(1)-diff(ylim)*.2 || yrange(1)>ylim(1)+diff(ylim)*.2 || ...
           yrange(2)>ylim(2)+diff(ylim)*.2 || yrange(2)<ylim(2)-diff(ylim)*.2 )
         if ( isequal(yrange,[0 0]) ) 
            %fprintf('Warning: Clims are equal -- reset to clim+/- .5');
            yrange=.5*[-1 1]; 
         elseif ( yrange(1)==yrange(2) ) 
           yrange=yrange(1)+.5*[-1 1];
         end;
          ylim=yrange; set(hdls(1:size(ppdat,1)),'ylim',ylim);
      end
   end
   
   % update the plot
   for hi=1:size(ppdat,1);
      set(lines(hi),'ydata',ppdat(hi,:));
   end
   drawnow;
end
return;
%-----------------------
function testCase();
%Add necessary paths

if ( exist('initPaths.m','file') ) 
  initPaths;
else
  run ../utilities/initPaths;
end

% start the buffer proxy
% dataAcq/startSignalProxy

eegViewer();

