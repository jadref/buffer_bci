configureIM;

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

% make the stimulus
%figure;
fig=figure(2);
set(fig,'Name','Imagined Movement','color',winColor,'menubar','none','toolbar','none','doublebuffer','on');
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',winColor,'DrawMode','fast','nextplot','replacechildren',...
        'xlim',axLim,'ylim',axLim,'Ydir','normal');

stimPos=[]; h=[]; htxt=[];
stimRadius=diff(axLim)/4;
cursorSize=stimRadius/2;
theta=linspace(0,2*pi,nSymbs+1);
if ( mod(nSymbs,2)==1 ) theta=theta+pi/2; end; % ensure left-right symetric by making odd 0=up
theta=theta(1:end-1);
stimPos=[cos(theta);sin(theta)];
for hi=1:nSymbs; 
  h(hi)=rectangle('curvature',[1 1],'position',[stimPos(:,hi)-stimRadius/2;stimRadius*[1;1]],...
                  'facecolor',bgColor); 
  %if ( ~isempty(symbCue) ) % cue-text
	% htxt(hi)=text(stimPos(1,hi),stimPos(2,hi),symbCue{hi},...
	%					'HorizontalAlignment','center','color',[.1 .1 .1],'visible','on');
  %end  
end;
% add symbol for the center of the screen
stimPos(:,nSymbs+1)=[0 0];
h(nSymbs+1)=rectangle('curvature',[1 1],'position',[stimPos(:,nSymbs+1)-cursorSize/2;cursorSize*[1;1]],...
                      'facecolor',bgColor); 
set(gca,'visible','off');

%Create a text object with no text in it, center it, set font and color
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','off');

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'facecolor',bgColor);
sendEvent('stimulus.training','start');

set(txthdl,'string', 'Click mouse when ready', 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;

for si=1:nSeq;

  if ( ~ishandle(fig) ) break; end;

  sleepSec(intertrialDuration);
  % show the screen to alert the subject to trial start
  set(h(end),'facecolor',fixColor); % red fixation indicates trial about to start/baseline
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  if ( ~isempty(baselineClass) ) % treat baseline as a special class
	 sendEvent('stimulus.target',baselineClass);
  end
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');
  
  
  % show the target
  tgtIdx=find(tgtSeq(:,si)>0);
  set(h(tgtSeq(:,si)>0),'facecolor',tgtColor);
  set(h(tgtSeq(:,si)<=0),'facecolor',bgColor);
  if ( ~isempty(symbCue) )
	 set(txthdl,'string',sprintf('%s ',symbCue{tgtIdx}),'color',txtColor,'visible','on');
	 tgtNm = '';
	 for ti=1:numel(tgtIdx);
		if(ti>1) tgtNm=[tgtNm ' + ']; end;
		tgtNm=sprintf('%s%d %s ',tgtNm,tgtIdx,symbCue{tgtIdx});
	 end
  else
	 tgtNm = tgtIdx; % human-name is position number
  end
  set(h(end),'facecolor',[0 1 0]); % green fixation indicates trial running
  fprintf('%d) tgt=%10s : ',si,tgtNm);
  sendEvent('stimulus.target',tgtNm);
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.trial.cued','start');
  % wait for trial end
  sleepSec(trialDuration);
  
  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'facecolor',bgColor);
  if ( ~isempty(symbCue) ) set(txthdl,'visible','off'); end
  drawnow;
  sendEvent('stimulus.trial.cued','end');
  
  ftime=getwTime();
  fprintf('\n');
end % sequences
% end training marker
sendEvent('stimulus.training','end');

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'That ends the training phase.','Thanks for your patience'}, 'visible', 'on', 'color',[0 1 0]);
pause(3);
end
