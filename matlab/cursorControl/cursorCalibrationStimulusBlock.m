% make stim seq with an extra invisible symbol to increase the ISI
switch ( stimType )

  case {'p300','p3','p3-rand'};
	 [stimSeq,stimTime,eventSeq,colors]=mkStimSeqRand(nSymbs,seqDuration,isi);

  case 'p3-radial';
	 [stimSeq,stimTime,eventSeq,colors]=mkStimSeqScan(nSymbs,seqDuration,isi);

  case 'p3-90';
	 [stimSeq,stimTime,eventSeq,colors]=mkStimSeqScan(nSymbs,seqDuration,isi);
	 % shuffle order to be 90-deg out scan
	 nSkip=ceil(nSymbs/3); si=zeros(nSymbs,1); 
    i=1;j=1;while(any(si==0)); si(mod(j-1,nSymbs)+1)=i; i=i+1; j=j+nSkip; if(si(mod(j-1,nSymbs)+1)>0) j=j+1; end; end 
	 stimSeq=stimSeq(si,:);

  case 'ssvep';
	 % N.B. for periods < 4 you get horrible Aliasing artifacts in the stimulus sequence!
	 ssepPeriod=[1./ssepFreq/isi]'; % frequency -> duration in samples
	 ssepPeriod=[ssepPeriod(:) ssepPhase(:)/2/pi.*ssepPeriod(:)]; % radians -> offset in samples
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
set(instructh,'string',{'Press any key to continue to the next block.' blkNm},'visible','on');
waitkey;set(instructh,'visible','off');pause(1);
if ( verb>0 ) 
   fprintf('\n-------------\nStarting stimulus: %s\n--------------\n',blkNm);
end
sendEvent('stimulus.stimType',blkNm);
frametime=[]; nframe=0; curStimState=zeros(nSymbs,1);
for si=1:nSeq;

  if ( ~ishandle(fig) ) break; end;
  
  % show the screen to alert the subject to trial start
  set(h,'visible','on','facecolor',bgColor,'edgeColor',bgColor);
  set(h(end),'visible','on','facecolor',fixColor); % red fixation indicates trial about to start/baseline
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');

  % show the target  
  tgtId=find(tgtSeq(:,si)>0);
  fprintf('%d) tgt=%d : ',si,tgtId);
  set(h,'visible','on','facecolor',bgColor);
  set(h(tgtId),'facecolor',tgtColor,'edgeColor',tgtColor);
  set(h(tgtSeq(:,si)<=0),'facecolor',bgColor,'edgeColor',bgColor);
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  ev=sendEvent('stimulus.target',tgtId);
  if ( verb>1 ) fprintf('Sending target : %s\n',ev2str(ev)); end;
  sleepSec(cueDuration);
  set(h,'facecolor',bgColor);
  drawnow;
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
      if ( verb>=0 ) fprintf('%d) Dropped %d Frame(s)!!!\n',ei,ei-oei); end;
      ndropped=ndropped+(ei-oei);
    end
	 
	 % update the display on the backing store
	 curStim(frmi)= ei;
    oss   = ss;
    ss    = stimSeq(:,curStim(frmi));
    set(h(ss<0), 'visible','off');  % neg stimSeq codes for invisible stimulus
    set(h(ss>=0),'visible','on');
	 if ( ~isempty(colors) )
		if(any(ss==0))set(h(ss==0),'facecolor',bgColor); end % everybody starts as background color
		if(any(ss==1))set(h(ss==1),'facecolor',colors(:,1)); end% stimSeq codes into a colortable
		if(any(ss==2))set(h(ss==2),'facecolor',colors(:,min(size(colors,2),2)));end;
		if(any(ss==3))set(h(ss==3),'facecolor',colors(:,min(size(colors,2),3)));end;
	 else % continuous shade stimulus
		for hi=find(ss>=0)';		
		  set(h(hi),'facecolor',ss(hi)*[1 1 1]);
		end		  
	 end
	 % sleep until stim time & then draw the display
	 ft=getwTime();
    sleepSec(max(0,repStartTime+stimTime(ei)-ft)); 
    drawnow; 
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
  set(h(:),'facecolor',bgColor,'visible','off');
  drawnow;
  sendEvent('stimulus.trial','end');
  sleepSec(interSeqDuration);  
end % sequences
