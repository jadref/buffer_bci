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

% start the stimulus
state=buffer('poll'); % set initial config
tgt=ones(4,1);
sendEvent('stimulus.training','start'); 
for seqi=1:nSeq;
  
  sleepSec(intertrialDuration);

							  % show the screen to alert the subject to trial start
  Screen('Drawtextures',wPtr,texels(end),srcR(:,end),destR(:,end),[],[],[],fixColor*255); 
  Screen('flip',wPtr,1,1);% re-draw the display
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');  
  
  
										  % make the stim-seq for this trial
  [stimSeq,stimTime,eventSeq,colors]=mkStimSeqSSEP(texels,trialDuration,isi,periods,false);
																	 % now play the sequence
  sendEvent('stimulus.stimSeq',stimSeq(tgtId,:)); % event is actual target stimulus sequence

										  % now play the sequence
  ev=sendEvent('stimulus.trial','start');
  sendEvent('classifier.apply','now',ev.sample);%tell the classifier to apply to this data
  evti=0; stimEvts=mkEvent('test'); % reset the total set of events info
  seqStartTime=getwTime(); ei=0; ndropped=0; frametime=zeros(numel(stimTime),4);
  while ( true ) % frame-dropping version    
    ftime=getwTime()-seqStartTime();
    if ( ftime>=stimTime(end) ) break; end; % exit condition

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

										  % do the return to baseline phase
  sendEvent('stimulus.rtb','start');
  sleepSec(rtbDuration);        
  Screen('flip',wPtr);% re-draw the display, as blank
  sendEvent('stimulus.trial','end');
  
  if ( verb>0 ) % summary info
    dt=frametime(:,3)-frametime(:,2);
    fprintf('Sum: %d dropped frametime=%g drawTime=[%g,%g,%g]\n',...
            ndropped,mean(diff(frametime(:,1))),min(dt),mean(dt),max(dt));
  end

										  % wait for any prediction events
										  % wait for classifier prediction event
  if( verb>0 ) fprintf(1,'Waiting for predictions\n'); end;
  [devents,state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],500);  

	 % do something with the prediction (if there is one), i.e. give feedback
  if( isempty(devents) ) % extract the decision value
	 fprintf(1,'Error! no predictions, continuing');
  else
	 dv = devents(end).value;
	 if ( numel(dv)==1 )
      if ( dv>0 && dv<=nSymbs && isinteger(dv) ) % dvicted symbol, convert to dv equivalent
		  tmp=dv; dv=zeros(nSymbs,1); dv(tmp)=1;
      else % binary problem, convert to per-class
		  dv=[dv -dv];
      end
	 end
										  % give the feedback on the predicted class
	 prob=1./(1+exp(-dv)); prob=prob./sum(prob);
	 if ( verb>=0 ) 
      fprintf('dv:');fprintf('%5.4f ',dv);fprintf('\t\tProb:');fprintf('%5.4f ',prob);fprintf('\n'); 
	 end;  
	 [ans,predTgt]=max(dv); % prediction is max classifier output

										  % show the feedback
	 fprintf('%d) tgt=%s : ',si,classes{predTgt});
	 Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
	 Screen('Drawtextures',wPtr,texels(predTgt),srcR(:,predTgt),destR(:,predTgt),...
			  [],[],[],feedbackColor*255); 
	 Screen('flip',wPtr);% re-draw the display
	 ev=sendEvent('stimulus.predTgt',predTgt);
  end
  sleepSec(feedbackDuration);
  
  fprintf('\n');

end % sequences
% end training marker
sendEvent('stimulus.testing','end');

% thanks message
if ( isempty(windowPos) ) Screen('closeall'); end; % close display if fullscreen
