configureIM;

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs+5,nSeq);
tgtSeq(1,:) = tgtSeq(1,:) + tgtSeq(11,:);
tgtSeq(3,:) = tgtSeq(3,:) + tgtSeq(12,:);
tgtSeq(5,:) = tgtSeq(5,:) + tgtSeq(13,:);
tgtSeq(7,:) = tgtSeq(7,:) + tgtSeq(14,:);
tgtSeq(10,:) = tgtSeq(10,:) + tgtSeq(15,:);
tgtSeq = tgtSeq([1:10],:);
%randp([0.134 0.066 0.134 0.066 0.134 0.066 0.134 0.066 0.066 0.134], 1, nSeq)



% make the stimulus
%figure;
fig=figure(2);
set(fig,'Name','Imagined Movement','color',[0 0 0],'menubar','none','toolbar','none','doublebuffer','on');
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');

stimPos=[]; h=[];
stimRadius=.5;
theta=linspace(0,1.75*pi,nSymbs-1); stimPos=[cos(theta);sin(theta)];
stimPos = [stimPos stimPos(:,3)];
%for hi=1:nSymbs; 
  %h(hi)=rectangle('curvature',[1 1],'position',[stimPos(:,hi)-stimRadius/2;stimRadius*[1;1]],...
  %                'facecolor',bgColor); 
%   h(1)= text(stimPos(1,1),stimPos(2,1),'Right Hand','HorizontalAlignment','center','FontSize',20);
%   h(2)= text(stimPos(1,2),stimPos(2,2),'Right Hand + Tongue','HorizontalAlignment','center','FontSize',20);
%   h(3)= text(stimPos(1,3),stimPos(2,3),'Tongue','HorizontalAlignment','center','FontSize',20);
%   h(4)= text(stimPos(1,4),stimPos(2,4),'Left Hand + Tongue','HorizontalAlignment','center','FontSize',20);
%   h(5)= text(stimPos(1,5),stimPos(2,5),'Left Hand','HorizontalAlignment','center','FontSize',20);
%   h(6)= text(stimPos(1,6),stimPos(2,6),'Left Hand + Feet','HorizontalAlignment','center','FontSize',20);
%   h(7)= text(stimPos(1,7),stimPos(2,7),'Feet','HorizontalAlignment','center','FontSize',20);
%   h(8)= text(stimPos(1,8),stimPos(2,8),'Right Hand + Feet','HorizontalAlignment','center','FontSize',20);
%   h(9)= text(stimPos(1,9),stimPos(2,9),'Left Hand + Right Hand','HorizontalAlignment','center','FontSize',20);
				  
%end;
% add symbol for the center of the screen
% stimPos(:,nSymbs+1)=[0 0];
%h(nSymbs+1)=rectangle('curvature',[1 1],'position',[stimPos(:,nSymbs+1)-stimRadius/4;stimRadius/2*[1;1]],...
%                      'facecolor',bgColor); 
% h(nSymbs+1) = text(stimPos(1,nSymbs+1),stimPos(2,nSymbs+1),'+','HorizontalAlignment','center','FontSize',30);
set(gca,'visible','off');

%Create a text object with no text in it, center it, set font and color
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',[0.75 0.75 0.75],'visible','off');

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'color',bgColor,'visible','off');
sendEvent('stimulus.training','start');

set(txthdl,'string', 'Click mouse when ready', 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;

for si=1:nSeq;

  if ( ~ishandle(fig) ) break; end;
  sleepSec(intertrialDuration);
  % show the screen to alert the subject to trial start
  tgtId = find(tgtSeq(:,si)>0);
 % set(txthdl,'color',fixColor,'visible','on'); % red fixation indicates trial about to start/baseline
%   set(h(tgtSeq(:,si)>0),'color',fixColor,'visible','on');
  set(txthdl,'string',conditions{tgtId},'color',fixColor,'visible','on');
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');
  
  
  % show the target
  fprintf('%d) tgt=%d : ',si,find(tgtSeq(:,si)>0));
  set(txthdl ,'color',tgtColor, 'visible', 'on');
  %set(h(tgtSeq(:,si)<=0),'color',bgColor, 'visible', 'off');
  %set(h(end),'color',[0 1 0],'visible','on'); % green fixation indicates trial running
  sendEvent('stimulus.target',conditions{tgtId});
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.trial','start');
  % wait for trial end
  sleepSec(trialDuration);
  
  % reset the cue and fixation point to indicate trial has finished  
  set(txthdl ,'color',bgColor,'visible','off');
  drawnow;
  sendEvent('stimulus.trial','end');
  
  ftime=getwTime();
  fprintf('\n');
end % sequences
% end training marker
sendEvent('stimulus.training','end');

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'That ends the training phase.','Thanks for your patience'}, 'visible', 'on', 'color',[0 1 0]);
pause(3);
end
