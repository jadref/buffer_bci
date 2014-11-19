run ../../utilities/initPaths.m;

buffhost='localhost';buffport=1972;
% wait for the buffer to return valid header information
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
  try 
    hdr=buffer('get_hdr',[],buffhost,buffport); 
  catch
    hdr=[];
    fprintf('Invalid header info... waiting.\n');
  end;
  pause(1);
end;

% set the real-time-clock to use
initgetwTime;
initsleepSec;

verb=1;
nSeq=15;
nRepetitions=5;  % the number of complete row/col stimulus before sequence is finished
cueDuration=2;
stimDuration=.2; % the length a row/col is highlighted
dataDuration=.6; % lenght of the data that the sig processing needs
interSeqDuration=2;
feedbackDuration=2; % length of time feedback is on the screen
bgColor=[.5 .5 .5]; % background color (grey)
flashColor=[1 1 1]; % the 'flash' color (white)
tgtColor=[0 1 0]; % the target indication color (green)

% the set of options the user will pick from
symbols={'1' '2' '3';...
         '4' '5' '6';...
         '7' '8' '9'};

% make the stimulus
clf;
[h,symbs]=initGrid(symbols);

% make the row/col flash sequence for each sequence
[stimSeqRow]=mkStimSeqRand(size(symbols,1),nRepetitions*size(symbols,1));
[stimSeqCol]=mkStimSeqRand(size(symbols,2),nRepetitions*size(symbols,2));

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
state=hdr.nEvents; % ignore all prediction events before this time
set(h(:),'color',[.5 .5 .5]);
sendEvent('stimulus.training','start');
for si=1:nSeq;

  nFlash = 0; stimSeq=zeros(size(symbols));
  set(h(:),'color',bgColor); % rest all symbols to background color
  sleepSec(interSeqDuration);
  sendEvent('stimulus.sequence','start');
  
  if( verb>0 ) fprintf(1,'Rows'); end;
  % rows stimulus
  for ei=1:size(stimSeqRow,2);
    % record the stimulus state, needed for decoding the classifier predictions later
    nFlash=nFlash+1;
    stimSeq(stimSeqRow(:,ei)>0,:,nFlash)=true;
    % set the stimulus state
    set(h(:),'color',bgColor);
    set(h(stimSeqRow(:,ei)>0,:),'color',flashColor);
    drawnow;
    sendEvent('stimulus.rowFlash',stimSeqRow(:,ei)); % indicate this row is 'flashed'    
    sleepSec(stimDuration);
  end

  if( verb>0 ) fprintf(1,'Cols');end
  % cols stimulus
  for ei=1:size(stimSeqCol,2);
    % record the stimulus state, needed for decoding the classifier predictions later
    nFlash=nFlash+1;
    stimSeq(:,stimSeqCol(:,ei)>0,nFlash)=true;
    % set the stimulus state
    set(h(:),'color',bgColor);
    set(h(:,stimSeqCol(:,ei)>0),'color',flashColor);
    drawnow;
    sendEvent('stimulus.colFlash',stimSeqCol(:,ei)); % indicate this row is 'flashed'
    sleepSec(stimDuration);    
  end
   
  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'color',bgColor);
  drawnow;
  sleepSec(dataDuration-stimDuration);    
  sendEvent('stimulus.sequence','end');

  % combine the classifier predictions with the stimulus used
  % wait for the signal processing pipeline to return the sequence of epoch predictions
  if( verb>0 ) fprintf(1,'Waiting for predictions\n'); end;
  [devents,state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],500);
  if ( ~isempty(devents) ) 
    % correlate the stimulus sequence with the classifier predictions to identify the most likely letter
    % N.B. assume last prediction is one for prev sequence  
    corr = reshape(stimSeq(:,:,1:nFlash),[numel(symbols) nFlash])*devents(end).value(:); 
    [ans,predTgt] = max(corr); % predicted target is highest correlation
  
    % show the classifier prediction
    set(h(predTgt),'color',tgtColor);
    drawnow;
    sendEvent('stimulus.prediction',symbols{predTgt});
  end
  sleepSec(feedbackDuration);
end % sequences
% end training marker
sendEvent('stimulus.feedback','end');
