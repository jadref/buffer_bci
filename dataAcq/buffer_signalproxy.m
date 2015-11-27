function []=buffer_signalproxy(host,port,varargin);
% generate simulated data for a buffer
% 
% []=buffer_signalproxy(host,port,varargin);
% 
% Inputs:
%  host - [str] hostname on which the buffer server is running (localhost)
%  port - [int] port number on which to contact the server     (1972)
% Options:
%  fsample - [int] data sample rate                            (100)
%  nCh     - [int] number of simulated channels                (3)
%  blockSize- [int] number of samples to send at a time to buffer (2)
%  Cnames   - {str} cell array of strings with the channel names in ([])
%               if empty, channel names are 'rand01', 'rand02', etc
%  stimEventRate - [int] rate in samples at which stimulated 'stimulus'  (100)
%                   events are generated 
%  queueEventRate - [int] rate (in samples) at which simulated type='queue'   (500)
%                   events are generated
%  keyboardEvents - [bool] do we listen for keyboard events and generate (1)
%                   type='keyboard' events from them?
%  key2signal     - [bool] does the signal amplitude depend on keypresses (1)
%                   the amplitude of channel 1 is scaled by the ascii value of the last
%                   pressed key, e.g. 
%                      'space' = amplitude 0, 0= amplitude 1, 9= amplitude 2, Z=amplitude 26
%                      'e' = exponential ERP, 't'='tophat' ERP, 'g'='gaussian' ERP
%  mouse2signal   - [bool] does the signal amplitude depend on mouse position (1)
%                     channel 2 amplitude = mouse x-coordinate / screen x-size * 2
%                     channel 3 amplitude = mouse y-coordinate / screen y-size * 2
%  event2signal   - [bool] do certain events with type 'sigprox.erp' ERP style events?    (1)
%                      event types are similar to te key2signal events
%                      sendEvent('sigprox.erp','e') = exponential ERP  
%                      sendEvent('sigprox.erp','t') = tophat ERP       
%                      sendEvent('sigprox.erp','g') = gaussian ERP
%  triggerType    - [str] event type to look for event2signal triggers
%  verb           - [int] verbosity level.  If <0 then rate in samples to print status info (0)
if ( nargin<2 || isempty(port) ) port=1972; end;
if ( nargin<1 || isempty(host) ) host='localhost'; end;
wb=which('buffer'); if ( isempty(wb) || isempty(strfind('dataAcq',wb)) ) run('../utilities/initPaths.m'); end;

opts=struct('fsample',100,'nCh',4,'blockSize',5,'Cnames',[],...
				'stimEventRate',100,'queueEventRate',500,'keyboardEvents',true,'verb',-2,...
				'key2signal',true,'mouse2signal',true,'event2signal',true,'triggerType','sigprox.erp',...
				'sinFreq',10,'rednoise',1);
opts=parseOpts(opts,varargin);
if ( isempty(opts.Cnames) )
  opts.Cnames={};
  opts.Cnames{1}  ='erp';
  for i=2:opts.nCh-1; opts.Cnames{i}=sprintf('rand%02d',i); end;
  opts.Cnames{opts.nCh}=sprintf('sin%g',opts.sinFreq);
end

% N.B. from ft_fuffer/src/message.h: double -> ft type ID 10
hdr=struct('fsample',opts.fsample,'channel_names',{opts.Cnames(1:opts.nCh)},'nchans',opts.nCh,'nsamples',0,'nsamplespre',0,'ntrials',1,'nevents',0,'data_type',10);
buffer('put_hdr',hdr,host,port);
dat=struct('nchans',hdr.nchans,'nsamples',opts.blockSize,'data_type',hdr.data_type,'buf',[]);
simevt=struct('type','stimulus','value',0,'sample',[],'offset',0,'duration',0);
keyevt=struct('type','keyboard','value',0,'sample',[],'offset',0,'duration',0);

blockSize=opts.blockSize;
fsample  =opts.fsample;

% pre-build the ERP templates
erps      = zeros(round(fsample/2),4); 
erps(:,1) = exp(-(1:size(erps,1))*5./size(erps,1)); % exp
erps(:,2) = 1; % tophad
erps(:,3) = exp(-((1:size(erps,1))-size(erps,1)/2).^2./(size(erps,1)/3)); % gaussian
erps(:,4) = 0; % none
erps(:,1:3)=erps(:,1:3)./repmat(sum(abs(erps(:,1:3)),1),[size(erps,1),1]); % normalize to sum=1
erps=erps*size(erps,1); % erp averages amplitude 1/sample
erpSamp=inf(1,3);

