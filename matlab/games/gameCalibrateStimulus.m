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
fig=figure(2);
clf;
set(fig,...%'units','normalized','position',[0 0 1 1],'backingstore','on',...
    'toolbar','none','menubar','none','color',[0 0 0],...
    'renderer','painters','Name','Calibration Phase');
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
arenaax=axes('position',[0.025 0.05 .825 .85],'units','normalized','visible','off','box','off',...
         'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
         'color',[0 0 0],'drawmode','fast',...
         'xlim',zoomedLim,'ylim',zoomedLim,'Ydir','reverse');%,'DataAspectRatio',[1 1 1]);
arrowcoords=loadPatchCoords('arrow.coords');
%i=image('xdata',[-3 3],'ydata',[-3 3],'cdata',ones(10,10)); % background image
[arenaax,h,stimPos,stimPCoords]=initBCIStim(arenaax,0,0,arrowScale,nSymbs,arrowcoords);

%Create a text object with no text in it, center it, set font and color
txthdl = text(mean(get(arenaax,'xlim')),mean(get(arenaax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','off');

% give the user time to get to the right screen
set(txthdl,'string', {calibrate_instruct{:} '' 'Click mouse when ready'}, 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;

% play the stimulus
sendEvent('stimulus.training','start');
frametime=[]; nframe=0; curStimState=zeros(nSymbs,1);
for si=1:nSeq;

  % show the target  
  tgt=tgtSeq(:,si)>0;
  fprintf('%d) tgt=[%s] : ',si,sprintf('%d ',tgt));
  set(h(tgtSeq(:,si)>0),'facecolor',cueColor,'edgeColor',cueColor);
  set(h(tgtSeq(:,si)<=0),'facecolor',bgColor,'edgeColor',bgColor);
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
               set(h(j),'xdata',stimPos(1,j)+stimPCoords(1,:,j),...
                        'ydata',stimPos(2,j)+stimPCoords(2,:,j));
           end
        end
        si=find(curStimState>0);
        if ( ~isempty(si) )
            for j=si; % change stim size
                set(h(j),'xdata',stimPos(1,j)+stimPCoords(1,:,j)*sizeStim,...
                         'ydata',stimPos(2,j)+stimPCoords(2,:,j)*sizeStim);
            end
        end
    end
    set(h(curStimState>0),'facecolor',tgtColor);
    set(h(curStimState<=0),'facecolor',bgColor);
    set(h(curStimState>1),'facecolor',tgt2Color);
    frametime(nframe,2)=getwTime();
    if ( 0 && ispc() )
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
sleepSec(1); % wait for brain response to end
% show the end training message
axes(arenaax);
set(txthdl,'string',{'That ends the calibration phase.','Thanks for your patience'}, 'visible', 'on', 'color',[0 1 0]);
pause(3);
