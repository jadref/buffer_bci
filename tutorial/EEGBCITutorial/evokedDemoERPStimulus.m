% make the stimulus
fig=figure(2);
set(fig,'Name','Evoked/Induced Response Stimulus.  Press key to start trial','color',[0 0 0],'menubar','none','toolbar','none','doublebuffer','on');
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');
stimPos=[]; h=[];
% center block
h(1) =rectangle('curvature',[0 0],'position',[[0;0]-stimRadius/2;stimRadius*[1;1]],'facecolor',bgColor); 
% left block
h(2) =rectangle('curvature',[0 0],'position',[[-.75;0]-stimRadius/2;stimRadius*[1;1]],'facecolor',bgColor); 
% right block
h(3) =rectangle('curvature',[0 0],'position',[[.75;0]-stimRadius/2;stimRadius*[1;1]],'facecolor',bgColor); 
% fixation point
h(4) =rectangle('curvature',[1 1],'position',[[0;0]-.5/4;.5/2*[1;1]],'facecolor',bgColor');
% add symbol for the center of the screen
set(gca,'visible','off');
set(fig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:))));
set(fig,'userdata',[]); % clear any old key info

set(fig,'Units','pixel');wSize=get(fig,'position');fontSize = .05*wSize(4);
instructh=text(min(get(ax,'xlim'))+.25*diff(get(ax,'xlim')),mean(get(ax,'ylim')),instructstr,'HorizontalAlignment','left','VerticalAlignment','middle','color',[0 1 0],'fontunits','pixel','FontSize',fontSize,'visible','off');

%BODGE: to force screen redraw
if ( exist('OCTAVE_VERSION','builtin') ) hold('on'); ph=plot(-1.5,-1.5,'k'); end; 

