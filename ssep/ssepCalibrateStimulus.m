configureSSEP;

% make the stimulus
fig=figure(2);
set(fig,'Name','SSEP Stimulus','color',[0 0 0],'menubar','none','toolbar','none','doublebuffer','on');
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1 1],'ylim',[-1 1],'Ydir','normal');
set(ax,'visible','off');
h=[];
theta=linspace(0,2*pi*(nSymbs-1)/nSymbs,nSymbs); 
for stimi=1:nSymbs;
  h(stimi) =rectangle('curvature',[0 0],'facecolor',bgColor,...
                      'position',[[cos(theta(stimi));sin(theta(stimi))]*.75-stimRadius/2;stimRadius*[1;1]]); 
end
% add the fixation point
h(nSymbs+1) =rectangle('curvature',[1 1],'position',[[0;0]-.5/4;.5/2*[1;1]],'facecolor',bgColor');

% add a txt handle for instructions
txth=text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ','HorizontalAlignment','center','VerticalAlignment','middle','color',[0 1 0],'fontunits','normalized','FontSize',.05,'visible','on','interpreter','none');

% show instructions & wait to start
set(txth,'string',instructstr,'visible','on');
drawnow;
waitforbuttonpress;
set(txth,'visible','off');

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
    [stimSeq,stimTime,eventSeq,colors]=mkStimSeqSSEP(h,trialDuration,isi,periods,false);
    % now play the sequence
    sendEvent('stimulus.trial','start'); 

	 evti=0; stimEvts=mkEvent('test'); % reset the total set of events info
    seqStartTime=getwTime(); ei=0; ndropped=0; frametime=zeros(numel(stimTime),4);
    while ( stimTime(end)>=getwTime()-seqStartTime ) % frame-dropping version    

	   % get the next frame to display -- dropping frames if we're running slow
		ei=min(numel(stimTime),ei+1);
      frametime(ei,1)=getwTime()-seqStartTime;
      % find nearest stim-time, dropping frames is necessary to say on the time-line
      if ( frametime(ei,1)>=stimTime(min(numel(stimTime),ei+1)) ) 
        oei = ei;
        for ei=ei+1:numel(stimTime); if ( frametime(oei,1)<stimTime(ei) ) break; end; end; % find next valid frame
        if ( verb>=0 ) fprintf('%d) Dropped %d Frame(s)!!!\n',ei,ei-oei); end;
        ndropped=ndropped+(ei-oei);
      end

		% update the display with the current frame's information
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

      % record event info about this stimulus to send later so don't delay stimulus
	   if ( isempty(eventSeq) || (numel(eventSeq)>ei && eventSeq(ei)>0) )
		  samp=buffer('get_samp'); % get sample at which display updated
		  % event with information on the total stimulus state
		  evti=evti+1; stimEvts(evti)=mkEvent('stimulus.stimState',ss,samp); 
		end

    end % while < endTime
	 
	 % send all the stimulus events in one go
    buffer('put_evt',stimEvts(1:evti));

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
  end % trials within a sequence
  sendEvent('stimulus.sequence','end');
  
  
  if ( seqi<nSeq ) %wait for key press to continue
	 % show wait message
	 set(txth,'string',{'Pause' 'click mouse to continue'},'visible','on');
	 drawnow;
	 waitforbuttonpress;
	 set(txth,'visible','off');	 
  end

end % sequences
% end training marker
sendEvent('stimulus.training','end');

% thanks message
if ( ishandle(fig))
   set(txth,'string',thanksstr,'visible','on');
   drawnow;
   pause(3);
   close(fig);
end