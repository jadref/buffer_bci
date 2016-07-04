run ../utilities/initPaths.m
initsleepSec;

fixateDuration   = 3;
eyesDuration     = 30;
artifactDuration = 10;
interArtifactDuration=2;
eyeColor         = [.8 .1 0];
muscleColor      = [.8 .1 0];


% make the stimulus
%figure;
fig=figure(2);
set(fig,'Name','Artifact Calibration','color',[0 0 0],'menubar','none','toolbar','none','doublebuffer','on');
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');
    
h=[];
% draw stimulus: noise (eye movement)
h(1,3) = rectangle('position',[-.15 -.1 0.15*2 .1*2],'curvature',[1 1],'LineWidth',4,'faceColor',eyeColor,'EdgeColor',eyeColor);
h(2,3) = rectangle('position',[-.05 -.05 0.1 0.1],'curvature',[1 1],'LineWidth',4,'FaceColor',[0 0 0],'EdgeColor',eyeColor);
% draw stimulus: noise (Jaw clench)
h(1,4) = rectangle('position',[-.15 -.05 .15*2 0.1],'curvature',[1 1],'LineWidth',4,'faceColor',muscleColor,'EdgeColor',muscleColor);
h(2,4) = line([-.15 .15],[0 0],'LineWidth',4,'Color',[0 0 0]);
% draw stimulus: noise (eyes shut)
h(1,5) = rectangle('position',[-.15 -.1 0.15*2 0.1*2],'curvature',[1 1],'LineWidth',4,'FaceColor',eyeColor,'EdgeColor',eyeColor);

	% draw stimulus: fixation cross
h(1,6) = line([-0.1 0.1], [0 0],'Color','w','LineWidth',4);
h(2,6) = line([0 0], [-0.1 0.1],'Color','w','LineWidth',4);

% draw stimulus: fixate dots
fixatePos = [.0 .0;... % Middle
             -1 -1;... % Left Bottom
             -1  1;... % Left Top
              1 -1;... % Right Bottom 
              1  1];   % Right Top
for fi=1:size(fixatePos,1);
   h(fi,8) = rectangle('position',[fixatePos(fi,:) 0.02 0.02],'curvature',[1 1],...
                       'LineWidth',4,'FaceColor',eyeColor,'EdgeColor',eyeColor);
end

set(gca,'visible','off');
%Create a text object with no text in it, center it, set font and color
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',[0.75 0.75 0.75],'visible','off');

sendEvent('stimulus.artifactcalibration','start');

