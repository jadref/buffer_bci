configureIM;
if ( ~exist('epochFeedbackTrialDuration') || isempty(epochFeedbackTrialDuration) )
  epochFeedbackTrialDuration=trialDuration;
end;


cybathalon = struct('host','localhost','port',5555,'player',1,...
                    'cmdlabels',{{'jump' 'slide' 'speed' 'rest'}},'cmddict',[2 3 1 99],...
						  'cmdColors',[.6 0 .6;.6 .6 0;0 .5 0;.3 .3 .3]',...
                    'socket',[],'socketaddress',[]);
% open socket to the cybathalon game
[cybathalon.socket]=javaObject('java.net.DatagramSocket'); % create a UDP socket
cybathalon.socketaddress=javaObject('java.net.InetSocketAddress',cybathalon.host,cybathalon.port);
cybathalon.socket.connect(cybathalon.socketaddress); % connect to host/port
connectionWarned=0;

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

% make the stimulus display
fig=figure(2);
clf;
set(fig,'Name','Imagined Movement','color',winColor,'menubar','none','toolbar','none','doublebuffer','on');
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',winColor,'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');

stimPos=[]; h=[];
stimRadius=diff(axLim)/4;
cursorSize=stimRadius/2;
theta=linspace(0,2*pi,nSymbs+1);
if ( mod(nSymbs,2)==1 ) theta=theta+pi/2; end; % ensure left-right symetric by making odd 0=up
theta=theta(1:end-1);
stimPos=[cos(theta);sin(theta)];
for hi=1:nSymbs; 
  % set tgt to the color of that part of the game
  h(hi)=rectangle('curvature',[1 1],'position',[stimPos(:,hi)-stimRadius/2;stimRadius*[1;1]],...
                  'facecolor',cybathalon.cmdColors(:,hi));

  if ( ~isempty(symbCue) ) % cue-text
	 htxt(hi)=text(stimPos(1,hi),stimPos(2,hi),{symbCue{hi} '->' cybathalon.cmdlabels{hi}},...
						'HorizontalAlignment','center',...
						'fontunits','pixel','fontsize',.05*wSize(4),...
						'color',txtColor,'visible','on');
  end  
end;
% add symbol for the center of the screen
stimPos(:,nSymbs+1)=[0 0];
h(nSymbs+1)=rectangle('curvature',[1 1],'position',[stimPos(:,end)-stimRadius/4;stimRadius/2*[1;1]],...
                      'facecolor',bgColor); 
set(gca,'visible','off');

%Create a text object with no text in it, center it, set font and color
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',[0.75 0.75 0.75],'visible','off');

set(txthdl,'string', 'Click mouse when ready', 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;

% play the stimulus
sendEvent('stimulus.testing','start');
% initialize the state so don't miss classifier prediction events
state=[]; 
endTesting=false; dvs=[];
for si=1:max(100000,nSeq);

  if ( ~ishandle(fig) || endTesting ) break; end;
  
  % show the screen to alert the subject to trial start
  set(h(end),'facecolor',tgtColor); % red fixation indicates trial about to start/baseline
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  if ( earlyStopping )
	 % cont-classifier, so tell it to clear the prediction filter for start new trial
	 ev=sendEvent('classifier.reset','now'); 
  else
	 % event-classifier, so send the event which triggers to classify this data-block
	 ev=sendEvent('classifier.apply','now'); % tell the classifier to apply from now
  end
  trlStartTime=getwTime();
  sendEvent('stimulus.trial','start',ev.sample);
  state=buffer('poll'); % Ensure we ignore any predictions before the trial start  
  if( verb>0 )
	 fprintf(1,'Waiting for predictions after: (%d samp, %d evt)\n',...
				state.nSamples,state.nEvents);
  end;
  if ( earlyStopping )
	 % wait for new prediction events to process *or* end of trial time
	 [devents,state,nevents,nsamples]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],epochFeedbackTrialDuration*1000+1500);
  else
    sleepSec(epochFeedbackTrialDuration/2); 
	 % wait for classifier prediction event
	 [devents,state,nevents,nsamples]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],epochFeedbackTrialDuration*1000/2+2000);
  end
  trlEndTime=getwTime();
  
  % do something with the prediction (if there is one), i.e. give feedback
  predTgt=[];
  if( isempty(devents) ) % extract the decision value
    fprintf(1,'Error! no predictions after %gs, continuing (%d samp, %d evt)\n',trlEndTime-trlStartTime,state.nSamples,state.nEvents);
    set(h(end),'facecolor',fbColor); % fix turns blue to show now pred recieved
    drawnow;
  else
	 fprintf(1,'Prediction after %gs : %s',trlEndTime-trlStartTime,ev2str(devents(end)));
    dv = devents(end).value;
    % predicted symbol, convert to dv equivalent
    if ( numel(dv)==1 && isinteger(dv) && dv>0 && dv<=nSymbs ) 
       tmp=dv; dv=zeros(nSymbs,1); dv(tmp)=1;
    end    
    % give the feedback on the predicted class
    if( numel(dv)==1 ) dv=[dv -dv]; end; % ensure min 1 decision values..
    prob=exp(dv-max(dv)); prob=prob./sum(prob); % robust soft-max prob computation
    if ( verb>=0 ) 
      fprintf('dv:');fprintf('%5.4f ',dv);fprintf('\t\tProb:');fprintf('%5.4f ',prob);fprintf('\n'); 
    end;  
    [ans,predTgt]=max(dv); % prediction is max classifier output
    set(h(predTgt),'facecolor',fbColor);
    drawnow;
    sendEvent('stimulus.predTgt',predTgt);
                                % send the command to the game server
    try;
		cybathalon.socket.send(javaObject('java.net.DatagramPacket',uint8([10*cybathalon.player+cybathalon.cmddict(predTgt) 0]),1));
    catch;
		if ( connectionWarned<10 )
		  connectionWarned=connectionWarned+1;
		  warning('Error sending to the Cybathalon game.  Is it running?\n');
		end
    end
    
  end % if classifier prediction
  
  % reset the cue and fixation point to indicate trial has finished  
  set(h(end),'facecolor',bgColor);
  if ( ~isempty(predTgt) ) 
   drawnow;
   sleepSec(.1); % slight delay to see the feedback
	set(h(predTgt),'facecolor',cybathalon.cmdColors(:,predTgt)); % reset the feedback
  end
  % also reset the position of the fixation point
  drawnow;
  sendEvent('stimulus.trial','end');
  
end % loop over sequences in the experiment
% end training marker
sendEvent('stimulus.testing','end');

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'That ends the testing phase.','Thanks for your patience'}, 'visible', 'on', 'color',[0 1 0]);
pause(3);
end
