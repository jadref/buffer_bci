configureCursor;
run ../utilities/initPTBPaths.m;
windowPos=[0 0 500 500]; % run in window

if( ~isempty(windowPos) ) Screen('Preference', 'SkipSyncTests', 1); end;

% get a good initial clock sync
buffer('sync_clock',[0:.5:10]);

% make the stimulus
% make the stimulus
ws=Screen('windows'); % re-use existing window 
if ( isempty(ws) )
  if ( IsLinux() ) PsychGPUControl('FullScreenWindowDisablesCompositor', 1); end % exclusive disp access in FS
  screenNum = max(Screen('Screens')); % get 2nd display
  wPtr= Screen('OpenWindow',screenNum,bgColor,windowPos)
  Screen('BlendFunction',wPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA); % enable alpha blending
  [flipInterval nrValid stddev]=Screen('GetFlipInterval',wPtr); % get flip-time (i.e. refresh rate)
  [width,height]=Screen('WindowSize',wPtr); 
else
  wPtr=ws(1);
end
% Now make the boxes
stimPos=[]; texels=[]; destR=[]; srcR=[];
stimRadius = .5/(nSymbs/2+1);
h=[];
for hi=1:nSymbs;
  theta=(hi-1)/nSymbs*2*pi; 
  x=cos(theta)*(1-stimRadius); y=sin(theta)*(1-stimRadius);
  x=x/2+1/2; y=y/2+1/2; % shift to relative units
  % N.B. PTB measures y from the top of the screen!  
  destR(:,hi)= round(rel2pixel(wPtr,[x-stimRadius/4,1-y-stimRadius/4,x+stimRadius/2,1-y+stimRadius/2]));
  srcR(:,hi) = [0 0 1 1];%destR(3,hi)-destR(1,hi) destR(4,hi)-destR(2,hi)];
  h(hi)      = Screen('MakeTexture',wPtr,ones(srcR([3 4],hi)')*255);
end
% fixation point
hi=nSymbs+1;
destR(:,hi)= round(rel2pixel(wPtr,[.5-stimRadius/4 .5+stimRadius/4 .5+stimRadius/4 .5-stimRadius/4]));
srcR(:,hi) = [0 0 1 1];%destR(3,hi)-destR(1,hi) destR(2,hi)-destR(4,hi)];
h(hi)      = Screen('MakeTexture',wPtr,ones(srcR([3 4],hi)')*255);

% instructions object
Screen('FillRect',wPtr,[0 0 0]*255); % blank background
[ans,ans,instructSrcR]=DrawFormattedText(wPtr,sprintf('%s\n',instructstr{:}),width/4,height/2,[1 1 1]*255);
Screen('flip',wPtr,1,1);
KbWait([],2,GetSecs()+5);

%% play the stimulus
sendEvent('stimulus.training','start');


%% Block 6 -- P300-90 @ 10hz
stimType = 'p3-90';
isi      = 1/10;
cursorCalibrationStimulusBlockPTB;


%% Block 1 - SSEP - LF @ 2Phase
isi      = 1/30;
stimType = 'ssep_2phase';
ssepFreq = [10 11+2/3 13+1/3 15 10 11+2/3 13+1/3 15];
ssepPhase= 2*pi*[0 0 0 0 .5 .5 .5 .5];
cursorCalibrationStimulusBlockPTB;

%% Block 2 - SSEP - HF @ 2phase
isi      = 1/60;
stimType = 'ssep_2phase';
ssepFreq = [20 23+1/3 26+2/3 30 20 23+1/3 16+2/3 30];
ssepPhase= 2*pi*[0 0 0 0 .5 .5 .5 .5];
cursorCalibrationStimulusBlockPTB;

%% Block 3 -- SSEP - LF+HF @ 1 phase
isi      = 1/60;
stimType = 'ssep';
ssepFreq = [8+2/3 10 11+2/3 13+1/3 15 16+2/3 18+1/3 20];
ssepPhase= 2*pi*[0 0 0 0 0 0 0 0];
cursorCalibrationStimulusBlockPTB;

%% Block 4 -- P300 Radial @ 10hz
stimType = 'p3-radial';
isi      = 1/10;
cursorCalibrationStimulusBlockPTB;

%% Block 5 -- P300 Radial @ 20hz
stimType = 'p3-radial';
isi      = 1/20;
cursorCalibrationStimulusBlockPTB;

%% Block 6 -- P300-90 @ 10hz
stimType = 'p3-90';
isi      = 1/10;
cursorCalibrationStimulusBlockPTB;

%% Block 7 -- P300-90 @ 20hz
stimType = 'p3-90';
isi      = 1/20;
cursorCalibrationStimulusBlockPTB;

%% Block 8 -- P300 @ 10hz
stimType = 'p3';
isi      = 1/10;
cursorCalibrationStimulusBlockPTB;

%% Block 9 -- P300 @ 20hz
stimType = 'p3';
isi      = 1/20;
cursorCalibrationStimulusBlockPTB;

%% Block 10 -- noise @ 10hz
stimType = 'noise';
isi      = 1/10;
cursorCalibrationStimulusBlockPTB;

%% Block 11 -- noise @ 20hz
stimType = 'noise';
isi      = 1/20;
cursorCalibrationStimulusBlockPTB;

%% Block 12 -- noise @ 30hz
stimType = 'noise';
isi      = 1/30;
cursorCalibrationStimulusBlockPTB;

%% Block 13 -- noise @ 60hz
stimType = 'noise';
isi      = 1/60;
cursorCalibrationStimulusBlockPTB;

%% Block 14 -- noise-psk @ 10hz
stimType = 'noise-psk';
isi      = 1/10;
cursorCalibrationStimulusBlockPTB;

%% Block 15 -- noise-psk @ 20hz
stimType = 'noise-psk';
isi      = 1/20;
cursorCalibrationStimulusBlockPTB;

%% Block 16 -- noise-psk @ 30hz
stimType = 'noise-psk';
isi      = 1/30;
cursorCalibrationStimulusBlockPTB;

%% Block 17 -- noise-psk @ 60hz
stimType = 'noise-psk';
isi      = 1/60;
cursorCalibrationStimulusBlockPTB;

%% end training marker
sendEvent('stimulus.training','end');
% show the end training message
Screen('FillRect',wPtr,[0 0 0]*255); % blank background
[ans,ans,instructSrcR]=DrawFormattedText(wPtr,sprintf('%s\n','That ends the training','thankyou for your patience'),0,0,[1 1 1]*255);
Screen('flip',wPtr,1,1);
KbWait([],2,GetSecs()+5);
if ( isempty(windowPos) ) Screen('closeall'); end; % close display if fullscreen
