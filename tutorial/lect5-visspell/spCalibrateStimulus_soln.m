try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end
try; cd(fileparts(mfilename('fullpath')));catch; end; %ARGH! fix bug with paths on Octave

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
nSeq=6;
nRepetitions=5;  % the number of complete row/col stimulus before sequence is finished
cueDuration=2;
stimDuration=.2; % the length a row/col is highlighted
interSeqDuration=2;
bgColor=[.5 .5 .5]; % background color (grey)
flashColor=[1 1 1]; % the 'flash' color (white)
tgtColor=[0 1 0]; % the target indication color (green)

% the set of options the user will pick from
symbols={'A' 'B' 'C' 'D'};

% make the stimulus
clf;
[h]=initGrid(symbols);

tgtSeq = repmat([1:numel(symbols)]',ceil(nSeq/numel(symbols)));
tgtSeq = randperm(tgtSeq(1:nSeq));

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'color',[.5 .5 .5]);
sendEvent('stimulus.training','start');
for si=1:nSeq;

  sleepSec(interSeqDuration);
  sendEvent('stimulus.sequence','start');
  % show the subject cue where to attend
  tgtIdx=tgtSeq(si);
  set(h(tgtIdx),'color',tgtColor);
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.targetSymbol',symbols{tgtIdx});
  fprintf('%d) tgt=%s : ',si,symbols{tgtSeq(si)}); % debug info
  sleepSec(cueDuration);  
  set(h(:),'color',bgColor); % rest all symbols to background color
  
  for ri=1:nRep; % reps
    for ei=1:numel(symbols); % symbs
      flashIdx=ei;
      % flash
      set(h(:),'color',bgColor);
      set(h(flashIdx),'color',flashColor);
      drawnow;
      ev=sendEvent('stimulus.flash',symbols{flashIdx}); % indicate this row is 'flashed'
      sendEvent('stimulus.tgtFlash',flashIdx==tgtIdx,ev.sample); % indicate 'target' flashs
      sleepSec(stimDuration);
      % reset
      set(h(:),'color',bgColor);
      drawnow;
      sleepSec(stimDuration);      
    end
  end
   
  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'color',bgColor);
  drawnow;
  sendEvent('stimulus.sequence','end');
  fprintf('\n');
end % sequences
% end training marker
sendEvent('stimulus.training','end');
