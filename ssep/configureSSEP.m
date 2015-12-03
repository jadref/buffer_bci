% guard to prevent running multiple times
if ( ~exist('configured','var') || ~isequal(configured,true) )
  run ../utilities/initPaths.m;
  run ../utilities/initPTBPaths.m;

  buffhost='localhost';buffport=1972;
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
	 page_output_immediately(1); % prevent buffering output
	 if ( ~isempty(strmatch('qt',available_graphics_toolkits())) )
		graphics_toolkit('qt'); 
	 elseif ( ~isempty(strmatch('qthandles',available_graphics_toolkits())) )
		graphics_toolkit('qthandles'); 
	 elseif ( ~isempty(strmatch('fltk',available_graphics_toolkits())) )
		graphics_toolkit('fltk'); % use fast rendering library
	 end
  end
  configured=true;
end

verb=0;
buffhost='localhost';
buffport=1972;

verb=0;
nSeq=4;
seqLen=12;
cueDuration=2;
feedbackDuration=3;
stimRadius=.3;

trialDuration=3;
baselineDuration=1;
rtbDuration=1;
intertrialDuration=2;
isi = 1/30;
periods=[3 4 5 6;...  % periods, in frames
         0 1 0 2]';   % phases, in frames (N.B. not used in ERSP analysis!)
periods= periods*isi; % convert from frames to seconds - as mkStimSeqSSEP wants
classes={};
for ci=1:size(periods,1);
  classes{ci} = sprintf('%gHz_%gdeg',1./(periods(ci,1)),periods(ci,2)/periods(ci,1)*360);
end
nSymbs=size(periods,1);
bgColor=[.3 .3 .3]; % background color (grey)
tgtColor=[0 1 0]; % the target indication color (green)
flashColor=[1 1 1]; % the 'flash' color (white)
fixColor=[1 0 0];
feedbackColor=[0 0 1]; % feedback (blue)

% classifier trianing system options
trlen_ms=trialDuration*1000;
trainOpts={'freqband',[0 1  45 47],'width_ms',1500}; % sig-proc/classifier training options

instructstr={'Look at the box indicated' 'in green' '' 'click mouse to continue'};
thanksstr  ={'That ends this phase.' '' 'click mouse to continue'};
feedbackinstructstr={'Look at your choosen box.' 'feedback given at sequence' 'end in blue' '' 'click mouse to continue'};


% PTB stuff
windowPos=[0 0 500 500];%[];%[0 0 1024 1024];% % in sub-window set to [] for full screen
