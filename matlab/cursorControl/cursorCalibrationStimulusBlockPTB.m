% make stim seq with an extra invisible symbol to increase the ISI
switch ( stimType )

  case {'p300','p3','p3-rand'};
	 [stimSeq,stimTime,eventSeq,colors]=mkStimSeqRand(nSymbs,seqDuration,isi);

  case 'p3-radial';
	 [stimSeq,stimTime,eventSeq,colors]=mkStimSeqScan(nSymbs,seqDuration,isi);

  case 'p3-120';
	 [stimSeq,stimTime,eventSeq,colors]=mkStimSeqScan(nSymbs,seqDuration,isi);
	 % shuffle order to be 90-deg out scan
	 nSkip=ceil(nSymbs/4); si=[]; for i=1:nSkip; si=[si i:nSkip:nSymbs]; end; 
	 stimSeq=stimSeq(si,:);

  case 'p3-90';
	 [stimSeq,stimTime,eventSeq,colors]=mkStimSeqScan(nSymbs,seqDuration,isi);
	 % shuffle order to be 90-deg out scan
	 nSkip=ceil(nSymbs/3); si=zeros(nSymbs,1); 
    i=1;j=1;while(any(si==0)); si(mod(j-1,nSymbs)+1)=i; i=i+1; j=j+nSkip; if(si(mod(j-1,nSymbs)+1)>0) j=j+1; end; end 
	 stimSeq=stimSeq(si,:);

  case {'ssvep','ssvep_2phase'};
	 ssepPeriod=[1./ssepFreq/isi]'; % frequency -> duration in samples
	 ssepPeriod=[ssepPeriod(:) ssepPhase(:)/2/pi*ssepPeriod(:)]; % radians -> offset in samples
	 [stimSeq,stimTime,eventSeq,colors]=mkStimSeqSSEP(nSymbs,seqDuration,isi,ssepPeriod,1);

  case 'noise';		  
	 [stimSeq,stimTime,eventSeq,colors]=mkStimSeqNoise(nSymbs,seqDuration,isi,'gold');

  case 'noise-psk';
	 % code runs on 10/01 carrier, so half data rate
	 [bstimSeq,bstimTime,beventSeq,colors]=mkStimSeqNoise(nSymbs,seqDuration,isi*2,'gold');
	 % convert to phase shift keyed
	 stimSeq=zeros(size(bstimSeq,1),size(bstimSeq,2)*2); 
	 stimSeq(:,1:2:end)=bstimSeq; stimSeq(:,2:2:end)=~bstimSeq; %up then down
	 stimTime=zeros(size(bstimSeq,2)*2+1,1);
	 stimTime(1:2:end)=bstimTime;stimTime(2:2:end)=stimTime(1:2:end-1)+isi;
	 eventSeq=false(size(stimSeq,2),1); eventSeq(1:2:end)=true;
	 
  case 'rythm';

  case 'yesno';
  otherwise; error('Unrec stim type');
end
if( verb>1 ) % compute mean tti statistics for each symb
  fprintf('Stim Stats:\n');
  for si=1:size(stimSeq,1); 
    tti=diff(find(stimSeq(si,:)));
    fprintf('Symb%d: %g\t%g\t%g\t%g\n',si,min(tti),mean(tti),max(tti),var(tti));
  end;
end

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

% Wait for key to proceed
blkNm = sprintf('%s_%dhz',stimType,1/isi);
Screen('FillRect',wPtr,[0 0 0]*255); % blank background
[ans,ans,instructSrcR]=DrawFormattedText(wPtr,sprintf('%s\n','Press any key to continue to the next block.',blkNm),width/4,height/2,[1 1 1]*255);
Screen('flip',wPtr,1,1);
KbWait([],2,GetSecs()+5);
Screen('FillRect',wPtr,[0 0 0]*255); % blank background
if ( verb>0 ) 
   fprintf('\n-------------\nStarting stimulus: %s\n--------------\n',blkNm);