%fprintf(stderr,'Scaling = [%s]\n',sprintf('%g ',scaling));
stopwatch=getwTime(); printtime=stopwatch; fstart=stopwatch;
% key listener
if ( opts.keyboardEvents || opts.key2signal ) 
  fig=figure(1);clf;
  set(fig,'name','SignalProxy: Press key here to generate events','menubar','none','toolbar','none');
  ax=axes('position',[0 0 1 1],'visible','off',...
			 'xlim',[0 1],'XLimMode','manual','ylim',[0 1],'ylimmode','manual','nextplot','add');
  set(fig,'Units','pixel');wSize=get(fig,'position'); fontSize = .05*wSize(4);
  text(.25,.5,{'Keyboard Events' 
					'-------'
					'0= noise amplitude 0' 
					'9= noise amplitude 9' 
					'a= sin amplitude 0'
					'z= sin amplitude 26'
					'E= exponential ERP' 
					'T= tophat ERP' 
					'G= gaussian ERP'
					'N= no ERP'
					sprintf('ERP trigger event type = %s',opts.triggerType)},...
		 'fontunit','pixels','fontsize',fontSize);
  % install listener for key-press mode change
  set(fig,'keypressfcn',@(src,ev) set(src,'userdata',ev)); set(fig,'userdata',[]);
  if ( exist('OCTAVE_VERSION','builtin') ) 
	 % BODGE: point to move around to update the plot to force key processing
	 set(ax,'nextplot','add');ph=plot(ax,.9,.1,'w'); 
    page_output_immediately(1); % prevent buffering output
    if ( ~isempty(strmatch('qthandles',available_graphics_toolkits())) )
      graphics_toolkit('qthandles'); % use fast rendering library
    elseif ( ~isempty(strmatch('fltk',available_graphics_toolkits())) )
      graphics_toolkit('fltk'); % use fast rendering library
    end
  end
end  
if ( opts.mouse2signal ) scrnSz=get(0,'ScreenSize'); end % scale by screensize
if ( opts.event2signal ) nEvents=-1; end;

