if ( ~exist('imConfig','var') || ~imConfig ) configureIM; end;

% make the stimulus
fig=gcf;
set(fig,'Name','Press: Left/Right/Down to generate trial','color',[0 0 0],'menubar','none','toolbar','none','doublebuffer','on');
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');
stimPos=[]; h=[];
stimRadius=.5;
theta=linspace(0,pi,nSymbs); stimPos=[cos(theta);-sin(theta)];
for hi=1:nSymbs; 
  h(hi)=rectangle('curvature',[1 1],'position',[stimPos(:,hi)-stimRadius/2;stimRadius*[1;1]],...
                  'facecolor',bgColor); 
end;
% add symbol for the center of the screen
stimPos(:,nSymbs+1)=[0 0];
h(nSymbs+1)=rectangle('curvature',[1 1],'position',[stimPos(:,nSymbs+1)-stimRadius/4;stimRadius/2*[1;1]],...
                      'facecolor',bgColor); 
set(gca,'visible','off');
set(fig,'keypressfcn',@keyListener);
set(fig,'userdata',[]); % clear any old key info

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'facecolor',bgColor);
tgt=ones(nSymbs,1);
endTraining=false; si=0;
sendEvent('stimulus.training','start'); 
while ( ~endTraining ) 
  si=si+1;
  
  if ( ~ishandle(fig) ) endTraining=true; break; end;  
  
  %sleepSec(intertrialDuration);
  % wait for key press to start the next epoch  
  tgt(:)=0;
  while ( ~any(tgt) )
    key=get(fig,'userData');
    while ( isempty(key) )
      key=get(fig,'userData');
      pause(.25);
    end
    %fprintf('key=%s\n',key);
    key=get(fig,'currentkey');
    set(fig,'userData',[]);
    switch lower(key)
     case {'d','r','rightarrow'}; tgt(1)=1; %right
     case {'s','d','downarrow'};  tgt(2)=1; %down
     case {'a','l','leftarrow'};  tgt(3)=1; %left
     case {'q','escape'};         endTraining=true; break; % end the phase
    end        
  end
  if ( endTraining ) break; end;

  % show the screen to alert the subject to trial start
  set(h(end),'facecolor',fixColor); % red fixation indicates trial about to start/baseline
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');
    
  % show the target
  fprintf('%d) tgt=%d : ',si,find(tgt>0));
  set(h(tgt>0),'facecolor',tgtColor);
  set(h(tgt<=0),'facecolor',bgColor);
  set(h(end),'facecolor',[0 1 0]); % green fixation indicates trial running
  sendEvent('stimulus.target',find(tgt>0));
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.trial','start');
  % wait for trial end
  sleepSec(trialDuration);
  
  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'facecolor',bgColor);
  drawnow;
  sendEvent('stimulus.trial','end');
  
  fprintf('\n');
end % sequences
% end training marker
sendEvent('stimulus.training','end');

% thanks message
text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),{'That ends the training phase.','Thanks for your patience'},'HorizontalAlignment','center','color',[0 1 0],'fontunits','normalized','FontSize',.1);
pause(3);
