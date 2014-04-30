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
%  nCh     - [int] number of simulated channels                (10)
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
%  verb           - [int] verbosity level.  If <0 then rate in samples to print status info (0)
if ( nargin<2 || isempty(port) ) port=1972; end;
if ( nargin<1 || isempty(host) ) host='localhost'; end;
wb=which('buffer'); if ( isempty(wb) || isempty(strfind('dataAcq',wb)) ) run('../utilities/initPaths.m'); end;

opts=struct('fsample',100,'nCh',3,'blockSize',5,'Cnames',[],'stimEventRate',100,'queueEventRate',500,'keyboardEvents',true,'verb',-2,'key2signal',true,'mouse2signal',true);
opts=parseOpts(opts,varargin);
if ( isempty(opts.Cnames) )
  opts.Cnames={'Cz' 'CPz' 'Oz'};
  for i=numel(opts.Cnames)+1:opts.nCh; opts.Cnames{i}=sprintf('rand%02d',i); end;
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
erps=zeros(round(fsample/2),3); 
erps(:,1) = exp(-(1:size(erps,1))*5./size(erps,1));                       erps(:,1)=erps(:,1)./sum(abs(erps(:,1)));
erps(:,2) = 1;                                                            erps(:,2)=erps(:,2)./sum(abs(erps(:,2)));
erps(:,3) = exp(-((1:size(erps,1))-size(erps,1)/2).^2./(size(erps,1)/3)); erps(:,3)=erps(:,3)./sum(abs(erps(:,3)));
erps=erps*size(erps,1); % erp averages amplitude 1/sample
erpSamp=inf(1,3);

nsamp=0; nblk=0; nevents=0; 
scaling=[0;ones(hdr.nchans-1,1)];
%fprintf(stderr,'Scaling = [%s]\n',sprintf('%g ',scaling));
tic;stopwatch=toc; printtime=stopwatch; fstart=stopwatch;
% key listener
if ( opts.keyboardEvents || opts.key2signal ) 
  fig=figure(1);clf;
  set(fig,'name','Press key here to generate events','menubar','none','toolbar','none');
  ax=axes('position',[0 0 1 1],'visible','off');
  text(.5,.5,{'Keyboard Events' '-------'...
              'space = amplitude 0' '0= amplitude 1' '9= amplitude 2' 'Z=amplitude 26'...
             'e = exponential ERP' 't=tophat ERP' 'g=gaussian ERP'});
  set(fig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character))); 
  if ( exist('OCTAVE_VERSION','builtin') ) 
    page_output_immediately(1); % prevent buffering output
    graphics_toolkit('fltk'); % use fast rendering library
  end
end  
if ( opts.mouse2signal ) scrnSz=get(0,'ScreenSize'); end % scale by screensize
while( true )
  nblk=nblk+1;
  onsamp=nsamp; nsamp=nsamp+blockSize;
  dat.buf = randn(hdr.nchans,blockSize);
  if ( ~isempty(scaling) ) dat.buf = dat.buf.*repmat(scaling(1:size(dat.buf,1)),1,size(dat.buf,2)); end;
  for ei=1:numel(erpSamp);
    if ( erpSamp(ei)<nsamp && erpSamp(ei)+size(erps,1)>onsamp )
      erpIdx=min(size(erps,1),onsamp+1-erpSamp(ei)):min(size(erps,1),nsamp-erpSamp(ei));
      dat.buf(1,1:numel(erpIdx)) = dat.buf(1,1:numel(erpIdx))+erps(erpIdx,ei)';
    end
  end
  % sleep so exactly blockSize/fsample between blocks
  trem=max(0,blockSize./fsample-(toc-fstart));sleepSec(trem);fstart=toc; 
  buffer('put_dat',dat,host,port);
  %fprintf('%g) trem=%g\n',toc-stopwatch,trem)
  if ( opts.verb~=0 )
    if ( opts.verb>0 || (opts.verb<0 && toc-printtime>-opts.verb) )
      fprintf('%d %d %d %f (blk,samp,event,sec)\r',nblk,nsamp,nevents,toc-stopwatch);
      printtime=toc;
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
    h=get(fig,'userdata');
    if ( ~isempty(h) && ischar(h) )
      fprintf('\nkey=%s\n',h);
      if ( opts.keyboardEvents ) 
        %tsamp(nblk)=nsamp; ttime(nblk)=buffer('get_time'); esamp(nblk)=buffer('get_samp'); 
        keyevt.value=h; 
        %keyevt.sample=nsamp;
        keyevt.sample=-1; % test the auto-filling code
        evt=buffer('put_evt',keyevt,host,port);
        fprintf('%d) evt=%s\n',nsamp,ev2str(evt));
      end
      switch lower(h); % record start of ERP time
       case 'e'; erpSamp(1)=nsamp;
       case 't'; erpSamp(2)=nsamp;
       case 'g'; erpSamp(3)=nsamp;
       otherwise
        if ( opts.key2signal ) 
          scaling(1) = max(1,single(h)-32)/10; % signal is integer value of the pressed key
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
  % N.B. due to a bug on OCTAVE we need to do this in the main loop to cause the display to re-draw...
  %  and allow us to update the mouse/keyboard information.
  set(fig,'userdata',[]); % mark any key's pressed as processed
  if ( mod(nblk,ceil(fsample/blockSize/4))==0 ) % re-draw 10x a second
    drawnow;
    if ( ~ishandle(fig) ) break; end;
  end;
end
return;

function []=sleepSec(t)
if ( exist('java')==2 )
  javaMethod('sleep','java.lang.Thread',max(0,t)*1000);      
else
  pause(t);
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