% load the audio fragments
audio={};
if ( ~exist('OCTAVE_VERSION','builtin') ) % audioplayer not supported in octave
  [tmp,fsi]= wavread('auditoryStimuli/550.wav');%oddball
  beepStd  = audioplayer(tmp(1:min(size(tmp,1),fsi*.2),:)', fsi); % limit to .2s long
  [tmp,fsi]= wavread('auditoryStimuli/500.wav');%standard
  beepOdd = audioplayer(tmp(1:min(size(tmp,1),fsi*.2),:)', fsi); % limit to .2s long
  audio = {beepStd beepOdd};
end

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'visible','off'); % make them all invisible
set(h(:),'facecolor',bgColor);
set(instructh,'visible','on');
inswait=0;
tgt=ones(4,1);
endTraining=false; si=0;
sendEvent('stimulus.training','start'); 
while ( ~endTraining ) 
  si=si+1;
    
  %sleepSec(intertrialDuration);
  % wait for key press to start the next epoch  
  seqStart=false;
  while ( ~seqStart )
    if ( ~ishandle(fig) ) endTraining=true; break; end;  
    inswait=0;
    key=get(fig,'userData');
    while ( ishandle(fig) && isempty(key) )
      key=get(fig,'userData');
		if ( exist('OCTAVE_VERSION','builtin') ) set(ph,'ydata',rand(1)*.01); drawnow; pause(.1); end;
      if ( inswait>6 ) set(instructh,'visible','on');drawnow; end;
      pause(.25);
      inswait=inswait+1;
    end
    if ( ~ishandle(fig) ) endTraining=true; break; end;
    % turn off the instructions screen
    set(instructh,'visible','off');drawnow;sleepSec(.5);
    if ( ~ishandle(fig) ) endTraining=true; break; end;

    %fprintf('key=%s\n',key);
    %key=get(fig,'currentkey');
    set(fig,'userData',[]);
    switch lower(key(1))
     case {'v','1'}; [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_Vis(h,trialDuration);          
			 seqStart=true;
     case {'o','2'}; [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_Vis(h,trialDuration,1/5,2,1);  
			 seqStart=true;
     case {'a'};     [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_Aud(h,trialDuration,1/2,2,1);    
			 seqStart=true;
     case {'s','3'}; [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_SSVEP(h,trialDuration,1/ssvepFreq(1)/2,sprintf('SSVEP %g',ssvepFreq(1)));   
			 seqStart=true;
     case {'p','4'}; [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_P3(h,trialDuration,1/5,2,1); 
			 seqStart=true;
     case {'f','5'}; [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_flicker(h,trialDuration,isi,1./(flickerFreq*isi)); 
			 seqStart=true;
     case {'l','6'}; % left box only
      stimTime=0:1:trialDuration; % times something happens, i.e. every second send event
      stimSeq =-ones(numel(h),numel(stimTime)); stimSeq(2,:)=1; stimSeq(4,:)=2; % what happens when
      colors=[tgtColor;bgColor]'; % key for color to use for each stimulus
      eventSeq=cell(1,numel(stimTime)); [eventSeq{1:end-1}]=deal({'stimulus' 'left'}); % markers to send
      seqStart=true;
     case {'n','7'}; % fixation point only
      stimTime=0:1:trialDuration; % times something happens, i.e. every second send event
      stimSeq =-ones(numel(h),numel(stimTime)); stimSeq(4,:)=1; % what happens when
      colors=[tgtColor;bgColor]'; % key for color to use for each stimulus
      eventSeq=cell(1,numel(stimTime)); [eventSeq{1:end-1}]=deal({'stimulus' 'none'}); % markers to send
      seqStart=true;
     case {'r','8'}; % right box only
      stimTime=0:1:trialDuration; % times something happens, i.e. every second send event
      stimSeq =-ones(numel(h),numel(stimTime)); stimSeq(3,:)=1; stimSeq(4,:)=2; % what happens when
      colors=[tgtColor;bgColor]'; % key for color to use for each stimulus
      eventSeq=cell(1,numel(stimTime)); [eventSeq{1:end-1}]=deal({'stimulus' 'right'}); % markers to send
      seqStart=true;
     case {'q','escape'};         endTraining=true; break; % end the phase
     %case {'7'};     [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_SSVEP(h,trialDuration,1/ssvepFreq(2)/2,sprintf('SSVEP %g',ssvepFreq(2)));  seqStart=true;
     %case {'8'};     [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_SSVEP(h,trialDuration,1/ssvepFreq(3)/2,sprintf('SSVEP %g',ssvepFreq(3)));  seqStart=true;
     %case {'9'};     [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_SSVEP(h,3,1/ssvepFreq(4)/2,sprintf('SSVEP %g',ssvepFreq(4)));  seqStart=true;
     %case {'0'};     [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_SSVEP(h,3,1/ssvepFreq(5)/2,sprintf('SSVEP %g',ssvepFreq(5)));  seqStart=true;
     otherwise; fprintf('Unrecog key: %s\n',lower(key)); seqStart=false;
    end        
  end
  if ( ~ishandle(fig) || endTraining ) break; end;
  
  % show the screen to alert the subject to trial start
  set(h(1:end-1),'visible','off');
  set(h(end),'visible','on','facecolor',fixColor); % red fixation indicates trial about to start/baseline
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');
    
  % now play the selected sequence
  seqStartTime=getwTime(); ei=0; ndropped=0; frametime=zeros(numel(stimTime),4);
  while ( stimTime(end)>=getwTime()-seqStartTime ) % frame-dropping version    
    ei=min(numel(stimTime),ei+1);
    frametime(ei,1)=getwTime()-seqStartTime;
    % find nearest stim-time
    if ( ei<numel(stimTime) && frametime(ei,1)>=stimTime(min(numel(stimTime),ei+1)) ) 
      oei = ei;
      for ei=ei+1:numel(stimTime); if ( frametime(oei,1)<stimTime(ei) ) break; end; end; % find next valid frame
      if ( verb>=0 ) fprintf('%d) Dropped %d Frame(s)!!!\n',ei,ei-oei); end;
      ndropped=ndropped+(ei-oei);
    end
    ss=stimSeq(:,ei);
    set(h(ss<0),'visible','off');  % neg stimSeq codes for invisible stimulus
    set(h(ss>=0),'visible','on','facecolor',bgColor); % everybody starts as background color
    if(any(ss==1))set(h(ss==1),'facecolor',colors(:,1)); end% stimSeq codes into a colortable
    if(any(ss==2))set(h(ss==2),'facecolor',colors(:,min(size(colors,2),2)));end;
    if(any(ss==3))set(h(ss==3),'facecolor',colors(:,min(size(colors,2),3)));end;
    
    % sleep until time to update the stimuli the screen
    if ( verb>1 ) fprintf('%d) Sleep : %gs\n',ei,stimTime(ei)-(getwTime()-seqStartTime)-flipInterval/2); end;
    sleepSec(max(0,stimTime(ei)-(getwTime()-seqStartTime))); % wait until time to call the draw-now
    if ( verb>0 ) frametime(ei,2)=getwTime()-seqStartTime; end;
    drawnow;
    if(any(ss==-4))if(~isempty(audio{1}))play(audio{1});end;end;
    if(any(ss==-5))if(~isempty(audio{2}))play(audio{2});end;end; 
    if ( verb>0 ) 
      frametime(ei,3)=getwTime()-seqStartTime;
      fprintf('%d) dStart=%8.6f dEnd=%8.6f stim=[%s] lag=%g\n',ei,...
              frametime(ei,2),frametime(ei,3),...
              sprintf('%d ',stimSeq(:,ei)),stimTime(ei)-(getwTime()-seqStartTime));
    end
    % send event saying what the updated display was
    if ( ~isempty(eventSeq{ei}) ) 
      ev=sendEvent(eventSeq{ei}{:}); 
      if (verb>0) fprintf('%d) Event: %s\n',ei,ev2str(ev)); end;
    end
  end
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
end % sequences
% end training marker
sendEvent('stimulus.training','end');

% thanks message
% if ( ishandle(fig) ) 
% text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),{'That ends the training phase.','Thanks for your patience'},'HorizontalAlignment','center','color',[0 1 0],'fontunits','normalized','FontSize',.1);
% pause(3);
% end


