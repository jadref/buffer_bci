configureSpeller;

% make the stimulus
fig=gcf;
set(fig,'Name','Matrix Speller','color',[0 0 0],'menubar','none','toolbar','none','doublebuffer','on');
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');
% compute size of letters in pixels from fraction of window size
set(fig,'Units','pixel');wSize=get(fig,'position');symbSize_px = symbSize*wSize(4);
[h,symbs]=initGrid(symbols,'fontSize',symbSize_px);

% make the row/col flash sequence for each sequence
[stimSeqRow,stimTimeRow]=mkStimSeqRand(vnRows,nRepetitions*vnRows,stimDuration);
stimSeqRow(size(symbols,1)+1:end,:)=[];  % remove the extra symbol
[stimSeqCol,stimTimeCol]=mkStimSeqRand(vnCols,nRepetitions*vnCols,stimDuration);
stimSeqCol(size(symbols,2)+1:end,:)=[];  % remove the extra symbol

stimSeq=zeros([size(symbols),size(stimSeqRow,2)+size(stimSeqCol,2)]); % to store the actual stimulus state
flash=zeros(1,size(stimSeqRow,2)+size(stimSeqCol,2)); % stores the flash times
pred=zeros(2,size(stimSeqRow,2)+size(stimSeqCol,2)); % stores the classifier predictions
  
% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'color',[.5 .5 .5]);
sendEvent('stimulus.feedback','start');
drawnow; pause(5); % N.B. use pause so the figure window redraws
state=[];
for si=1:nSeq;

  if ( ~ishandle(fig) ) break; end;
  nFlash = 0; nPred=0;
  p   =ones(size(symbols))./numel(symbols);
  set(h(:),'color',bgColor); % rest all symbols to background color
  for hi=1:numel(h); set(h(hi),'fontSize',symbSize_px*(1+.5*(p(hi)-1/numel(symbols)))); end;
  sleepSec(interSeqDuration);
  sendEvent('stimulus.sequence','start');
  % get current events status, i.e. discard all events before this time....
  [devents,state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],0);
  
  if( verb>0 ) fprintf(1,'Rows\n'); end;
  % rows stimulus
  seqStartTime=getwTime();
  for ei=1:size(stimSeqRow,2);
    % record the stimulus state, needed for decoding the classifier predictions later
    nFlash=nFlash+1;
    stimSeq(stimSeqRow(:,ei)>0,:,nFlash)=true;
    % set the stimulus state
    set(h(:),'color',bgColor);
    set(h(stimSeqRow(:,ei)>0,:),'color',flashColor);
    sleepSec(max(0,stimTimeRow(ei)-(getwTime()-seqStartTime))); % wait until time to call the draw-now
    drawnow;
    evt=sendEvent('stimulus.rowFlash',stimSeqRow(:,ei)); % indicate this row is 'flashed'    
    flash(nFlash,1)=evt.sample; % record sample this event was sent

    % *non-blocking* check for new events and collect
    [events,state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],0);
    if ( ~isempty(events) ) % new events to process
      % store the predictions
      for ei=1:numel(events);
        if ( verb>0 ) fprintf('Got %d events\n',numel(events)); end;
        nPredei = find(flash(1:nFlash)==events(ei).sample); % find the flash this prediction is for
        if ( isempty(nPredei) ) 
          if ( verb>0 ) fprintf('Pred without flash =%d\n',events(ei).value); end;
          continue;
        end
        nPred=max(nPred,nPredei(1));
        pred(:,nPredei)=[events(ei).sample; events(ei).value];
        if ( verb>1 ) fprintf('%d) samp=%d pred=%g\n',nPredei,pred(:,nPredei)); end;
        dv = reshape(stimSeq(:,:,1:min(nPred,nFlash)),[numel(symbols) min(nPred,nFlash)])*pred(2,1:nPred)'; 
        p  = 1./(1+exp(-dv)); p=p./sum(p); % norm letter prob      
      end
      % update the display
      for hi=1:numel(h); set(h(hi),'fontSize',symbSize_px*(1+.5*(p(hi)-1/numel(symbols)))); end;
    end
    
  end
  sleepSec(stimDuration);
  
  if( verb>0 ) fprintf(1,'Cols\n');end
  % cols stimulus
  seqStartTime=getwTime();
  for ei=1:size(stimSeqCol,2);
    % record the stimulus state, needed for decoding the classifier predictions later
    nFlash=nFlash+1;
    stimSeq(:,stimSeqCol(:,ei)>0,nFlash)=true;
    % set the stimulus state
    set(h(:),'color',bgColor);
    set(h(:,stimSeqCol(:,ei)>0),'color',flashColor);
    sleepSec(max(0,stimTimeCol(ei)-(getwTime()-seqStartTime))); % wait until time to call the draw-now
    drawnow;
    evt=sendEvent('stimulus.colFlash',stimSeqCol(:,ei)); % indicate this row is 'flashed'
    flash(nFlash,1)=evt.sample; % record sample this event was sent

    % *non-blocking* check for new events and collect
    [events,state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],0);
    if ( ~isempty(events) ) % new events to process
       if ( verb>0 ) fprintf('Got %d events\n',numel(events)); end;
      % store the predictions
      for ei=1:numel(events);
        nPredei = find(flash(1:nFlash)==events(ei).sample); % find the flash this prediction is for
        if ( isempty(nPredei) ) 
          if ( verb>0 ) fprintf('Pred without flash =%d\n',events(ei).value); end;
          continue;
        end
        nPred=max(nPred,nPredei(1));
        pred(:,nPredei)=[events(ei).sample; events(ei).value];
        if ( verb>1 ) fprintf('%d) samp=%d pred=%g\n',nPredei,pred(:,nPredei)); end;
        dv = reshape(stimSeq(:,:,1:min(nPred,nFlash)),[numel(symbols) min(nPred,nFlash)])*pred(2,1:nPred)'; 
        p  = 1./(1+exp(-dv)); p=p./sum(p); % norm letter prob      
      end
      % update the display
      for hi=1:numel(h); set(h(hi),'fontSize',symbSize_px*(1+.5*(p(hi)-1/numel(symbols)))); end;
    end
  end
   
  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'color',bgColor);
  drawnow;
  sleepSec(trlen_ms/1000+.2);  % wait long enough for classifier to finish up..
  sendEvent('stimulus.sequence','end');

  % *blocking* check for the final set of prediction events
  [events,state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],trlen_ms);
  for ei=1:numel(events); % new events to process
    % store the predictions
    nPredei = find(flash(1:nFlash)==events(ei).sample); % find the flash this prediction is for
    if ( isempty(nPredei) ) 
      if ( verb>0 ) fprintf('Pred without flash =%d\n',events(ei).value); end;
      continue;
    end
    nPred=max(nPred,nPredei);
    pred(:,nPredei)=[events(ei).sample; events(ei).value];
    if ( verb>1 ) fprintf('%d) samp=%d pred=%g\n',nPredei,pred(:,nPredei)); end;
  end

  % combine the classifier predictions with the stimulus used
  if ( nPred>0 ) 
    fprintf('Pred(%d) = [%s]\n',nPred,sprintf('%g,',pred(2,1:nPred)));
    % correlate the stimulus sequence with the classifier predictions to identify the most likely
    % N.B. assume last prediction is one for prev sequence  
    dv = reshape(stimSeq(:,:,1:min(nPred,nFlash)),[numel(symbols) min(nPred,nFlash)])*pred(2,1:nPred)'; 
    p  = 1./(1+exp(-dv)); p=p./sum(p); % norm letter prob      
    [ans,predTgt] = max(dv); % predicted target is highest correlation
  
    % update the feedback display
    for hi=1:numel(h); set(h(hi),'fontSize',symbSize_px*(1+.5*(p(hi)-1/numel(symbols)))); end;     
    % show the classifier prediction
    set(h(predTgt),'color',predColor);
    drawnow;
    sendEvent('stimulus.prediction',symbols{predTgt});
  end
  
  sleepSec(feedbackDuration);
  fprintf('\n');
end % sequences
% end training marker
sendEvent('stimulus.feedback','end');
