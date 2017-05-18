% setup so we can send buffer events...
addtopath('~/projects/bci/buffer_bci','dataAcq','bciLoop','utilities','signalProc',fullfile('dataAcq','buffer'));
buffhost='localhost';buffport=1972;
initgetwTime;  initsleepSec;
global rtclockmb rtclockrecord;
[rtclockmb,rtclockrecord]=buffer_alignrtClock([],[.2 .4],buffhost,buffport);
