configureSpeller();

% make the stimulus
ws=Screen('windows'); % re-use existing window if there
if ( isempty(ws) )
  screenNum = max(Screen('Screens')); % get 2nd display
  wPtr= Screen('OpenWindow',screenNum,bgColor,windowPos)
  Screen('BlendFunction',wPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA); % enable alpha blending
  [flipInterval nrValid stddev]=Screen('GetFlipInterval',wPtr); % get flip-time (i.e. refresh rate)
end

% make the stimuli
[texels srcR destR]=mkTextureGrid(wPtr,symbols);
flash=false(size(symbols)); %logical indicator of current flash state

% make the row/col flash sequence for each sequence
[stimSeqRow,stimTimeRow]=mkStimSeqRand(vnRows,nRepetitions*vnRows,stimDuration);
stimSeqRow(size(symbols,1)+1:end,:)=[];  % remove the extra symbol(s)
[stimSeqCol,stimTimeCol]=mkStimSeqRand(vnCols,nRepetitions*vnCols,stimDuration);
stimSeqCol(size(symbols,2)+1:end,:)=[];  % remove the extra symbol(s)

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
% reset the cue and fixation point to indicate trial has finished  
Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],[.5 .5 .5]*255); 
Screen('flip',wPtr);% re-draw the display
sendEvent('stimulus.training','start');
stimSeq=zeros([size(symbols),size(stimSeqRow,2)+size(stimSeqCol,2)]); % for decoding
for si=1:nSeq;

  nFlash = 0; stimSeq(:)=0;
  Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
  Screen('flip',wPtr);% re-draw the display
  sleepSec(interSeqDuration);
  sendEvent('stimulus.sequence','start');
  
  if( verb>0 ) fprintf(1,'Rows'); end;
  % rows stimulus
  for ei=1:size(stimSeqRow,2);
    % record the stimulus state, needed for decoding the classifier predictions later
    nFlash=nFlash+1;
    flash(:)=false; flash(stimSeqRow(:,ei)>0,:)=true; % indicator for which symbols are flashed now
    stimSeq(:,:,nFlash)=flash;
    Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
    if (any(flash(:)) ) 
      Screen('Drawtextures',wPtr,texels(flash),srcR(:,flash),destR(:,flash),[],[],[],flashColor*255); 
    end
    Screen('flip',wPtr);
    sendEvent('stimulus.rowFlash',stimSeqRow(:,ei)); % indicate this row is 'flashed'    
    sleepSec(stimDuration);
  end

  if( verb>0 ) fprintf(1,'Cols');end
  % cols stimulus
  for ei=1:size(stimSeqCol,2);
    % record the stimulus state, needed for decoding the classifier predictions later
    nFlash=nFlash+1;
    flash(:)=false; flash(:,stimSeqCol(:,ei)>0)=true; % indicator for which symbols are flashed now
    stimSeq(:,:,nFlash)=flash;
    Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
    if (any(flash(:)) ) 
      Screen('Drawtextures',wPtr,texels(flash),srcR(:,flash),destR(:,flash),[],[],[],flashColor*255); 
    end
    Screen('flip',wPtr);
    sendEvent('stimulus.colFlash',stimSeqCol(:,ei)); % indicate this row is 'flashed'
    sleepSec(stimDuration);    
  end
   
  % reset the cue and fixation point to indicate trial has finished  
  Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
  Screen('flip',wPtr);
  sleepSec(trlen_ms/1000-stimDuration+.2);  % wait long enough for classifier to finish up..
  sendEvent('stimulus.sequence','end');

  % combine the classifier predictions with the stimulus used
  % wait for the signal processing pipeline to return the sequence of epoch predictions
  if( verb>0 ) fprintf(1,'Waiting for predictions\n'); end;
  [data,devents,state]=buffer_waitData(buffhost,buffport,[],'exitSet',{1000 'classifier.prediction'});
  if ( 0 && isempty(devents) ) devents=mkEvent('prediction',randn(nFlash,1)); end; % testing code ONLY
  if ( ~isempty(devents) ) 
    % correlate the stimulus sequence with the classifier predictions to identify the most likely
    % N.B. assume last prediction is one for prev sequence  
    corr = reshape(stimSeq(:,:,1:nFlash),[numel(symbols) nFlash])*devents(end).value(:); 
    [ans,predTgt] = max(corr); % predicted target is highest correlation
  
    % show the classifier prediction
    Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
    Screen('Drawtextures',wPtr,texels(predTgt),srcR(:,predTgt),destR(:,predTgt),[],[],[],tgtColor*255); 
    Screen('flip',wPtr);% re-draw the display
    sendEvent('stimulus.prediction',symbols{predTgt});
  end
  sleepSec(feedbackDuration);
    
  fprintf('\n');
end % sequences
% end training marker
sendEvent('stimulus.feedback','end');
uiwait(msgbox({'That ends the testing phase.','Thanks for your patience'},'Thanks','modal'),10);
pause(1);
if ( isempty(windowPos) ) Screen('closeall'); end; % close display if fullscreen