try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end

buffhost='localhost';buffport=1972;
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
initgetwTime;
initsleepSec;

% ----------------------------------------------------------------------------
%    FILL IN YOUR CODE BELOW HERE
% ----------------------------------------------------------------------------

% useful functions
verb=0;
nSymbs=2;
nSeq=15;
nBlock=2;%10; % number of stim blocks to use
trialDuration=3;
baselineDuration=1;
intertrialDuration=2;

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

% make the stimulus
clf;
set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
set(gca,'visible','off','color',[0 0 0]); % black axes
% 2 targets at left/right of screen
stimPos=[]; h=[];
stimRadius=.5;
theta=linspace(0,pi,nSymbs); stimPos=[cos(theta);sin(theta)];
for hi=1:nSymbs; 
  h(hi)=rectangle('curvature',[1 1],'position',[stimPos(:,hi)-stimRadius/2;stimRadius*[1;1]],...
                  'facecolor',[0 0 0]); 
end;
% add symbol for the center of the screen
stimPos(:,nSymbs+1)=[0 0];
h(nSymbs+1)=rectangle('curvature',[1 1],'position',[stimPos(:,nSymbs+1)-stimRadius/4;stimRadius/2*[1;1]],...
                      'facecolor',[0 0 0]); 
set(gca,'visible','off');

% make the target symbol for epoch si green
set(h(tgtSeq(:,si)>0),'facecolor',[0 1 0]);
