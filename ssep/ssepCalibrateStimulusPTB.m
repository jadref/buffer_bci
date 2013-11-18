configureSSEP();

% make the stimulus
ws=Screen('windows'); % re-use existing window 
if ( isempty(ws) )
  if ( IsLinux() ) PsychGPUControl('FullScreenWindowDisablesCompositor', 1); end % exclusive disp access in FS
  screenNum = max(Screen('Screens')); % get 2nd display
  wPtr= Screen('OpenWindow',screenNum,bgColor,windowPos)
  Screen('BlendFunction',wPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA); % enable alpha blending
  [flipInterval nrValid stddev]=Screen('GetFlipInterval',wPtr); % get flip-time (i.e. refresh rate)
else
  wPtr=ws(1);
end
% Now make the boxes
stimPos=[]; texels=[]; destR=[]; srcR=[];
% left block
destR(:,1)= round(rel2pixel(wPtr,[.25-stimRadius/2 .5+stimRadius/2 .25+stimRadius/2 .5-stimRadius/2]));
srcR(:,1) = [0 destR(3,1)-destR(1,1) destR(2,1)-destR(4,1) 0];
texels(1)  = Screen('MakeTexture',wPtr,ones(srcR([2 3],1)')*255);
% right block
destR(:,2)= round(rel2pixel(wPtr,[.75-stimRadius/2 .5+stimRadius/2 .75+stimRadius/2 .5-stimRadius/2]));
srcR(:,2) = [0 destR(3,2)-destR(1,2) destR(2,2)-destR(4,2) 0];
texels(2)  = Screen('MakeTexture',wPtr,ones(srcR([3 2],2)')*255);
% fixation point
destR(:,3)= round(rel2pixel(wPtr,[.5-stimRadius/4 .5+stimRadius/4 .5+stimRadius/4 .5-stimRadius/4]));
srcR(:,3) = [0 destR(3,3)-destR(1,3) destR(2,3)-destR(4,3) 0];
texels(3)  = Screen('MakeTexture',wPtr,ones(srcR([3 2],3)')*255);

% make the target sequence
tgtSeq=mkStimSeqRand(numel(texels)-1,nSeq);

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
endTraining=false; si=0;
sendEvent('stimulus.training','start'); 
for si=1:size(tgtSeq,2);
  
  sleepSec(intertrialDuration);

  % show the screen to alert the subject to trial start
  Screen('Drawtextures',wPtr,texels(end),srcR(:,end),destR(:,end),[],[],[],fixColor*255); 
  Screen('flip',wPtr,1,1);% re-draw the display
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');  
  
  tgtId=find(tgtSeq(:,si)>0);
  fprintf('%d) tgt=%d : ',si,tgtId);
  Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
  Screen('Drawtextures',wPtr,texels(tgtId),srcR(:,tgtId),destR(:,tgtId),[],[],[],tgtColor*255); 
  Screen('flip',wPtr);% re-draw the display
  ev=sendEvent('stimulus.target',tgtId);
  if ( verb>1 ) fprintf('Sending target : %s\n',ev2str(ev)); end;
  sleepSec(cueDuration);
  Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
  Screen('flip',wPtr);% re-draw the display
    
  % make the stim-seq for this trial
  [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_flicker(texels,trialDuration,flipInterval,periods,false);
  % now play the sequence
  sendEvent('stimulus.stimSeq',stimSeq(:,tgtId));
  seqStartTime=getwTime(); ei=0; ndropped=0; frametime=zeros(numel(stimTime),4);
  while ( stimTime(end)>=getwTime()-seqStartTime ) % frame-dropping version    
    ei=min(numel(stimTime),ei+1);
    frametime(ei,1)=getwTime()-seqStartTime;
    % find nearest stim-time
    if ( frametime(ei,1)>=stimTime(min(numel(stimTime),ei+1)) ) 
      if ( verb>=0 ) fprintf('%d) Dropped Frame!!!\n',ei); end;
      ndropped=ndropped+1;
      ei=min(numel(stimTime),ei+1);
    end
    ss=stimSeq(:,ei);
    Screen('Drawtextures',wPtr,texels(ss>=0),srcR(:,ss>=0),destR(:,ss>=0),[],[],[],bgColor*255); 
    if(any(ss==1))
      Screen('Drawtextures',wPtr,texels(ss==1),srcR(:,ss==1),destR(:,ss==1),[],[],[],colors(:,1)*255); 
    end% stimSeq codes into a colortable
    if(any(ss==2))
      Screen('Drawtextures',wPtr,texels(ss==2),srcR(:,ss==2),destR(:,ss==2),[],[],[],colors(:,2)*255); 
    end;
    if(any(ss==3))
      Screen('Drawtextures',wPtr,texels(ss==3),srcR(:,ss==3),destR(:,ss==3),[],[],[],colors(:,3)*255); 
    end;

    % sleep until just before the next re-draw of the screen
    % then let PTB do the waiting until the exact right time
    sleepSec(max(0,stimTime(ei)-(getwTime()-seqStartTime)-flipInterval/2)); 
    if ( verb>0 ) frametime(ei,2)=getwTime()-seqStartTime; end;
    Screen('flip',wPtr,0,0,0);% re-draw the display, but wait for the re-fresh
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
  end
  if ( verb>0 ) % summary info
    dt=frametime(:,3)-frametime(:,2);
    fprintf('Sum: %d dropped frametime=%g drawTime=[%g,%g,%g]\n',...
            ndropped,mean(diff(frametime(:,1))),min(dt),mean(dt),max(dt));
  end
  
  Screen('flip',wPtr);% re-draw the display, as blank
  sendEvent('stimulus.trial','end');
  
  fprintf('\n');
end % sequences
% end training marker
sendEvent('stimulus.training','end');

% thanks message
%msgbox({'That ends the training phase.','Thanks for your patience'},'Thanks','modal');
%pause(1);
if ( isempty(windowPos) ) Screen('closeall'); end; % close display if fullscreen