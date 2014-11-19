configureGame; 


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
set(gcf,...%'units','normalized','position',[0 0 1 1],...
    'toolbar','none','menubar','none','color',[0 0 0],...
    'backingstore','on','renderer','painters','Name','Calibration Phase');
arenaax=axes('position',[0.025 0.05 .825 .85],'units','normalized','visible','off','box','off',...
         'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
         'color',[0 0 0],'drawmode','fast',...
         'xlim',zoomedLim,'ylim',zoomedLim,'Ydir','reverse');%,'DataAspectRatio',[1 1 1]);
arrowcoords=loadPatchCoords('arrow.coords');
[arenaax,h,stimPos,stimPCoords]=initBCIStim(arenaax,0,0,arrowScale,nSymbs,arrowcoords);

% give the user time to get to the right screen
drawnow;
pause(5);

% play the stimulus
sendEvent('stimulus.training','start');
frametime=[]; nframe=0; curStimState=zeros(nSymbs,1);
for si=1:nSeq;

  % show the target  
  tgt=tgtSeq(:,si)>0;
  fprintf('%d) tgt=[%s] : ',si,sprintf('%d ',tgt));
  set(h(tgtSeq(:,si)>0),'facecolor',[0 1 0],'edgeColor',[0 1 0]);
  set(h(tgtSeq(:,si)<=0),'facecolor',[0 0 0],'edgeColor',[1 1 1]);
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  ev=sendEvent('stimulus.target',find(tgt));
  if ( verb>1 ) fprintf('Sending target : %s\n',ev2str(ev)); end;
  sleepSec(targetTime); % sleep remaining frame time
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
    set(h(curStimState>0),'facecolor',tgtColor);
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
    frametime(nframe,4)=getwTime();
    stimID=find(curStimState>0); if(isempty(stimID))stimID=0; end; %0 is id of invisible stim
    ev=sendEvent('stimulus.arrows',stimID);
    sendEvent('stimulus.tgtFlash',any(curStimState(tgt)),ev.sample); % send if this was target flash or not
    if ( verb>2 ) % sanity check the samp times
      status=buffer('wait_dat',[-1 -1 -1]); % current sample info
      fprintf('Sending Event: %s @ %d\n',ev2str(ev),status.nsamples);
    end    
    frametime(nframe,5)=getwTime();

    frametime(nframe,6)=getwTime();
  end
  fprintf('\n');
  set(h(:),'facecolor',bgColor);
  drawnow;
  sleepSec(interTrialDelay);  
end % sequences
% end training marker
sendEvent('stimulus.training','end');
% show the end training message
pause(1);
axes(arenaax);
text(mean(get(arenaax,'xlim')),mean(get(arenaax,'ylim')),{'That ends the calibration phase.','Thanks for your patience'},'HorizontalAlignment','center','color',[0 1 0],'fontunits','normalized','FontSize',.1);
pause(3);