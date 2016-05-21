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

h=[];

% draw stimulus: MI task arrow (right)
h(1,4) = annotation(gcf,'arrow',[0.65 0.75],[0.5 0.5],'HeadLength',30,'HeadWidth',40,...
    'HeadStyle','plain','LineWidth',4,'Color',[1 1 1]);
% draw stimulus: MI task arrow (left)
h(1,5) = annotation(gcf,'arrow',[0.35 0.25],[0.5 0.5],'HeadLength',30,'HeadWidth',40,...
    'HeadStyle','plain','LineWidth',4,'Color',[1 1 1]);
% draw stimulus: fixation cross
h(1,6) = line([-0.2 0.2], [0 0],'Color','w','LineWidth',4);
h(2,6) = line([0 0], [-0.2 0.2],'Color','w','LineWidth',4);
% draw stimulus: MI feedback arrow (right)
h(1,1) = annotation(gcf,'arrow',[0.65 0.75],[0.5 0.5],'HeadLength',30,'HeadWidth',40,...
    'HeadStyle','plain','LineWidth',4,'Color',[0 0 1]);
% draw stimulus: MI feedback arrow (left)
h(1,2) = annotation(gcf,'arrow',[0.35 0.25],[0.5 0.5],'HeadLength',30,'HeadWidth',40,...
    'HeadStyle','plain','LineWidth',4,'Color',[0 0 1]);
% draw stimulus; Rest fixation cross
h(1,3) = line([-0.2 0.2], [0 0],'Color',[0 0 1],'LineWidth',4);
h(2,3) = line([0 0], [-0.2 0.2],'Color',[0 0 1],'LineWidth',4);
    
set(gca,'visible','off');
%Create a text object with no text in it, center it, set font and color
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',[0.75 0.75 0.75],'visible','off');

            
              
% play the stimulus
set(h(:),'visible','off');
sendEvent('stimulus.training','start');

set(txthdl,'string', 'Click mouse when ready', 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;



for si=1:nSeq;
  set(h(1,4),'visible','on');
  set(h(1,5),'visible','on');
  set(h(1,6),'visible','on');
  set(h(2,6),'visible','on'); drawnow;
  if ( ~ishandle(fig) ) break; end;
  % show the screen to alert the subject to trial start
  tgtId = find(tgtSeq(:,si)>0);
  % show the target
  fprintf('%d) tgt=%d : ',si,find(tgtSeq(:,si)>0));
  set(h(:,tgtSeq(:,si)>0),'visible','on');
  %set(txthdl ,'string',conditions{tgtId},'color',tgtColor, 'visible', 'on');
  sendEvent('stimulus.target',conditions{tgtId});
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.trial.continuous','start');
  % wait for trial end
  sleepSec(trialDuration);
  % reset the cue and fixation point to indicate trial has finished  
  sendEvent('stimulus.trial.continuous','end');
  ftime=getwTime();
  fprintf('\n');
  set(h(:,1:3),'visible','off'); 
  if(mod(si,nGroup) == 0)
      set(h(:),'visible','off');
      set(txthdl,'string', 'Press any key to continue', 'color',bgColor,'visible', 'on'); drawnow;
      waitforbuttonpress;
      set(txthdl,'visible', 'off'); drawnow;
  end
end % sequences

set(txthdl,'string', 'Click mouse when ready', 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;



% end training marker
sendEvent('stimulus.training','end');

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'That ends the training phase.','Thanks for your patience'}, 'visible', 'on', 'color',[0 1 0]);
pause(3);
end
