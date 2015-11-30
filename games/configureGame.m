if ( exist('OCTAVE_VERSION') ) debug_on_error(1); else dbstop if error; end;
% guard to prevent running slow stuff multiple times
if ( ~exist('gameConfig','var') || ~isequal(gameConfig,true) ) 
  run ../utilities/initPaths.m;
  % wait for the buffer to return valid header information
  buffhost='localhost'; buffport=1972;
  hdr=[];
  while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
    try 
      hdr=buffer('get_hdr',[],buffhost,buffport); 
    catch
      fprintf('Waiting for header\n');
      hdr=[];
    end;
    pause(1);
  end;
  % set the RTC to use
  initgetwTime;  initsleepSec;
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
  gameConfig=true;
end
%capFile='cap_tmsi_mobita_p300';
keyboardControl=false;%true;%
  
%global dispState gameState;
verb=1;
buffhost='localhost'; buffport=1972;
zoomed   = false;
zoomedLim=[-4 4];

% BCI Stim Props
flashColor=[1 1 1]; % the 'flash' color (white)
tgtColor = [.8 .8 .8];
bgColor  = [.5 .5 .5];
tgt2Color= [1 0 0];
predColor= [0 1 0];
arrowScale=[.4 1.0];
sizeStim = 1.5;

% epoch timing info
stimType ='pseudorand';% 'ssvep'; %
isi      = 1/10;
nSymbs=4;
tti=.4; % target to target interval
vnSymbs=max(nSymbs,round(tti/isi)); % number virtual symbs used to generate the stim seq... adds occasional gaps
targetTime= ceil(.5/isi)*isi;
startDelay=0;
interTrialDelay=0;
% N.B. to get nReps data use: ((nReps+1)*isi+.6)
maxMoveInterval = ceil(6/isi)*isi; % move character every this long seconds
minMoveInterval = ceil(0.75/isi)*isi; % fastest possible is 1.5 sec
moveInterval    = maxMoveInterval;
speedupInterval = inf;moveInterval*4;
movePause       = .5;
pelletInterval  = 10;
nLives=1;
max_moves = 200;
level=1;

nTestSeq=12;
nBlock=2;%10; % number of stim blocks to use
seqDuration=ceil(5/(isi*nSymbs))*isi*nSymbs; % training sequence length (s)
nSeq = ceil(90/(seqDuration+targetTime+startDelay+interTrialDelay)); % 1.5 min for training?

predAlpha =[];%exp(log(.5)/10);%

snakeLevels={'snake1.lv' 'snake2.lv' 'snake2.lv'};
pacmanLevels={'vsml.lv' 'sml.lv' 'level1.lv'};
sokobanLevels={'soko1.lv' 'soko2.lv' 'soko3.lv'};


% speller config options
% the set of options the user will pick from
% symbols={'1'  '2'  '3';...
%          '4'  '5'  '6';...
%          '7'  '8'  '9'}';
symbols={'a'  'b'  'c' 'd' 'e';...
         'f'  'g'  'h' 'i' 'j';...
         'k'  'l'  'm' 'n' 'o';...
         'p'  'q'  'r' 's' 't';...
         'u'  'v'  'w' 'x' 'yz'}';
vnRows=max(size(symbols,1),ceil(tti/isi));
vnCols=max(size(symbols,2),ceil(tti/isi));
symbSize=.1;
interSeqDuration=2;
feedbackDuration=5;
nRepetitions=5;
stimDuration=isi;
trlen_ms=1000;
