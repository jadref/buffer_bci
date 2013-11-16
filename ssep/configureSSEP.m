% guard to prevent running multiple times
if ( exist('runConfig','var') && ~isempty(runConfig) ) return; end;
runConfig=true;
run ../utilities/initPaths;

buffhost='localhost';buffport=1972;
global ft_buff; ft_buff=struct('host',buffhost,'port',buffport);
% wait for the buffer to return valid header information
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

% set the real-time-clock to use
initgetwTime();
initsleepSec();

capFile='1010'; %'emotiv';%cap_tmsi_mobita_im2'; N.B. use 1010 for emotiv so non-eeg are labelled correctly
verb=0;
buffhost='localhost';
buffport=1972;

verb=0;
nSeq=15;
nRepetitions=5;  % the number of complete row/col stimulus before sequence is finished
cueDuration=2;
stimDuration=.15;% the length a row/col is highlighted
interSeqDuration=2;
feedbackDuration=5;
stimRadius=.6;

nSymbs=2;
trialDuration=3;
baselineDuration=1;
intertrialDuration=2;
isi = 2/60;
periods=[2 4];
bgColor=[.1 .1 .1]; % background color (grey)
tgtColor=[0 1 0]; % the target indication color (green)
flashColor=[1 1 1]; % the 'flash' color (white)
fixColor=[1 0 0];
trlen_ms=trialDuration*1000;
