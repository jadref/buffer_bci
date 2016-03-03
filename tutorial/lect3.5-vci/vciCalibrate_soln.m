try; cd(fileparts(mfilename('fullpath')));catch; end;
run ../../utilities/initPaths.m

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

% make the target sequence
conditions={'yes' 'no'};
nSeq      =30; % 30 training examples, 15=yes, 15=no

% trial =  baseline -> cue+task -> pause -> repeat
baselineDuration=1;
baselineColor   =[1 0 0]; % red in baseline
trialDuration  =1.5;
trialColor      =[.7 .7 .7]; % grey during trial
interTrialDuration=2; % off in gaps

instructstr={'Say the cued word clearly' 'when indicated.' ' ' 'Press mouse to start.'};

% make the stimulus
fig=figure(1);
clf;
set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
set(gca,'visible','off','color',[0 0 0]); % black axes
% simple text object in the middle of the display
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');
h=text(.5,.5,'text','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','pixel','fontsize',.07*wSize(4),'color',[1 1 1],'visible','off'); 

% show the instructions and wait for key press to start
set(h,'string',instructstr,'color',[1 1 1],'visible','on');
drawnow;
waitforbuttonpress;

% make the target sequence
tgtSeq = 1:numel(conditions); % make a target code
tgtSeq = repmat(tgtSeq(:),ceil(nSeq/numel(conditions)),1); % copy until have nSeq
tgtSeq = tgtSeq(1:nSeq); % enusre exactly nSeq
% randomize the order. Note: should really ensure is *perceptually* random....
tgtSeq = tgtSeq(randperm(nSeq));

% play the stimulus
sendEvent('stimulus.calibrate','start');
for si=1:nSeq;
  % get the target ID for this trail, and the cue
  tgtId = tgtSeq(si);
  tgt   = conditions{tgtId};
      
  % show the baseline text.
  set(h,'string','+','visible','on','color',baselineColor);
  drawnow;
  sendEvent('stimulus.baseline','start'); % event say the trial type
  sleepSec(baselineDuration);

  % show the target to start the trial.
  set(h,'string',tgt,'visible','on','color',trialColor);
  drawnow;
  sendEvent('stimulus.target',tgt); % event say the trial type
  sleepSec(trialDuration);

  % turn off the stimuli for the inter-trial
  set(h,'string','+','visible','off');
  drawnow;
  sleepSec(interTrialDuration);
      
end % sequences

% send event to say that calibration has finished
sendEvent('calibrate','end');

% tell user we're done
msg=msgbox({'Thanks for taking part!'},'Continue?');while ishandle(msg); pause(.2); end;
