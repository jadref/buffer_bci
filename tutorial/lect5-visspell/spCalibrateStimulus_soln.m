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

verb=0;
nSeq=15;
nRepetitions=5;  % the number of complete row/col stimulus before sequence is finished
cueDuration=2;
stimDuration=.2; % the length a row/col is highlighted
interSeqDuration=2;
bgColor=[.5 .5 .5]; % background color (grey)
flashColor=[1 1 1]; % the 'flash' color (white)
tgtColor=[0 1 0]; % the target indication color (green)

% the set of options the user will pick from
symbols={'1' '2' '3';...
         '4' '5' '6';...
         '7' '8' '9'}';

% make the stimulus
clf;
[h]=initGrid(symbols);

% make the target stimulus sequence
[ans,ans,ans,ans,tgtSeq]=mkStimSeqRand(numel(symbols),nSeq);
% make the row/col flash sequence for each sequence
[stimSeqRow]=mkStimSeqRand(size(symbols,1),nRepetitions*size(symbols,1),2);
[stimSeqCol]=mkStimSeqRand(size(symbols,2),nRepetitions*size(symbols,2),2);

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'color',[.5 .5 .5]);
sendEvent('stimulus.training','start');
for si=1:nSeq;

  sleepSec(interSeqDuration);
  sendEvent('stimulus.sequence','start');
  % show the subject cue where to attend
  [tgtRow,tgtCol]=ind2sub(size(symbols),tgtSeq(si)); % convert to row/col index
  set(h(tgtRow,tgtCol),'color',tgtColor);
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.targetSymbol',symbols{tgtSeq(si)});
  fprintf('%d) tgt=%s : ',si,symbols{tgtSeq(si)}); % debug info
  sleepSec(cueDuration);  
  set(h(:),'color',bgColor); % rest all symbols to background color
  
  % rows stimulus
  for ei=1:size(stimSeqRow,2);
    set(h(:),'color',bgColor);
    set(h(stimSeqRow(:,ei)>0,:),'color',flashColor);
    drawnow;
    ev=sendEvent('stimulus.rowFlash',stimSeqRow(:,ei)); % indicate this row is 'flashed'
    sendEvent('stimulus.tgtFlash',stimSeqRow(tgtRow,ei),ev.sample); % indicate if it was a 'target' flash
    sleepSec(stimDuration);
  end
  
  % cols stimulus
  for ei=1:size(stimSeqCol,2);
    set(h(:),'color',bgColor);
    set(h(:,stimSeqCol(:,ei)>0),'color',flashColor);
    drawnow;
    ev=sendEvent('stimulus.colFlash',stimSeqCol(:,ei)); % indicate this row is 'flashed'
    sendEvent('stimulus.tgtFlash',stimSeqCol(tgtCol,ei),ev.sample); % indicate if it was a 'target' flash
    sleepSec(stimDuration);
  end
   
  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'color',bgColor);
  drawnow;
  sendEvent('stimulus.sequence','end');  
end % sequences
% end training marker
sendEvent('stimulus.training','end');
