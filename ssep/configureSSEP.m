% guard to prevent running multiple times
if ( ~exist('configured','var') || ~isequal(configured,true) )
  run ../utilities/initPaths.m;
  run ../utilities/initPTBPaths.m;

  buffhost='localhost';buffport=1972;
  global ft_buff; ft_buff=struct('host',buffhost,'port',buffport);
  % wait for the buffer to return valid header information
  hdr=[];
  while ( isempty(hdr) || ~isstruct(hdr) ) % wait for the buffer to contain valid data
    try 
      hdr=buffer('get_hdr',[],buffhost,buffport); 
    catch
      hdr=[];
      fprintf('Invalid header info... waiting.\n');
    end;
    pause(1);
  end;

  % set the real-time-clock to use
  initgetwTime;
  initsleepSec;
  
  if ( exist('OCTAVE_VERSION') ) % use fast render pipeline in OCTAVE
    graphics_toolkit('fltk');
  end
  configured=true;
end

capFile='cap_tmsi_mobita_black';%'1010'; %'emotiv';%cap_tmsi_mobita_im2'; N.B. use 1010 for emotiv so non-eeg are labelled correctly
% set cap-fitting and position information thresholds
thresh=[.5 3];  badchThresh=.5;   overridechnms=0;
if ( ~exist('capFile','var') ) capFile='1010'; 
else %'cap_tmsi_mobita_num'; 
    overridechnms=1;
    if ( ~isempty(strfind(capFile,'tmsi')) ) thresh=[.0 .1 .2 5]; badchThresh=1e-4;  end;
end

verb=0;
buffhost='localhost';
buffport=1972;

verb=0;
nSeq=6;
seqLen=15;
cueDuration=2;
feedbackDuration=5;
stimRadius=.3;

trialDuration=3;
baselineDuration=1;
rtbDuration=1;
intertrialDuration=2;
isi = 1/60;
periods=[3 3 4 4;...  % periods
         0 1 0 2]';   % phases
classes={};
for ci=1:size(periods,1);
  classes{ci} = sprintf('%gHz_%gdeg',1./(periods(ci,1)*isi),periods(ci,2)/periods(ci,1)*360);
end
nSymbs=size(periods,1);
bgColor=[.1 .1 .1]; % background color (grey)
tgtColor=[0 1 0]; % the target indication color (green)
flashColor=[1 1 1]; % the 'flash' color (white)
fixColor=[1 0 0];
trlen_ms=trialDuration*1000;

% PTB stuff
windowPos=[];%[0 0 500 500];%[0 0 1024 1024];% % in sub-window set to [] for full screen