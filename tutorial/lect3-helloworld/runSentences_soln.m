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
sentences={'hello world','this is new!','BCI is fun!'};
interSentenceDuration=3;
interCharDuration=1;

% make the stimulus
clf;
set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
set(gca,'visible','off','color',[0 0 0]); % black axes
h=text(.5,.5,'text','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','normalized','fontsize',.2,'color',[1 1 1],'visible','off'); 

% play the stimulus
sendEvent('stimulus.sentences','start');
for si=1:numel(sentences);
  sentence=sentences{si};
      
  % reset the cue and fixation point to indicate trial has finished  
  set(h,'visible','off');
  drawnow;
  sendEvent('stimulus.sentence',sentence);
    
  % loop over characters in the sentence
  for ci=1:numel(sentence);
    char = sentence(ci);
    sendEvent('stimulus.character',char);
    set(h,'string',sentence(1:ci),'visible','on');drawnow;
    sleepSec(interCharDuration);
  end
  sleepSec(interSentenceDuration);
  
  % wait for a key press
  msg=msgbox({'Press OK to continue'},'Continue?');while ishandle(msg); pause(.2); end;
  
end % sequences
% end training marker
sendEvent('stimulus.sentences','end');
% tell user we're done
msg=msgbox({'Thanks for taking part!'},'Continue?');while ishandle(msg); pause(.2); end;
