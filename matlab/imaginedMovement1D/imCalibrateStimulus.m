configureIM;

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

% make the stimulus
%figure;
fig=figure(2);
set(fig,'Name','Imagined Movement','color',[0 0 0],'menubar','none','toolbar','none','doublebuffer','on');
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');

set(gca,'visible','off');
%Create a text object with no text in it, center it, set font and color
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',[0.75 0.75 0.75],'visible','off');

% play the stimulus
sendEvent('stimulus.training','start');

set(txthdl,'string', 'Click mouse when ready', 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;

for si=1:nSeq;
  if ( ~ishandle(fig) ) break; end;
  % show the screen to alert the subject to trial start
  tgtId = find(tgtSeq(:,si)>0);
  % show the target
  fprintf('%d) tgt=%d : ',si,find(tgtSeq(:,si)>0));
  set(txthdl ,'string',conditions{tgtId},'color',tgtColor, 'visible', 'on');
  sendEvent('stimulus.target',conditions{tgtId});
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.trial.continuous','start');
  % wait for trial end
  sleepSec(trialDuration);
  % reset the cue and fixation point to indicate trial has finished  
  sendEvent('stimulus.trial.continuous','end');
  ftime=getwTime();
  fprintf('\n');
  if(mod(si,nGroup) == 0)
      set(txthdl,'string', 'Press any key to continue', 'color',bgColor,'visible', 'on'); drawnow;
      waitforbuttonpress;
      set(txthdl,'visible', 'off'); drawnow;
  end
end % sequences

% end training marker
sendEvent('stimulus.training','end');

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'That ends the training phase.','Thanks for your patience'}, 'visible', 'on', 'color',[0 1 0]);
pause(3);
end
