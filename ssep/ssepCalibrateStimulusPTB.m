configureSSEP;

% make the stimulus
ws=Screen('windows'); % re-use existing window 
if ( isempty(ws) )
  if ( IsLinux() ) PsychGPUControl('FullScreenWindowDisablesCompositor', 1); end % exclusive disp access in FS
  screenNum = max(Screen('Screens')); % get 2nd display
  wPtr= Screen('OpenWindow',screenNum,bgColor,windowPos)
  Screen('BlendFunction',wPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA); % enable alpha blending
  [flipInterval nrValid stddev]=Screen('GetFlipInterval',wPtr); % get flip-time (i.e. refresh rate)
  [width,height]=Screen('WindowSize',wPtr); 
else
  wPtr=ws(1);
end
% Now make the boxes
stimPos=[]; texels=[]; destR=[]; srcR=[];
theta=linspace(0,2*pi*(nSymbs-1)/nSymbs,nSymbs); 
for stimi=1:nSymbs;
  % N.B. move to the postive quadrant and shrink to be in 0-1 range.  Also stimRadius/2 for same reason
  x=cos(theta(stimi))*.75/2+.5; y=sin(theta(stimi))*.75/2+.5;
  % N.B. PTB measures y from the top of the screen!
  destR(:,stimi)= round(rel2pixel(wPtr,[x-stimRadius/4 1-y+stimRadius/4 x+stimRadius/4 1-y-stimRadius/4]));
  srcR(:,stimi) = [0 destR(3,stimi)-destR(1,stimi) destR(2,stimi)-destR(4,stimi) 0];
  texels(stimi)  = Screen('MakeTexture',wPtr,ones(srcR([2 3],stimi)')*255);
end
% fixation point
stimi=nSymbs+1;
destR(:,stimi)= round(rel2pixel(wPtr,[.5-stimRadius/8 .5+stimRadius/8 .5+stimRadius/8 .5-stimRadius/8]));
srcR(:,stimi) = [0 destR(3,stimi)-destR(1,stimi) destR(2,stimi)-destR(4,stimi) 0];
texels(stimi)  = Screen('MakeTexture',wPtr,ones(srcR([3 2],stimi)')*255);

tgt=ones(4,1);
endTraining=false;
sendEvent('stimulus.training','start'); 
for seqi=1:nSeq;
  % make the target sequence
  tgtSeq=mkStimSeqRand(numel(texels)-1,seqLen);

  % play the stimulus
  % reset the cue and fixation point to indicate trial has finished  
  sendEvent('stimulus.sequence','start');
  for si=1:size(tgtSeq,2);
    
    sleepSec(intertrialDuration);

    % show the screen to alert the subject to trial start
    Screen('Drawtextures',wPtr,texels(end),srcR(:,end),destR(:,end),[],[],[],fixColor*255); 
    Screen('flip',wPtr,1,1);% re-draw the display
    sendEvent('stimulus.baseline','start');
    sleepSec(baselineDuration);
    sendEvent('stimulus.baseline','end');  
    
    tgtId=find(tgtSeq(:,si)>0);
    fprintf('%d) tgt=%s : ',si,classes{tgtId});
    Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
    Screen('Drawtextures',wPtr,texels(tgtId),srcR(:,tgtId),destR(:,tgtId),[],[],[],tgtColor*255); 
    Screen('flip',wPtr);% re-draw the display
    ev=sendEvent('stimulus.target',classes{tgtId});
    if ( verb>1 ) fprintf('Sending target : %s\n',ev2str(ev)); end;
    sleepSec(cueDuration);
    Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
    Screen('flip',wPtr);% re-draw the display
    
    % make the stim-seq for this trial
    [stimSeq,stimTime,eventSeq,colors]=mkStimSeqSSEP(texels,trialDuration,isi,periods,false);
    % now play the sequence
    sendEvent('stimulus.stimSeq',stimSeq(tgtId,:)); % event is actual target stimulus sequence

	 evti=0; stimEvts=mkEvent('test'); % reset the total set of events info
    seqStartTime=getwTime(); ei=0; ndropped=0; frametime=zeros(numel(stimTime),4);
    while ( true ) % frame-dropping version    
      ftime=getwTime()-seqStartTime();
      if ( ftime>=stimTime(end) ) break; end;

	   % get the next frame to display -- dropping frames if we're running slow
      ei=min(numel(stimTime),ei+1);
      frametime(ei,1)=ftime;
      % find nearest stim-time, dropping frames is necessary to say on the time-line
      if ( ftime>=stimTime(min(numel(stimTime),ei+1)) ) 
        oei = ei;
        for ei=ei+1:numel(stimTime); if ( ftime<stimTime(ei) ) break; end; end; % find next valid frame
        if ( verb>=0 ) fprintf('%d) Dropped %d Frame(s)!!!\n',ei,ei-oei); end;
        ndropped=ndropped+(ei-oei);
      end

		% update the display with the current frame's information
      ss=stimSeq(:,ei);
      if(any(ss>=0))
        Screen('Drawtextures',wPtr,texels(ss>=0),srcR(:,ss>=0),destR(:,ss>=0),[],[],[],bgColor*255); 
      end
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

    sendEvent('stimulus.rtb','start');
    sleepSec(rtbDuration);        
    Screen('flip',wPtr);% re-draw the display, as blank
    sendEvent('stimulus.trial','end');
    
    fprintf('\n');
  end % epochs within a sequence

  if ( seqi<nSeq ) %wait for key press to continue
    Screen('FillRect',wPtr,[0 0 0]*255); % blank background
    [ans,ans,instructSrcR]=DrawFormattedText(wPtr,sprintf('End of sequence %d/%d.',seqi,nSeq),0,0,[1 1 1]*255);
    Screen('flip',wPtr);
    try;  % wait for a key press *and release*, or until 10 sec has passed -- only in PTB>3.08       
       KbWait([],2,GetSecs()+10);
    catch ;
       sleepSec(10);
    end
  end

end % sequences
% end training marker
sendEvent('stimulus.training','end');

% thanks message
%msgbox({'That ends the training phase.','Thanks for your patience'},'Thanks','modal');
%pause(1);
if ( isempty(windowPos) ) Screen('closeall'); end; % close display if fullscreen