end
sendEvent('stimulus.stimType',blkNm);
frametime=[]; nframe=0; curStimState=zeros(nSymbs,1);
for si=1:nSeq;

  % show the screen to alert the subject to trial start
  Screen('Drawtextures',wPtr,h,srcR,destR,[],[],[],bgColor*255); 	 
  Screen('Drawtextures',wPtr,h(end),srcR(:,end),destR(:,end),[],[],[],fixColor*255); 
  Screen('flip',wPtr,1,1);% re-draw the display
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');

  % show the target  
  tgtId=find(tgtSeq(:,si)>0);
  fprintf('%d) tgt=%d : ',si,tgtId);
  Screen('Drawtextures',wPtr,h,srcR,destR,[],[],[],bgColor*255); 
  Screen('Drawtextures',wPtr,h(tgtId),srcR(:,tgtId),destR(:,tgtId),[],[],[],tgtColor*255);   
  Screen('flip',wPtr);% re-draw the display
  ev=sendEvent('stimulus.target',tgtId);
  if ( verb>1 ) fprintf('Sending target : %s\n',ev2str(ev)); end;
  sleepSec(cueDuration);

  Screen('Drawtextures',wPtr,h,srcR,destR,[],[],[],bgColor*255); 
  Screen('flip',wPtr);% re-draw the display
  fprintf('.');
  sleepSec(startDelay);
  
  sendEvent('stimulus.trial','start');
  % play the stimulus
  evti=0; stimEvts=mkEvent('test'); % reset the total set of events info
  seqStartTime=getwTime(); 
  repStartTime=seqStartTime;
  frmi=0; ei=0; ss=stimSeq(:,1); ndropped=0;
  while ( getwTime()-seqStartTime < seqDuration ) % frame dropping version
	 frmi=frmi+1;
	 
    % find nearest stim-time
	 ei= ei+1;
	 if ( ei>size(stimSeq,2) ) % wrap-around end of seq
		ei=1; 
		repStartTime=repStartTime+stimTime(end); 
	 end;
	 frametime=getwTime();
    if ( frametime>=repStartTime+stimTime(min(numel(stimTime),ei+1)) ) 
      oei = ei;
		% find next valid frame
      for ei=ei+1:size(stimSeq,2); if(frametime<stimTime(ei)+repStartTime) break; end; end;
      if ( verb>1 ) fprintf('%d) Dropped %d Frame(s)!!!\n',ei,ei-oei); end;
      ndropped=ndropped+(ei-oei);
    end
	 
	 % update the display on the backing store
	 curStim(frmi)= ei;
    oss   = ss;
    ss    = stimSeq(:,curStim(frmi));
	 if ( ~isempty(colors) )
		if(any(ss==0)) % everybody starts as background color
		  Screen('Drawtextures',wPtr,h(ss==0),srcR(:,ss==0),destR(:,ss==0),[],[],[],bgColor*255); 
		end 
		if(any(ss==1)) % stimSeq codes into a colortable
		  Screen('Drawtextures',wPtr,h(ss==1),srcR(:,ss==1),destR(:,ss==1),[],[],[],colors(:,1)*255); 
		end
		if(any(ss==2))
		  Screen('Drawtextures',wPtr,h(ss==2),srcR(:,ss==2),destR(:,ss==2),[],[],[],...
					colors(:,min(size(colors,2),2))*255);
		end;
		if(any(ss==3))
		  Screen('Drawtextures',wPtr,h(ss==3),srcR(:,ss==3),destR(:,ss==3),[],[],[],...
					colors(:,min(size(colors,2),3))*255);
		end
	 else % continuous shade stimulus
		for hi=find(ss>=0)';		
		  Screen('Drawtextures',wPtr,h(hi),srcR(:,hi),destR(:,hi),[],[],[],...
					ss(hi)*[1 1 1]*255);
		end
    end
    Screen('Drawtextures',wPtr,h(end),srcR(:,end),destR(:,end),[],[],[],bgColor*255);
	 % sleep until stim time & then draw the display
	 ft=getwTime();
    sleepSec(max(0,repStartTime+stimTime(ei)-ft)); 
    Screen('flip',wPtr,1,1);% re-draw the display
    %fprintf('%d) ei=%d st=%g ft=%g sleep=%g\n',frmi,ei,stimTime(ei)+repStartTime-seqStartTime,ft-seqStartTime,repStartTime+stimTime(ei)-ft),

	 % record event info about this stimulus to send later so don't delay stimulus
	 if ( isempty(eventSeq) || (numel(eventSeq)>ei && eventSeq(ei)>0) )
		samp=buffer('get_samp'); % get sample at which display updated
		% total stimulus state
		evti=evti+1; stimEvts(evti)=mkEvent('stimulus.stimState',ss,samp); 
		% indicate if 'target' flash		
		evti=evti+1; stimEvts(evti)=mkEvent('stimulus.tgtState',ss(tgtId)>0,samp); 
	 end
	 % check for exit condition
    if ( ~ishandle(fig) ) break; end; % exit cleanly if exit event
  end
  if ( verb>=0 && ndropped>0) fprintf('Dropped %d Frame(s)!!!\n',ndropped); end;
  sleepSec(seqEndDuration);  
  % send all the stimulus events in one go
  buffer('put_evt',stimEvts(1:evti));
  if ( verb>1 ) fprintf('StimSeq: %s\n',ev2str(stimEvts(1:evti))); end;
  fprintf('\n');
  
  % reset the cue and fixation point to indicate trial has finished  
  if ( ~ishandle(fig) ) break; end;
  Screen('flip',wPtr);% re-draw the display
  sendEvent('stimulus.trial','end');
  sleepSec(interSeqDuration);  
end % sequences
