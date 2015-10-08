dbstop if error;
initPaths;
configureGame;

% put a fake header so we don't need a signal proxy to proceed
hdr=struct('fsample',100,'channel_names',{{'Cz'}},'nchans',1,'nsamples',0,'nsamplespre',0,'ntrials',1,'nevents',0,'data_type',10);
buffer('put_hdr',hdr,buffhost,buffport);

sendEvent('startPhase.cmd','capFitting');

sendEvent('startPhase.cmd','calibrate')
offlineStimTest

sendEvent('startPhase.cmd','training');

sendEvent('startPhase.cmd','testing');
tic
onlineStimTest;
toc

sendEvent('startPhase.cmd','testing');
pacman


sendEvent('startPhase.cmd','testing');
snake

sendEvent('startPhase.cmd','testing');
sokoban

% shut down the sigproc
sendEvent('startPhase.cmd','exit');
