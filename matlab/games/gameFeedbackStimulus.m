configureGame;
fbtype='epoch';%'cont';%

% hack set nsymbs lower
nSymbs=2;
[stimSeq,stimTime]=mkStimSeqRand2Color(vnSymbs,ceil(seqDuration/isi/vnSymbs)*vnSymbs*10,isi);
stimSeq(nSymbs+1:end,:)=[];  % remove the extra symbol
if( verb>1 ) % compute mean tti statistics for each symb
  fprintf('Stim Stats:\n');
  for si=1:size(stimSeq,1); 
    tti=diff(find(stimSeq(si,:)));
    fprintf('Symb%d: %g\t%g\t%g\t%g\n',si,min(tti),mean(tti),max(tti),var(tti));
  end;
end

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

% make the stimulus
%figure;
clf;
set(gcf,'units','normalized','position',[0 0 1 1],...
    'toolbar','none','menubar','none','color',[0 0 0],...
    'backingstore','on','renderer','painters');
arenaax=axes('position',[0.025 0.05 .825 .85],'units','normalized','visible','off','box','off',...
         'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
         'color',[0 0 0],'drawmode','fast',...
         'xlim',zoomedLim,'ylim',zoomedLim,'Ydir','reverse');%,'DataAspectRatio',[1 1 1]);
arrowcoords=loadPatchCoords('arrow.coords');
[arenaax,h,stimPos,stimPCoords]=initBCIStim(arenaax,0,0,arrowScale,nSymbs,arrowcoords);
if ( strcmp(fbtype,'cont') )
   % make bits for display of online feedback
   for hi=1:numel(h); 
     fb(hi)=line([0 stimPos(1,hi)*.7],[0 stimPos(2,hi)*.7],'lineWidth',20); % feedback is line pointing at stim
   end;
end

% give the user time to get to the right screen
drawnow;
pause(5); % N.B. pause so re-draws in this gap

% play the stimulus
sendEvent('stimulus.test','start');
frametime=[]; nframe=0; curStimState=zeros(nSymbs,1); btime=[]; wtime=[];
for si=1:nTestSeq;

  % show the target  
  fprintf('%d) tgt=%d : ',si,find(tgtSeq(:,si)>0));
  set(h(tgtSeq(:,si)>0),'facecolor',[0 1 0],'edgecolor',[0 1 0]);
  set(h(tgtSeq(:,si)<=0),'facecolor',[0 0 0]);
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.target',find(tgtSeq(:,si)>0));
  sleepSec(targetTime);
  %set(h(:),'facecolor',[0 0 0]);
  %drawnow;
  %sleepSec(startDelay);
  
  % discard all events before this time!
  status=buffer('wait_dat',[-1 -1 -1],buffhost,buffport); % get current state
  nevents=status.nevents; nsamples=status.nsamples;
  % play the stimulus
  seqStartTime=getwTime(); drawTime=seqStartTime;
  dv=zeros(nSymbs,1);
  for i=1:ceil(seqDuration/isi);
    nframe=nframe+1;
    fprintf('.');
    ftime=getwTime();
    frametime(nframe,1)=ftime;

    curStim      = mod(nframe,size(stimSeq,2))+1;
    ostimState   = curStimState;
    curStimState = stimSeq(:,curStim);
    if ( sizeStim>0 ) 
      si=find(ostimState>0);
      if( ~isempty(si) )
        for j=si; % change stim size
          set(h(j),'xdat',stimPos(1,j)+stimPCoords(1,:,j),...
                   'ydat',stimPos(2,j)+stimPCoords(2,:,j));
        end
      end
      si=find(curStimState>0);
      if ( ~isempty(si) )
        for j=si; % change stim size
          set(h(j),'xdat',stimPos(1,j)+stimPCoords(1,:,j)*sizeStim,...
                   'ydat',stimPos(2,j)+stimPCoords(2,:,j)*sizeStim);
        end
      end
    end
    set(h(curStimState>0),'facecolor',tgtColor);
    set(h(curStimState<=0),'facecolor',bgColor);
    set(h(curStimState>1),'facecolor',tgt2Color);
    frametime(nframe,2)=getwTime();
    odrawTime=drawTime;
    if ( 0 & ispc() )
      sleepSec(max(0,isi-(getwTime()-odrawTime)-100/1000)); % exactly isi ms between calls to drawnow
      while ( isi-(getwTime()-odrawTime)>0 ); end; % live wait - reduces expose variance?
      drawTime=getwTime();
      frametime(nframe,3)=drawTime;
      drawnow; 
    else 
      sleepSec(max(0,isi-(getwTime()-odrawTime))); % sleep until stim time
      drawTime=getwTime();
      frametime(nframe,3)=drawTime;
      drawnow; 
    end;
    frametime(nframe,4)=getwTime();
    stimID=find(curStimState>0); 
    if(~isempty(stimID)) % no-stim = no event
      ev=sendEvent('stimulus.arrows',stimID);
    end
    % check for prediction events and update the prediction information
    status=buffer('wait_dat',[-1 -1 -1],buffhost,buffport); % get current state
    stime =getwTime(); 
    btime(nframe)=status.nsamples; wtime(nframe)=stime; % track info used for sync
    frametime(nframe,5)=stime;
    if ( status.nevents > nevents ) % new events to process
      events=buffer('get_evt',[nevents status.nevents-1],buffhost,buffport);
      [dv,predevIdx]=procPredEvents(events,{{'stimulus.prediction'}},dv,predAlpha,verb);    
    end
    if ( strcmp(fbtype,'cont') )
      prob = 1./(1+exp(-(dv-mean(dv)))); % convert to prob.. N.B. with bias correction
      prob = prob./sum(prob);            % normalise the probabilties
      if ( verb>1 ) fprintf('Prob:');fprintf('%5.4f ',prob);fprintf('\n'); end;
      for hi=1:numel(fb); % update the line length
        set(fb(hi),'XData',[0 stimPos(1,hi)*prob(hi)],'YData',[0 stimPos(2,hi)*prob(hi)],'color',[0 0 1]);
      end
      [ans,bs]=max(dv); set(fb(bs),'color',[0 1 0]);           
    end
    nevents = status.nevents; nsamples=status.nsamples;
    frametime(nframe,6)=getwTime();
    
  end % loop over epochs in the sequence
  % send the end sequence event
  sendEvent('stimulus.endSeq',true,-1);
  % now wait for the final prediction
  status=buffer('wait_dat',[-1 -1 60],buffhost,buffport); % get current state
  if ( status.nevents > nevents ) % new events to process
    events=buffer('get_evt',[nevents status.nevents-1],buffhost,buffport);
    [dv,predevIdx]=procPredEvents(events,{{'stimulus.prediction'}},dv,predAlpha,verb);
    nevents = status.nevents;
  end
  
  fprintf('\n');
  % show final prediction
  [ans,bs]=max(dv(1:nSymbs));
  set(h(:),'facecolor',bgColor,'edgecolor',[1 1 1]);
  set(h(bs),'facecolor',[0 0 1],'edgecolor',[0 0 1]);
  drawnow;
  sleepSec(interTrialDelay);
  % reset
  %set(h(:),'facecolor',[0 0 0]);
  %drawnow;
  %sleepSec(.1);  
end % loop over sequences in the experiment
% end training marker
sendEvent('stimulus.test','end');

% show the end message
axes(arenaax);
text(mean(get(arenaax,'xlim')),mean(get(arenaax,'ylim')),{'That ends the on-line test.' 'Thankyou for your patience.'},'HorizontalAlignment','center','color',[0 1 0],'fontunits','normalized','FontSize',.15);