scaling=ones(hdr.nchans,1); % used to adjust signal amplitude
nsamp=0; nblk=0; nevents=0;
dat.buf=zeros(hdr.nchans,blockSize);
noise  =zeros(size(dat.buf));
while( true )
  nblk=nblk+1;
  onsamp=nsamp; nsamp=nsamp+blockSize;
  % start with normal gaussian noise
  offset       = noise(:,end);
  noise        = randn(hdr.nchans,blockSize); 
  if( ~isempty(scaling) ) noise=noise.*repmat(scaling(1:size(dat.buf,1)),1,size(noise,2)); end;  
  % cumulative gaussian noise -> 1/f spectrum
  if ( opts.rednoise ) noise        = cumsum([offset+noise(:,1) noise(:,2:end)],2); end
  dat.buf       = noise;
  % sin signal in the last place
  dat.buf(end,:)= sin((onsamp+(1:blockSize))*2*pi*opts.sinFreq/hdr.fsample);
  if ( ~isempty(scaling) ) dat.buf(end,:) = dat.buf(end,:)*scaling(size(dat.buf,1)); end;
  % include the ERP
  for ei=1:numel(erpSamp);
    if ( erpSamp(ei)<nsamp && erpSamp(ei)+size(erps,1)>onsamp )
      erpIdx=min(size(erps,1),onsamp+1-erpSamp(ei)):min(size(erps,1),nsamp-erpSamp(ei));
      dat.buf(1,1:numel(erpIdx)) = dat.buf(1,1:numel(erpIdx))+erps(erpIdx,ei)';
    end
  end
  % sleep until the next data sample is due
  sendtime=(nblk*blockSize)./fsample; % time at which data should be sent, rel to start
  curtime =getwTime();                % current time
  %check for v.long gap between calls (missed at 10s data)=> suspend, so reset start time
  if ( curtime-fstart>sendtime+10 ) 
	 fprintf('Warning suspend detected, reset start time.\n\n');
    fstart=curtime-sendtime;
  end
  trem=max(0,sendtime-(curtime-fstart));sleepSec(trem);
  %if ( nsamp > hdr.fsample*10 ) keyboard; end;
  buffer('put_dat',dat,host,port);
  %fprintf('fstart=%g cur=%g send=%g ',fstart,curtime,sendtime);
  if ( opts.verb~=0 )
    if ( opts.verb>0 || (opts.verb<0 && curtime-printtime>-opts.verb) )
      fprintf('%d %d %d %f (blk,samp,event,sec)\r',nblk,nsamp,nevents,curtime-fstart);
      printtime=curtime;
    end
  end  
  if ( opts.stimEventRate>0 && mod(nblk,ceil(opts.stimEventRate/blockSize))==0 )
      % insert simulated events also
      nevents=nevents+1;
      simevt.value=ceil(rand(1)*2);simevt.sample=nsamp;
      buffer('put_evt',simevt,host,port);
  end
  if ( opts.queueEventRate>0 && mod(nblk,ceil(opts.queueEventRate/blockSize))==0 )
      % insert simulated events also
      nevents=nevents+1;
      simevt.value=sprintf('queue.%d',ceil(rand(1)*2));
      simevt.sample=nsamp; 
      buffer('put_evt',simevt,host,port);
  end
  %% record clock alignment information
  %tsamp(nblk)=nsamp; ttime(nblk)=buffer('get_time'); esamp(nblk)=buffer('get_samp'); 
  if ( opts.keyboardEvents || opts.key2signal )
    if ( ~ishandle(fig) ) break; end;
    ev=get(fig,'userdata');
    try; 
      h=char(ev.Character); 
	  if ( any(strcmp('shift',ev.Modifier)) ) h=upper(h); end;
    catch; 
      h=[];
    end;
    if ( ~isempty(h) )
      fprintf('\nkey=%s\n',h);
      if ( opts.keyboardEvents ) 
        keyevt.value=h; 
        keyevt.sample=nsamp;
        evt=buffer('put_evt',keyevt,host,port);
        fprintf('%d) evt=%s\n',nsamp,ev2str(evt));
      end
      switch h; % record start of ERP time
       case 'E'; erpSamp(1)=nsamp;
       case 'T'; erpSamp(2)=nsamp;
       case 'G'; erpSamp(3)=nsamp;
	   case 'N'; erpSamp(4)=nsamp;
       otherwise
        if ( opts.key2signal ) 
			  if ( single(h)>=single('0') && single(h)<=single('9') ) % number key = noise strength
				 scaling(1:end-1) = single(h)-single('0');
			  elseif ( single(h)>=single('a') && single(h)<=single('z') ) % letter key = sin strength
				 scaling(end)     = single(h)-single('a');
			  end
        end
      end
    end
  end
  if ( opts.mouse2signal ) 
    if ( exist('OCTAVE_VERSION','builtin') ) 
      pos=get(fig,'currentpoint'); % N.B. only updated when you *click*
    else
      pos=get(0,'PointerLocation');
    end
    if ( any(pos(:)>0) )
      scaling(2:3)=pos(:)'./scrnSz(3:4)*2;
    end
  end
  if ( opts.event2signal ) 
    [events,nEvents]=buffer_newevents(host,port,nEvents,opts.triggerType,[],0);
    for ei=1:numel(events); % treat as simulated key-press
      fprintf('%s\n',ev2str(events(ei)));
      evtval=events(ei).value;
      switch  evtval;
       case {'e','E',1,true}; erpSamp(1)=nsamp;
       case {'t','T',2};      erpSamp(2)=nsamp;
       case {'g','G',3};      erpSamp(3)=nsamp;
       case {'n','N',4};      erpSamp(4)=nsamp;
      end
    end
  end
  % N.B. due to a bug on OCTAVE we need to do this in the main loop to cause the display to re-draw...
  %  and allow us to update the mouse/keyboard information.
  set(fig,'userdata',[]); % mark any key's pressed as processed
  if ( mod(nblk,ceil(fsample/blockSize/2))==0 ) % re-draw 2x a second
	 % BODGE: move point to force key-processing
	 if ( exist('OCTAVE_VERSION','builtin') ) set(ph,'ydata',.1+rand(1)*.01); end
    drawnow;
    if ( ~ishandle(fig) ) break; end;
  end;
end
return;

function []=sleepSec(t)
if ( usejava('jvm') )
  javaMethod('sleep','java.lang.Thread',max(0,t)*1000);      
else
  pause(t);
end

function [t]=getwTime()
if ( usejava('jvm') )
  t=javaMethod('currentTimeMillis','java.lang.System')/1000;
else
  t=clock()*[0 0 86400 3600 60 1]';
end


%-------------
function testCase();
% start buffer server
buffer('tcpserver',struct(),'localhost',1972);
buffer_signalproxy('localhost',1972);
% now try reading data from it...
hdr=buffer('get_hdr',[],'localhost');
dat=buffer('get_dat',[],'localhost');

% generate data without making any events
buffer_signalproxy([],[],'stimEventRate',0,'queueEventRate',0,'verb',-100)
