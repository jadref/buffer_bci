try; cd(fileparts(mfilename('fullpath')));catch; end;
run ../../utilities/initPaths.m

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

% make the target sequence
nSeq=5;
nEpoch=10;
stimSeq=zeros(nEpoch,nSeq);
for si=1:nSeq;
  [ans,ans,ans,ans,stimCode]=mkStimSeqRand(2,nEpoch,[],0);
  stimSeq(:,si)=stimCode;
end
interSeqDuration=3;
interEpochDuration=1;

% make the stimulus
clf;
set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
set(gca,'visible','off','color',[0 0 0]); % black axes
h=rectangle('curvature',[1 1],'position',[.25 .25 .5 .5],'facecolor',[.5 .5 .5]);
set(h,'visible','off');

% play the stimulus
sendEvent('stimulus.sequences','start');
for si=1:size(stimSeq,2);
  sequence=stimSeq(:,si);
      
  % reset the cue and fixation point to indicate trial has finished  
  set(h,'visible','off');
  drawnow;
  sendEvent('stimulus.sequence',sequence);
  
  % loop over events in the sequence
  set(h,'visible','on');
  drawnow;
  for ci=1:numel(sequence);
    epoch = sequence(ci);
    sendEvent('stimulus.epoch',epoch);
    if ( epoch==1 ) 
      set(h,'facecolor',[1 1 1]);
    else
      set(h,'facecolor',[.5 .5 .5]);
    end
    drawnow;
    fprintf('%d',epoch);
    sleepSec(interEpochDuration);
  end
  sleepSec(interSeqDuration);
  
  % wait for a key press
  msg=msgbox({'Press OK to continue'},'Continue?');while ishandle(msg); pause(.2); end;
  
end % sequences
% end training marker
sendEvent('stimulus.sequences','end');
% tell user we're done
msg=msgbox({'Thanks for taking part!'},'Continue?');while ishandle(msg); pause(.2); end;
