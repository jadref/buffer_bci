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
trialDuration=15;
interTrialDuration=3;

                                % durations for the labelling
eventInterval    =.25; % send event every this long...
startupArtDur    =1;
endArtDur        =1;
nonMoveLowerBound=-2;
nonMoveUpperBound=.5;
moveLowerBound   =-.5;
moveUpperBound   =.25;

% make the stimulus
clf;
fig=gcf;
set(fig,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
axes('position',[0 0 1 1],'visible','off','xlim',[0 1],'ylim',[0 1],'nextplot','add','color',[0 0 0]);

% fix pos
msgh=text(.5,.5,'+','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','normalized','fontsize',.2,'color',[1 1 1],'visible','off'); 
% score
scoreh=text(0,.9,'','HorizontalAlignment','left','verticalAlignment','top',...
            'FontUnits','normalized','fontsize',.2,'color',[1 1 1],'visible','off');

% install listener for key-press mode change
set(fig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
set(fig,'userdata',[]);

set(msgh,'string','press button to begin','visible','on');drawnow;
waitforbuttonpress;
set(msgh,'string','');
drawnow;

score=[0 0]; % current score, [computer, human]
set(scoreh,'visible','on','string',sprintf('%d/%d  you=%3d  comp=%3d',0,nSeq,score));

human_stats=struct('N',0,'sx',0,'sx2',0,'mu',0,'var',0);

% play the stimulus
sendEvent('stimulus.buttonpress','start');
for si=1:nSeq;

          % reset the cue and fixation point to indicate trial has finished  
  set(msgh,'string','+','visible','off');
  drawnow;
  % inter-trial
  sleepSec(interTrialDuration);

                                % baseline
  set(msgh,'string','+','visible','on','color',[1 0 0]); drawnow;
  set(scoreh,'visible','on','string',sprintf('%d/%d  you=%3d  comp=%3d',si,nSeq,score)); % update the score
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);

                                % trial-start
  set(msgh,'color',[1 1 1]); drawnow; % indicate trial-start
  sendEvent('stimulus.trial','start');
  samp0=buffer('poll');samp0=samp0.nSamples;
  t0=getwTime(); % get time trial start
                 % run the waiting loop
  t_now=0;
  t_human=inf; 
  % decide on the computer move time estimate
  t_computer=(.3+(1-.3)*rand(1))*trialDuration; % simple uniform rand for now..
  
  %------------------------------------- Run the trial ------------------------------
  while ( t_now < trialDuration ) % until trial end
    t_now = getwTime()-t0; % current trial-time
    
    % process human key-presses
    modekey=get(fig,'userdata'); 
    if ( ~isempty(modekey) ) t_human = t_now; set(fig,'userdata',[]); end;

    % update the time-display
    set(msgh,'string',sprintf('%f3.1',t_now));

    % update the color+score to reflect who-moved-first
    if( t_computer < t_human && t_computer < t_now ) % computer won
       set(msgh,'color',compWinsColor);
       score(2) = score(2) + t_computer;
       mevt=sendEvent('response.button','computer'); % send info event
    end
    if( t_human < t_computer && t_human < t_now ) % human won
       set(msgh,'color',humanWinsColor);
       score(1) = score(1) + t_human; 
       mevt=sendEvent('response.button','human'); % send info event
    end
  end
  % get time, send event, give-user feedback
  t_move=getwTime()-t0; % move time, rel trial start
  set(scoreh,'visible','on','string',sprintf('%d/%d  you=%3d  comp=%3d',si,nSeq,score)); % update the score
  drawnow;
  samp_move=mevt.sample;
  % wait for end of trial
  if( t_now < trialDuration )
    sleepSec(trialDuration-t_now);
  end
  t_end = getwTime()-t0;
  t_move = min(t_human,t_computer); % move time for either party

  % --------------------------  send the labelling events ----------------------------------
  nSamp=buffer('poll');
  if( t_human<t_computer )  % human moved:     startupArt < t < t_human - nonMoveLowerBound
     t_evt=startupArtDur:eventInterval:t_human+nonMoveLowerBound; 
  else                      % computer moved:  startupArt < t < t_computer
     t_evt=startupArtDur:eventInterval:t_computer;
  end  
  for ei=1:numel(t_evt);
    tei     = t_evt(ei);
    samp_evt= tei*(samp_move-samp0)./(t_human) + samp0; % linearly interpolate the event sample number
    sendEvent('stimulus.target','nonmove',samp_evt);
  end
  if( t_human < t_computer ) % human moved : t_move + moveLowerBound < t < t_human+moveUpperBound
     t_evt=t_human+moveLowerBound:eventInterval:t_human+moveUpperBound;
     for ei=1:numel(t_evt);
        tei     = t_evt(ei);
        samp_evt= tei*(samp_move-samp0)./(t_human) + samp0; 
        sendEvent('stimulus.target','move',samp_evt);
     end
  end
  % post move
  % t_move + nonMoveUpperBound < t < end-endArt
  t_evt=t_move+nonMoveUpperBound:eventInterval:t_end+endArtDur;
  for ei=1:numel(t_evt);
    tei     = t_evt(ei);
    samp_evt= tei*(samp_move-samp0)./(t_move) + samp0; 
    sendEvent('stimulus.target','nonmove',samp_evt);
  end
  sendEvent('stimulus.trial','end');

  %-------------------------------------- update the human move tracking stats
  % TODO [] : add a forgetting factor? moving-window estimate?
  if( t_human < t_computer ) % actual move
     human_stats.N   = human_stats.N  + 1;
     human_stats.sx  = human_stats.sx + t_human;
     human_stats.sx2 = human_stats.sx2+ t_human.^2;
     human_stats.mu  = human_stats.sx ./ human_stats.N; % mean
     human_stats.var = (human_stats.sx2 - human_stats.sx.^2./human_stats.N)./human_stats.N; %var
  end
    
end % sequences
% end training marker
sendEvent('stimulus.sentences','end');
