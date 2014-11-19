configureCursor;

% make stim seq with an extra invisible symbol to increase the ISI
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
fig=gcf;
set(fig,...%'units','normalized','position',[0 0 1 1],...
    'Name','BCI Cursor control','toolbar','none','menubar','none','color',[0 0 0],...
    'backingstore','on','renderer','painters');
ax=axes('position',[0.025 0.05 .825 .85],'units','normalized','visible','off','box','off',...
         'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
         'color',[0 0 0],'drawmode','fast',...
         'xlim',axLim,'ylim',axLim,'Ydir','reverse');%,'DataAspectRatio',[1 1 1]);
arrowcoords=loadPatchCoords('arrow.coords');
[ax,h,stimPos,stimPCoords]=initCursorStim(ax,0,0,arrowScale,nSymbs,arrowcoords);

% give the user time to get to the right screen
drawnow;
pause(5);

% play the stimulus
sendEvent('stimulus.training','start');
frametime=[]; nframe=0; curStimState=zeros(nSymbs,1);
for si=1:nSeq;

  if ( ~ishandle(fig) ) break; end;
  
  % show the target  
  fprintf('%d) tgt=%d : ',si,find(tgtSeq(:,si)>0));
  set(h(tgtSeq(:,si)>0),'facecolor',tgtColor,'edgeColor',tgtColor);
  set(h(tgtSeq(:,si)<=0),'facecolor',bgColor,'edgeColor',edgeColor);
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  tgtId=find(tgtSeq(:,si)>0);
  ev=sendEvent('stimulus.target',tgtId);
  if ( verb>1 ) fprintf('Sending target : %s\n',ev2str(ev)); end;
  sleepSec(cueDuration);
  set(h(:),'facecolor',bgColor);
  drawnow;
  sleepSec(startDelay);
  
  % play the stimulus
  seqStartTime=getwTime(); drawTime=seqStartTime;
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
    set(h(curStimState>0),'facecolor',flashColor);
    set(h(curStimState<=0),'facecolor',bgColor);
    set(h(curStimState>1),'facecolor',tgt2Color);
    frametime(nframe,2)=getwTime();
    if ( 0 & ispc() )
        odrawTime=drawTime;
        sleepSec(max(0,isi-(getwTime()-odrawTime)-100/1000)); % exactly isi ms between calls to drawnow
        while ( isi-(getwTime()-odrawTime)>0 ); end; % live wait - reduces expose variance?
        drawTime=getwTime();
        drawnow; 
    else 
        sleepSec(max(0,stimTime(i)-(getwTime()-seqStartTime))); % sleep until stim time
        drawnow; 
    end;
    if ( ~ishandle(fig) ) break; end; % exit cleanly if exit event
    frametime(nframe,4)=getwTime();
    stimID=find(curStimState>0); if(isempty(stimID))stimID=0; end; %0 is id of invisible stim
    ev=sendEvent('stimulus.arrows',curStimState); % total state
    sendEvent('stimulus.tgtFlash',curStimState(tgtId)>0,ev.sample(1)); % indicate if it was a 'target' flash
    if ( verb>2 ) % sanity check the samp times
      status=buffer('wait_dat',[-1 -1 -1]); % current sample info
      fprintf('Sending Event: %s @ %d\n',ev2str(ev),status.nsamples);
    end    
    frametime(nframe,5)=getwTime();
  end
  fprintf('\n');
  if ( ~ishandle(fig) ) break; end;
  set(h(:),'facecolor',bgColor);
  drawnow;
  sleepSec(interSeqDuration);  
end % sequences
% end training marker
sendEvent('stimulus.training','end');
% show the end training message
if ( ishandle(fig) ) 
pause(1);
axes(ax);
text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),{'That ends the training phase.','Thanks for your patience'},'HorizontalAlignment','center','color',[0 1 0],'fontunits','normalized','FontSize',.1);
pause(3);
end