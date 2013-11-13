function [mb,record,nsamples,ftime]=buffer_alignrtClock(record,wait,host,port,seedfs)
% align this computers *real-time-clock* with sample clock of the remote buffer
%
% [mb,record,nsamples,ftime]=buffer_alignrtClock(record,wait,host,port,seedfs)
global ft_buff;
if ( nargin<1 ) record=[]; end;
if ( nargin<2 ) wait=[]; if( numel(record)==1 ) wait=record; record=[]; end; end;
if ( nargin<3 || isempty(host) ) 
  if ( ~isempty(ft_buff) ) host=ft_buff.host ; else host='localhost'; end; 
end
if ( nargin<4 || isempty(port) ) 
  if ( ~isempty(ft_buff) ) port=ft_buff.port ; else port=1972; end;
end
if ( nargin<5 ) seedfs=[]; end;
if ( numel(wait)<1 )     wait=ones(2/.05,1)*.05; % 2 sec alignment
elseif( numel(wait)==1 ) wait=.05*ones(wait,1);
end
if ( wait(end)>0 ) wait=[wait(:);0]; end% add one at the end
try; 
  status(1) = buffer('wait_dat',[-1 -1 -1],host,port);
  ftime(1)=getwTime();
catch
  error('No samples available from the buffer!  Have you connected the amplifier/signalProxy?');
end
pause(wait(1));
for wi=2:numel(wait);
  status(wi)=buffer('wait_dat',[-1 -1 -1],host,port);
  if (status(wi).nsamples<=status(wi-1).nsamples) 
    warning('No new samples! Is the amplifier connected?');
  end
  ftime(wi)=getwTime();
  pause(wait(wi));
end
nsamples=[status.nsamples];
if ( nsamples(end)==nsamples(1) ) 
  error('No new samples! Is the amplifier connected?');
end
if ( ~isempty(seedfs) ) % seed with default value for sample-rate, but est intercept
  mb = [seedfs 0]; mb(2) = mean(nsamples-ftime*mb(1));
  seedTs=ftime(1)+(1:25); [mb,record]=updateClocks(record,mb(2)+seedTs*mb(1),seedTs);
else % est both
  [mb,record]=updateClocks(record,nsamples,ftime);
end
return;

%-----------------
function testCase();
% in another matlab
buffer('tcpserver',struct(),'localhost',1972);
ft_buffer_signalproxy('localhost',1972);
% in this matlab
record=[];
[mb,record]=buffer_alignrtClock([],[],record,1:10)

% check the alignment
wait=[0;ones(1000,1)*.05];
ftime=[];nsamples=[];
for wi=1:numel(wait);
  status=buffer('wait_dat',[-1 -1 -1]); nsamples(wi)=status.nsamples;
  ftime(wi)=getwTime();
  pause(wait(wi));
end

status=buffer('wait_dat',[-1 -1 -1]);status.nsamples-getsampTime()

% init and check
%[rtclockmb rtclockrecord nsamples0 ftime0]=buffer_alignrtClock(150);
%clf;plot([ftime ftime0],[nsamples'-getsampTime(ftime)'; nsamples0'-getsampTime(ftime0)']),sum([nsamples'-getsampTime(ftime)'])

wait=[0;ones(100,1)*.05];
btimen=[]; wtimen=[];
for wi=1:numel(wait);
  status=buffer('wait_dat',[-1 -1 -1]); btimen(wi)=status.nsamples;
  wtimen(wi)=getwTime();
  pause(wait(wi));
end
clf;plot([btime btimen],[btime-getsampTime(wtime) btimen-getsampTime(wtimen)])
sum([btime-getsampTime(wtime)]),sum(btimen-getsampTime(wtimen))


% now try sending an event
for i=1:20;
  evt=struct('type','sim','value',i,'sample',now()*mb(1)+mb(2),'offset',0,'duration',0);
  buffer('put_evt',evt);
  pause(.1);
end
evt=buffer('get_evt',[]);
evt=buffer('get_evt',[20 20]); % only get the last event added


% try again
for i=1:90;     
  status=buffer('wait_dat',[-1 -1 -1],buffhost,buffport); % get current state
  stime =getwTime(); 
  if ( (stime-clockUpdateTime)>clockUpdateInterval ) % keep the clock sync
    [rtclockmb rtclockrecord]=updateClocks(rtclockrecord,status.nsamples,stime); 
    clockUpdateTime=stime;
    fprintf('*');
  end
  pause(1); 
  status=buffer('wait_dat',[-1 -1 -1]);btime(i)=status.nsamples; 
  ctime(i)=getsampTime(); 
  fprintf('%d) %g - %g = %g\n',i,btime(i),ctime(i),btime(i)-ctime(i)); 
end;
