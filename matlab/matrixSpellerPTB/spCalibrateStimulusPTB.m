configureSpeller;

% make the stimulus
ws=Screen('windows'); % re-use existing window 
if ( isempty(ws) )
  screenNum = max(Screen('Screens')); % get 2nd display
  wPtr= Screen('OpenWindow',screenNum,bgColor,windowPos)
  Screen('BlendFunction',wPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA); % enable alpha blending
  [flipInterval nrValid stddev]=Screen('GetFlipInterval',wPtr); % get flip-time (i.e. refresh rate)
end

% make the stimuli
[texels srcR destR]=mkTextureGrid(wPtr,symbols);
flash=false(size(symbols)); %logical indicator of current flash state

% make the target stimulus sequence
[ans,ans,ans,ans,tgtSeq]=mkStimSeqRand(numel(symbols),nSeq);
% make the row/col flash sequence for each sequence
[stimSeqRow,stimTimeRow]=mkStimSeqRand(vnRows,nRepetitions*vnRows,stimDuration);
stimSeqRow(size(symbols,1)+1:end,:)=[];  % remove the extra symbol(s)
[stimSeqCol,stimTimeCol]=mkStimSeqRand(vnCols,nRepetitions*vnCols,stimDuration);
stimSeqCol(size(symbols,2)+1:end,:)=[];  % remove the extra symbol(s)

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],[.5 .5 .5]*255); 
Screen('flip',wPtr);% re-draw the display
sendEvent('stimulus.training','start');
for si=1:nSeq;

  sleepSec(interSeqDuration);
  sendEvent('stimulus.sequence','start');
  % show the subject cue where to attend
  [tgtRow,tgtCol]=ind2sub(size(symbols),tgtSeq(si)); % convert to row/col index
  
  Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
  Screen('Drawtextures',wPtr,texels(tgtSeq(si)),srcR(:,tgtSeq(si)),destR(:,tgtSeq(si)),[],[],[],tgtColor*255); 
  Screen('flip',wPtr);% re-draw the display
  sendEvent('stimulus.targetSymbol',symbols{tgtSeq(si)});
  fprintf('%d) tgt=%s : ',si,symbols{tgtSeq(si)}); % debug info
  sleepSec(cueDuration);  
  
  % rows stimulus
  for ei=1:size(stimSeqRow,2);
    flash(:)=false; flash(stimSeqRow(:,ei)>0,:)=true; % indicator for which symbols are flashed now
    Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
    if (any(flash(:)) ) 
      Screen('Drawtextures',wPtr,texels(flash),srcR(:,flash),destR(:,flash),[],[],[],flashColor*255); 
    end
    Screen('flip',wPtr);
    ev=sendEvent('stimulus.rowFlash',stimSeqRow(:,ei)); % indicate this row is 'flashed'
    sendEvent('stimulus.tgtFlash',flash(tgtSeq(si)),ev.sample); % indicate if it was a 'target' flash
    sleepSec(stimDuration);
  end
  
  % cols stimulus
  for ei=1:size(stimSeqCol,2);
    flash(:)=false; flash(:,stimSeqCol(:,ei)>0)=true; % indicator for which symbols are flashed now
    Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
    if (any(flash(:))) % sometimes *nothing* is flashed
      Screen('Drawtextures',wPtr,texels(flash),srcR(:,flash),destR(:,flash),[],[],[],flashColor*255); 
    end
    Screen('flip',wPtr);
    ev=sendEvent('stimulus.colFlash',stimSeqCol(:,ei)); % indicate this row is 'flashed'
    sendEvent('stimulus.tgtFlash',flash(tgtSeq(si)),ev.sample); % indicate if it was a 'target' flash
    sleepSec(stimDuration);
  end
   
  % reset the cue and fixation point to indicate trial has finished  
  Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
  Screen('flip',wPtr);
  sendEvent('stimulus.sequence','end');
end % sequences
Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
Screen('flip',wPtr);
% end training marker
sendEvent('stimulus.training','end');
if ( isempty(windowPos) ) Screen('closeall'); end; % close display if fullscreen