%------------------------------------------------------------------------
% Start with eyes moving to different fixatation locations
set(h(:),'visible','off');               
set(txthdl,'string', {'Eyemovements.  Look at the highlighted point' 'as it moves round the screen' '' 'Click mouse when ready'}, 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;              


fixateSeq=mkStimSeqRand(4,8); % make the fixatation location sequence

sendEvent('stimulus.baseline.eyesmove','start');
set(h(1,8),'visible','on');
sendEvent('stimulus.baseline.fixate',fixatePos(1,:));
drawnow;
sleepSec(fixateDuration);
set(h(:),'visible','off');drawnow;
for si=1:8;
   fixIdx = find(fixateSeq(:,si))+1;
   set(h(fixIdx,8),'visible','on');
   drawnow;
   sendEvent('stimulus.baseline.fixate',fixatePos(fixIdx,:));    
   fprintf('.');
   sleepSec(fixateDuration);
   set(h(:),'visible','off'); drawnow;
end
set(h(1,8),'visible','on');drawnow;
sendEvent('stimulus.baseline.fixate',fixatePos(1,:));
sleepSec(fixateDuration);
set(h(:),'visible','off');drawnow;
sendEvent('stimulus.baseline.eyesmove','end');


set(h(:),'visible','off');              
set(txthdl,'string', {'Artifact Generation' 'Create the indicated artifact' 'as instructed' '' 'Click mouse when ready'}, 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;

%------------------------------------------------------------------------
% 30 sec of eyes-open and fixatated
set(h(:),'visible','off');
set(h(1,6),'visible','on');
set(h(2,6),'visible','on');
set(txthdl,'string', {'' '' 'eyes open'}, 'visible', 'on'); 
drawnow;
sendEvent('stimulus.baseline.eyesopen','start');
sleepSec(eyesDuration);
sendEvent('stimulus.baseline.eyesopen','end');
set(h(:),'visible','off');
set(txthdl,'visible','off');
drawnow

sleepSec(interArtifactDuration);

%------------------------------------------------------------------------
% 30 sec of eyes closed
set(h(:),'visible','off');
set(h(1,5),'visible','on'); 
set(txthdl,'string', {'' '' 'eyes closed'}, 'visible', 'on');
drawnow;
sendEvent('stimulus.baseline.eyesclosed','start');
sleepSec(eyesDuration);
sendEvent('stimulus.baseline.eyesclosed','end');
sound(1);
set(h(:),'visible','off');
set(txthdl,'visible','off');
drawnow

sleepSec(interArtifactDuration);

%------------------------------------------------------------------------
% eye blinking 15 sec
set(h(:),'visible','off');
set(h(1,3),'visible','on');
set(h(2,3),'visible','on');
set(txthdl,'string', {'' '' 'blink'}, 'visible', 'on');
drawnow;
sendEvent('artifact.blink','start');
sleepSec(artifactDuration);
sendEvent('artifact.blink','end');
set(h(:),'visible','off');
set(txthdl,'visible','off');
drawnow

sleepSec(interArtifactDuration);

%------------------------------------------------------------------------
% jaw clench
set(h(:),'visible','off');
set(h(1,4),'visible','on');
set(h(2,4),'visible','on');
set(txthdl,'string', {'' '' 'jaw clench'}, 'visible', 'on');
drawnow;
sendEvent('artifact.jaw','start');
sleepSec(artifactDuration);
sendEvent('artifact.jaw','end');
set(h(:),'visible','off');
set(txthdl,'visible','off');
drawnow

sleepSec(interArtifactDuration);

%------------------------------------------------------------------------
% eye blinking
set(h(:),'visible','off');
set(h(1,3),'visible','on');
set(h(2,3),'visible','on');
set(txthdl,'string', {'' '' 'blink'}, 'visible', 'on');
drawnow;
sendEvent('artifact.blink','start');
sleepSec(artifactDuration);
sendEvent('artifact.blink','end');
set(h(:),'visible','off');
set(txthdl,'visible','off');
drawnow

sleepSec(interArtifactDuration);

%------------------------------------------------------------------------
% jaw clench
set(h(:),'visible','off');
set(h(1,4),'visible','on');
set(h(2,4),'visible','on');
set(txthdl,'string', {'' '' 'jaw clench'}, 'visible', 'on');
drawnow;
sendEvent('artifact.jaw','start');
sleepSec(artifactDuration);
sendEvent('artifact.jaw','end');
set(h(:),'visible','off');
set(txthdl,'visible','off');
drawnow

sleepSec(interArtifactDuration);

%------------------------------------------------------------------------
% 30 sec of fixation
set(h(:),'visible','off');
set(h(1,6),'visible','on');
set(h(2,6),'visible','on');
set(txthdl,'string', {'' '' 'eyes open'}, 'visible', 'on');
drawnow;
sendEvent('stimulus.baseline.eyesopen','start');
sleepSec(eyesDuration);
sendEvent('stimulus.baseline.eyesopen','end');
set(h(:),'visible','off');
set(txthdl,'visible','off');
drawnow

%------------------------------------------------------------------------
sendEvent('stimulus.artifactcalibration','end');

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'That ends the training phase.','Thanks for your patience'}, 'visible', 'on', 'color',[0 1 0]);
pause(3);
end
