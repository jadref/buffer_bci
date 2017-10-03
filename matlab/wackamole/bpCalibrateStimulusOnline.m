try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end

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
nSeq = 20;
baselineDuration = 2;
maxTrialDuration=15;
interTrialDuration=3;

                                % durations for the labelling
eventInterval    =.25; % send event every this long...
startupArtDur    =1;
nonMoveLowerBound=-2;
moveLowerBound   =-.5;
moveUpperBound   =.25;

% make the stimulus
clf;
set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
set(gca,'visible','off','color',[0 0 0]); % black axes
h=text(.5,.5,'+','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','normalized','fontsize',.2,'color',[1 1 1],'visible','off'); 

% play the stimulus
sendEvent('stimulus.buttonpress','start');
for si=1:nSeq;
      
  % reset the cue and fixation point to indicate trial has finished  
  set(h,'visible','off');
  drawnow;
  % inter-trial
  sleepSec(interTrialDuration);

                                % baseline
  set(h,'visible','on','color',[1 0 0]); drawnow;
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);

                                % trial-start
  set(h,'color',[1 1 1]); drawnow; % indicate trial-start
  sendEvent('stimulus.trial','start');
  
  t0=getwTime(); % get time trial start
  t_move=inf; % move time
  ttg=trialDuration;
  pendingEvts=[]; t_pending=0;
  while ( t_now < trialDuration ) % until trial end
    t_now = getwTime()-t0; % current trial-time
                                % add new events to pending
    if( t_now > t_pending(end)+eventInterval )
      s_now = buffer('poll'); % current sample count
      pendingEvts(end+1);=mkEvent('stimulus.target','undef',s_now);
      t_pending(numel(pendingEvts))=t_now;
    end

    % check for button presses...
    %t_move=t_now;

               % check if any events can be removed from the front of pending    
    procEvts=false(1,numel(pendingEvts));
    for pevti=1:numel(pendingEvts);
      evtProcessed=false;
      t_pevti=t_pending(pevti) 

      if( t_pevti<startupArtDur ) % discard if too soon after start
        evtProcessed=true;
      elseif( t_pevti< t_now+nonMoveLowerBound & t_pevti < t_move+nonMoveLowerBound ) % def-non-move, before move
        evtProcessed=true;
        pendingEvts(pevti).value = 'nonmove';
        sendEvent(pendingEvents(pevti));
      elseif( t_pevti < t_now+moveLowerBound & t_pevti < t_move + moveLowerBound ) % def- unsure
        evtProcessed = true;
      elseif( t_pevti > t_move+moveLowerBound & t_pevti < t_move + moveUpperBound ) % def move
        evtProcessed = true;
        pendingEvts(pevti).value = 'move';
        sendEvent(pendingEvents(pevti));
      elseif( t_pevti > t_move + moveUpperBound & t_pevti < trialDuration - artEnd ) % def non-move, after move
        evtProcessed = true;
        pendingEvts(pevti).value = 'nonmove';
        sendEvent(pendingEvents(pevti));
      end

      if( ~evtProcessed ) % stop at first event we can't yet label
        break;
      end
      procEvts(pevti)=true; % mark as processed to remove
    end
    if( any(procEvts) ) pendingEvts(procEvts)=[]; t_pending(procEvts)=[]; end; % remove proc events from pending queue    
  end
  sendEvent('stimulus.trial','end');
  
  % wait for a key press
  
end % sequences
% end training marker
sendEvent('stimulus.sentences','end');
