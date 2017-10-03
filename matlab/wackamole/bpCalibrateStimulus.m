% finger pressing game stimulus

try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end

neutralColor  =[.8 .8 .8];
compWinsColor =[1 0 0];
humanWinsColor=[0 1 0];
instruct={'Welcome to our wack-a-mole game' 
          ''
          'You will see a circle which grows slowly over time.'
          'Bigger circle = more money!'
          'Whoever presses the button first grabs the'
          'current pile.'
          ''
          'The computer *learns* how you move and tries'
          'move just before you to steal your money!'
          ''
          'To maximise your score wait as long as you can'
          'whilst remaining unpredictable!'
          ''
          'Press <space> to continue.'};


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
nonMoveUpperBound=.75;
moveLowerBound   =-.5;
moveUpperBound   =.25;

% make the stimulus
clf;
fig=gcf;
set(fig,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
set(fig,'Units','pixel');wSize=get(fig,'position');fontSize = .05*wSize(4);
axes('position',[0 0 1 1],'visible','off','xlim',[0 1],'ylim',[0 1],'nextplot','add','color',[0 0 0]);

% feedback circle
% equation to compute the size of the feedback,
%  scale to fit full screen at trialDuration
pilerfn=@(score) score*(1-.1)*(.8/trialDuration)+.1; 
pile_r =pilerfn(0);
pileh=rectangle('position',[.5-pile_r/2 .5-pile_r/2 pile_r pile_r],'curvature',[1 1],'facecolor',neutralColor,'visible','off');
% fix pos
msgh=text(.5,.5,'+','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','pixel','fontsize',.05*wSize(4),'color',[1 1 1],'visible','off'); 
% score
scoreh=text(0,1,'','HorizontalAlignment','left','verticalAlignment','top',...
            'FontUnits','pixel','fontsize',.1*wSize(4),'color',[1 1 1],'visible','off');

% install listener for key-press mode change
set(fig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
set(fig,'userdata',[]);

set(pileh,'visible','off'); set(scoreh,'visible','off');
set(msgh,'string',instruct,'visible','on');drawnow;
waitforbuttonpress;
set(msgh,'string','');
drawnow;

score=[0 0]; % current score, [computer, human]
set(scoreh,'visible','on','string',sprintf('%d/%d    you=%3g   comp=%3g',0,nSeq,score));

human_stats=struct('N',0,'sx',0,'sx2',0,'mu',0,'var',0);

% play the stimulus
sendEvent('stimulus.buttonpress','start');
for si=1:nSeq;

          % reset the cue and fixation point to indicate trial has finished  
  set(msgh,'string','+','visible','off');
  set(pileh,'visible','off');
  drawnow;
  % inter-trial
  sleepSec(interTrialDuration);

                                % baseline
  set(msgh,'string','+','visible','on','color',[1 0 0]); drawnow;
  set(scoreh,'visible','on','string',sprintf('%d/%d    you=%3g   comp=%3g',si,nSeq,score)); % update the score
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration); 

                                % trial-start
  pile_r =pilerfn(0);
  set(pileh,'position',[.5-pile_r/2 .5-pile_r/2 pile_r pile_r],'facecolor',neutralColor,'visible','on'); drawnow;
  sendEvent('stimulus.trial','start');
  samp0=buffer('poll');samp0=samp0.nSamples;
  t0=getwTime(); % get time trial start
                 % run the waiting loop
  t_now=0;
  t_human=inf; 

                                % decide on the computer move time estimate
  t_computer=(.5+(1-.5)*rand(1))*trialDuration; % simple uniform rand for now..
  if( human_stats.mu > 3 && human_stats.var>1 ) % gaussian est
                                                % generate random sample from the 'probe' distribution     
    t_computer = ( human_stats.mu - sqrt(human_stats.var)*.5 ) + randn(1)*sqrt(human_stats.var);
  end
  fprintf('%d) t_comp = %g    (%g,%g)\n',si,t_computer,human_stats.mu,human_stats.var);
  
  %------------------------------------- Run the trial -----------------------------
  set(fig,'userdata',[]); % clear the key buffer
  while ( t_now < trialDuration ) % until trial end
    t_now = getwTime()-t0; % current trial-time
    
    % process human key-presses
    modekey=get(fig,'userdata'); 
    if ( ~isempty(modekey) ) t_human = t_now; set(fig,'userdata',[]); end;

    % update the time-display
    pile_r =pilerfn(t_now);
    set(pileh,'position',[.5-pile_r/2 .5-pile_r/2 pile_r pile_r],'visible','on');    
    %set(msgh,'string',sprintf('%3.1f',t_now));
    drawnow;
	 if ( ~ishandle(fig) ) break; end;

    % update the color+score to reflect who-moved-first
    if( t_computer < t_human && t_computer < t_now ) % computer won
       set(pileh,'facecolor',compWinsColor);
       set(msgh,'string',{'Too Slow!!!' sprintf('%3.1f',t_now)},'color',[1 1 1],'visible','on');
       score(2) = score(2) + round(t_computer*10)/10;
       mevt=sendEvent('response.button','computer'); % send info event
       drawnow;
       break;
    end
    if( t_human < t_computer && t_human < t_now ) % human won
       set(pileh,'facecolor',humanWinsColor);
       set(msgh,'string',{'You Win!!!' sprintf('%3.1f',t_now)},'color',[1 1 1],'visible','on');
       score(1) = score(1) + round(t_human*10)/10; 
       mevt=sendEvent('response.button','human'); % send info event
       drawnow;
       break;
    end
    sleepSec(eventInterval*.5); % wait a bit
  end
  if ( ~ishandle(fig) ) break; end;
  % get time, send event, give-user feedback
  t_move=getwTime()-t0; % move time, rel trial start
  set(scoreh,'visible','on','string',sprintf('%d/%d    you=%3g   comp=%3g',si,nSeq,score)); % update the score
  drawnow;
  samp_move=mevt.sample;
  % wait for end of trial
  if( t_now < trialDuration )
    sleepSec(trialDuration-t_now);
  end
  t_end  = getwTime()-t0;
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
    samp_evt= tei*(samp_move-samp0)./t_move + samp0; % linearly interpolate the event sample number
    sendEvent('stimulus.target','nonmove',samp_evt);
  end
  if( t_human < t_computer ) % human moved : t_move + moveLowerBound < t < t_human+moveUpperBound
     t_evt=t_human+moveLowerBound:eventInterval:t_human+moveUpperBound;
     for ei=1:numel(t_evt);
        tei     = t_evt(ei);
        samp_evt= tei*(samp_move-samp0)./t_human + samp0; 
        sendEvent('stimulus.target','move',samp_evt);
     end
  end
  % post move
  % t_move + nonMoveUpperBound < t < end-endArt
  t_evt = t_move+nonMoveUpperBound:eventInterval:t_end+endArtDur;
  for ei=1:numel(t_evt);
    tei     = t_evt(ei);
    samp_evt= tei*(samp_move-samp0)./t_move + samp0; 
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
