configureSSEP;

% make the stimulus
fig=gcf;
set(fig,'Name','SSEP Stimulus','color',[0 0 0],'menubar','none','toolbar','none','doublebuffer','on');
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1 1],'ylim',[-1 1],'Ydir','normal');
h=[];
theta=linspace(0,2*pi*(nSymbs-1)/nSymbs,nSymbs); 
for stimi=1:nSymbs;
  h(stimi) =rectangle('curvature',[0 0],'facecolor',bgColor,...
                      'position',[[cos(theta(stimi));sin(theta(stimi))]*.75-stimRadius/2;stimRadius*[1;1]]); 
end
% add the fixation point
h(nSymbs+1) =rectangle('curvature',[1 1],'position',[[0;0]-.5/4;.5/2*[1;1]],'facecolor',bgColor');
% add symbol for the center of the screen
set(gca,'visible','off');
tgt=ones(4,1);
endTraining=false; 
sendEvent('stimulus.training','start'); 
for seqi=1:nSeq;
  % make the target sequence
  tgtSeq=mkStimSeqRand(numel(h)-1,seqLen);

  % play the stimulus
  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'visible','off'); % make them all invisible
  set(h(:),'facecolor',bgColor);
  sendEvent('stimulus.sequence','start');
  for si=1:size(tgtSeq,2);
    
    if ( ~ishandle(fig) ) break; end;  
    
    sleepSec(intertrialDuration);

    % show the screen to alert the subject to trial start
    set(h(1:end-1),'visible','off');
    set(h(end),'visible','on','facecolor',fixColor); % red fixation indicates trial about to start/baseline
    drawnow;% expose; % N.B. needs a full drawnow for some reason
    sendEvent('stimulus.baseline','start');
    sleepSec(baselineDuration);
    sendEvent('stimulus.baseline','end');  
    
    tgtId=find(tgtSeq(:,si)>0);
    fprintf('%d) tgt=%s : ',si,classes{tgtId});
    set(h(:),'visible','on');
    set(h(:),'facecolor',bgColor);
    set(h(tgtId),'facecolor',tgtColor);
    drawnow;% expose; % N.B. needs a full drawnow for some reason
    ev=sendEvent('stimulus.target',classes{tgtId});
    if ( verb>1 ) fprintf('Sending target : %s\n',ev2str(ev)); end;
    sleepSec(cueDuration);
    set(h(:),'facecolor',bgColor);
    drawnow;
    
    % make the stim-seq for this trial
    [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_flicker(h,trialDuration,isi,periods,false);
    % now play the sequence
    sendEvent('stimulus.stimSeq',stimSeq(tgtId,:));
    sendEvent('stimulus.frameNumber',0);
    seqStartTime=getwTime(); ei=0; ndropped=0; syncEvtTime=seqStartTime; frametime=zeros(numel(stimTime),4);
    while ( stimTime(end)>=getwTime()-seqStartTime ) % frame-dropping version    
      ei=min(numel(stimTime),ei+1);
      frametime(ei,1)=getwTime()-seqStartTime;
      % find nearest stim-time, dropping frames is necessary to say on the time-line
      if ( frametime(ei,1)>=stimTime(min(numel(stimTime),ei+1)) ) 
        oei = ei;
        for ei=ei+1:numel(stimTime); if ( frametime(oei,1)<stimTime(ei) ) break; end; end; % find next valid frame
        if ( verb>=0 ) fprintf('%d) Dropped %d Frame(s)!!!\n',ei,ei-oei); end;
        ndropped=ndropped+(ei-oei);
      end
      set(h(:),'facecolor',bgColor); % everybody starts as background color
      ss=stimSeq(:,ei);
      set(h(ss<0),'visible','off');  % neg stimSeq codes for invisible stimulus
      set(h(ss>=0),'visible','on');  % positive are visible    
      if(any(ss==1))set(h(ss==1),'facecolor',colors(:,1)); end;% stimSeq codes into a colortable
      if(any(ss==2))set(h(ss==2),'facecolor',colors(:,min(size(colors,2),2)));end;
      if(any(ss==3))set(h(ss==3),'facecolor',colors(:,min(size(colors,2),3)));end;

      % sleep until time to re-draw the screen
      sleepSec(max(0,stimTime(ei)-(getwTime()-seqStartTime))); % wait until time to call the draw-now
      if ( verb>0 ) frametime(ei,2)=getwTime()-seqStartTime; end;
      drawnow;
      if ( verb>0 ) 
        frametime(ei,3)=getwTime()-seqStartTime;
        fprintf('%d) dStart=%8.6f dEnd=%8.6f stim=[%s] lag=%g\n',ei,...
                frametime(ei,2),frametime(ei,3),...
                sprintf('%d ',stimSeq(:,ei)),stimTime(ei)-(getwTime()-seqStartTime));
      end
      % send event saying what the updated display was
      if ( ~isempty(eventSeq{ei}) ) 
        ev=sendEvent(eventSeq{ei}{:}); 
        if (verb>0) fprintf('Event: %s\n',ev2str(ev)); end;
      end
      if ( frametime(ei,1)>syncEvtTime+1 ) % once per second a sync event
        syncEvtTime=frametime(ei,1);
        sendEvent('stimulus.frameNumber',ei);
      end
    end % while < endTime
    if ( verb>0 ) % summary info
      dt=frametime(:,3)-frametime(:,2);
      fprintf('Sum: %d dropped frametime=%g drawTime=[%g,%g,%g]\n',...
              ndropped,mean(diff(frametime(:,1))),min(dt),mean(dt),max(dt));
    end
    
    % reset the cue and fixation point to indicate trial has finished  
    set(h(:),'facecolor',bgColor,'visible','off');
    drawnow;
    sendEvent('stimulus.trial','end');
    
    fprintf('\n');
  end % epochs within a sequence

  if ( seqi<nSeq ) %wait for key press to continue
    uiwait(msgbox({sprintf('End of sequence %d/%d.',seqi,nSeq) 'Press OK to continue'},'Thanks','modal'),10);
  end

end % sequences
% end training marker
sendEvent('stimulus.training','end');

% thanks message
text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),{'That ends the training phase.','Thanks for your patience'},'HorizontalAlignment','center','color',[0 1 0],'fontunits','normalized','FontSize',.1);
pause(3);
