% per-epoch feedback when using a continuously applied classifier
% This version of imEpoch feedback works directly with at continuous classifier by accumulating the 
% individual classifier prediction internally from the start until the end of the trial and then generating 
% a prediction
%if ( ~exist('preConfigured','var') || ~isequal(preConfigured,true) ) configureIM; end;

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

% make the stimulus display
fig=figure(2);
clf;
set(fig,'Name','Stimulus Display','color',winColor,'menubar','none','toolbar','none','doublebuffer','on');
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',winColor,'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');

stimPos=[]; h=[];
stimRadius=.5;
theta=linspace(0,2*pi,nSymbs+1);
if ( mod(nSymbs,2)==1 ) theta=theta+pi/2; end; % ensure left-right symetric by making odd 0=up
theta=theta(1:end-1);
stimPos=[cos(theta);sin(theta)];
for hi=1:nSymbs; 
  h(hi)=rectangle('curvature',[1 1],'position',[stimPos(:,hi)-stimRadius/2;stimRadius*[1;1]],...
                  'facecolor',bgColor); 
  if ( ~isempty(symbCue) ) % cue-text
	 htxt(hi)=text(stimPos(1,hi),stimPos(2,hi),symbCue{hi},...
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

                                % mapping from class order to screen order
cls2tgt=[];
%cls2tgt=1:nSymbs+1;
%if ( ~isempty(symbCue) ) % given cue-text
%  % compute inverse mapping from class-name-order -> input class order=display order
%  [ss,si]=sort(symbCue,'rows'); cls2tgt(si)=1:numel(si);
%end

      %Create a text object with no text in it, center it, set font and color
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','off');

% text object for the experiment progress bar
progresshdl=text(axLim(1),axLim(2),sprintf('%2d/%2d +%02d -%02d',0,nSeq,0,0),...
				  'HorizontalAlignment', 'left', 'VerticalAlignment', 'top',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','on');


set(txthdl,'string', {epochfeedback_instruct{:} '' 'Click mouse when ready'}, 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'facecolor',bgColor);
sendEvent('stimulus.testing','start');
drawnow; pause(5); % N.B. pause so fig redraws
endTesting=false; dvs=[];
for si=1:nSeq;

  if ( ~ishandle(fig) || endTesting ) break; end;

  % Give user a break if too much time has passed
  if ( getwTime() > waitforkeyTime )
	 set(txthdl,'string', {'Break between blocks.' 'Click mouse when ready to continue.'}, 'visible', 'on');
	 drawnow;
	 waitforbuttonpress;
	 set(txthdl,'visible', 'off');
	 drawnow;	 
	 waitforkeyTime=getwTime()+calibrateMaxSeqDuration;
	 sleepSec(intertrialDuration);
  end

  % show the screen to alert the subject to trial start
  set(h(:),'faceColor',bgColor);
  set(h(end),'facecolor',fixColor); % red fixation indicates trial about to start/baseline
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  if ( ~isempty(baselineClass) ) % treat baseline as a special class
	 sendEvent('stimulus.target',baselineClass);
  end
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');

  % show the target
  fprintf('%d) tgt=%d : ',si,find(tgtSeq(:,si)>0));
  set(h(tgtSeq(:,si)>0),'facecolor',tgtColor);
  set(h(tgtSeq(:,si)<=0),'facecolor',bgColor);
  set(h(end),'facecolor',tgtColor); % green fixation indicates trial running
  if ( ~isempty(symbCue) )
	 set(txthdl,'string',sprintf('%s ',symbCue{tgtIdx}),'color',txtColor,'visible','on');
	 tgtNm = '';
	 for ti=1:numel(tgtIdx);
		if(ti>1) tgtNm=[tgtNm ' + ']; end;
		tgtNm=sprintf('%s%d %s ',tgtNm,tgtIdx,symbCue{tgtIdx});
	 end
  else
	 tgtNm = tgtIdx; % human-name is position number
  end
  fprintf('%d) tgt=%10s : ',si,tgtNm);
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.target',tgtNm);
  sendEvent('stimulus.trial','start');
  
  % initial fixation point position
  dvs(:)=0; nPred=0; state=[];
  trlStartTime=getwTime();
  timetogo = trialDuration;
  while (timetogo>0)
    timetogo = trialDuration - (getwTime()-trlStartTime); % time left to run in this trial
    % wait for events to process *or* end of trial *or* out of time
    [devents,state,nevents,nsamples]=buffer_newevents(buffhost,buffport,state,{'stimulus.prediction' 'stimulus.testing'},[],timetogo*1000);
    for ei=1:numel(events);
      ev=events(ei);
      if ( strcmp(ev.type,'stimulus.prediction') ) 
        pred=ev.value;
        % now do something with the prediction....
        if ( numel(pred)==1 )
          if ( pred>0 && pred<=nSymbs && isinteger(pred) ) % predicted symbol, convert to dv equivalent
            tmp=pred; pred=zeros(nSymbs,1); pred(tmp)=1;
          else % binary problem, convert to per-class
            pred=[pred -pred];
          end
        end
        % map from class order to display / target order
        if(~isempty(cls2tgt)) pred=pred(cls2tgt); end;
        
        nPred=nPred+1;
        dvs(:,nPred)=pred;
        if ( verb>=0 ) 
          fprintf('dv:');fprintf('%5.4f ',pred);fprintf('\n'); 
        end;          
      elseif ( strcmp(ev.type,'stimulus.testing') ) 
        endTesting=true; break;
      end % prediction events to processa  
    end % if feedback events to process
    if ( endTesting ) break; end;
  end % loop accumulating prediction events

  % give the feedback on the predicted class
  prob=exp((dv-max(dv))); prob=prob./sum(prob); % robust soft-max prob computation
  if ( verb>=0 ) 
    fprintf('dv:');fprintf('%5.4f ',pred);fprintf('\t\tProb:');fprintf('%5.4f ',prob);fprintf('\n'); 
  end;  
  [ans,predTgt]=max(dv); % prediction is max classifier output
  set(h(:),'facecolor',bgColor);
  set(h(predTgt),'facecolor',tgtColor);
  % update the score
  if ( predTgt>nSymbs )      nMissed = nMissed+1; fprintf('missed!');
  elseif ( predTgt~=tgtIdx ) nWrong  = nWrong+1;  fprintf('wrong!'); % wrong (and not 'rest') .... do the penalty
  else                       nCorrect= nCorrect+1;fprintf('right!'); % correct
  end
  % update progress bar
  set(progresshdl,'string',sprintf('%2d/%2d +%02d -%02d',si,nSeq,nCorrect,nWrong));
  drawnow;
  sendEvent('stimulus.predTgt',predTgt);

  if ( ~isempty(rtbClass) ) % treat post-trial return-to-baseline as a special class		
	 if ( ischar(rtbClass) && strcmp(rtbClass,'trialClass') ) % label as part of the trial
		sendEvent('stimulus.target',tgtNm);
	 elseif ( ischar(rtbClass) && strcmp(rtbClass,'trialClass+rtb') )%return-to-base ver of trial class
		sendEvent('stimulus.target',[tgtNm '_rtb']);		
	 else
		sendEvent('stimulus.target',rtbClass);
	 end
  end
  sleepSec(feedbackDuration);
	 
  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'facecolor',bgColor);
  if ( ~isempty(symbCue) ) set(txthdl,'visible','off'); end
  % also reset the position of the fixation point
  drawnow;
  sendEvent('stimulus.trial','end');
  
  ftime=getwTime();
  fprintf('\n');
end % loop over sequences in the experiment
% end training marker
sendEvent('stimulus.testing','end');

if ( ishandle(fig) ) % thanks message
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),{'That ends the testing phase.','Thanks for your patience'},'HorizontalAlignment','center','color',[0 1 0],'fontunits','pixel','FontSize',.1*wSize(4));
pause(3);
end
