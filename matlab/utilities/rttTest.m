run ../utilities/initPaths.m
global getwTime; getwTime=[];initgetwTime;
buffhost='localhost';buffport=1972;
if ( 1 )
% put a fake header so we don't need a signal proxy to proceed
hdr=struct('fsample',100,'channel_names',{{'Cz'}},'nchans',1,'nsamples',0,'nsamplespre',0,'ntrials',1,'nevents',0,'data_type',10);
buffer('put_hdr',hdr,buffhost,buffport);
end
if ( 1 )
  global rtclockmb rtclockrecord;
  [rtclockmb,rtclockrecord]=buffer_alignrtClock();
end

[ans,ans,ans,opts]=buffer_waitData([],[],[],'exitSet',{{'heartbeat'}},'verb',0,'getOpts',1);
wt=[];et=[];st=[];
for i=1:100;
status=buffer('wait_dat',[-1 -1 -1]);
se(i)=status.nevents;
st(i)=getwTime();sendEvent('heartbeat',i);
if ( 0 )
  newstatus=buffer('wait_dat',[-1 status.nevents 1000]); wt(i)=getwTime(); %status.nevents
  evt=buffer('get_evt',[status.nevents newstatus.nevents-1]); et(i)=getwTime();
  ne(i)=newstatus.nevents;
else
  wt(i)=getwTime();
  [ans,evt]=buffer_waitData([],[],[-1 status.nevents 1000],opts);%'exitSet',{{'heartbeat'}},'verb',0);
  %[ans,evt]=buffer_waitData([],[],[],'exitSet',{{'heartbeat'}},'verb',0);
  et(i)=getwTime();
end
ev(i)=evt.value;
pause(.1);
end
fprintf('(2-1)=%8.3fms  (3-1)=%8.3fms\n',mean(wt-st)*1000,mean(et-st)*1000);
clf;plot([wt-st;et-st]'*1000);legend('wd-start','et-start');
