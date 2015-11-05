
% setup the set of levels we are to test
% set the levels we are to test
switch testType;
  case 'color';  levels = alphas;
  case 'images'; % Load the images if needed
	 files = dir(imagesDir); % get all files
	 [ans,si]=sort({files.name}); files=files(si);
	 levels={};
	 for fi=1:numel(files);
		filei = files(fi);
		if (filei.isdir) continue;
		else
		  fprintf('Loading :%s...',filei.name);
		  try
			 img=imread(fullfile(imagesDir,filei.name));
			 fprintf('OK.\n',filei.name);
		  catch
			 fprintf('Failed!\n',filei.name);
			 continue;
		  end
		  if (size(img,3)==1 ) img=repmat(img,[1 1 3]); end; % make RGB to enforce color display
		  levels{numel(levels)+1} = img; % store in levels set
		end
	 end
	 % background should brightness match the target
	 bgLevel = mean(levels{1},3); bgLevel=median(bgLevel(:));
	 if ( isinteger(levels{1}) ) bgLevel=bgLevel/255.0; end; % convert to 0-1 float value 
end


%==========================================================================
% Initialize the display
%==========================================================================
%Set the frame size for the stimulus frame, make axes invisible, 
%remove menubar and toolbar. Also set the background color for the frame.
stimfig = figure(2);
clf;
set(stimfig,'Name','Experiment - Psychophysics',...
    'color',framebgColor,'menubar','none','toolbar','none',...
    'renderer','painters','doublebuffer','on','Interruptible','off');

ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',axlim(:,1),'ylim',axlim(:,2),'Ydir','normal');
set(gca,'visible','off');
stimPos=[]; h=[];
% center block only
switch ( testType ) 
case 'color';
  h(1) =rectangle('curvature',[1 1],'position',[[0;0]-stimRadius/2;stimRadius.*[1;1]],'facecolor',bgColor); 
case 'images';
  set(ax,'ydir','reverse'); % for images to display right way round....
    % ARGH: Matlab uses the xrange/yrange to say the center of the pixels
    % of the image.  Thus if you have very large pixels the size on the
    % screen is bigger....  Thus, for color blocks use a 20x20 image...
  h(1) =image([-1 1]*stimRadius/2,[-1 1]*stimRadius/2,repmat(reshape(bgColor,[1,1,3]),[20 20 1]));
otherwise;
  error('Unrecog test type');
end
% text object for instructions / user-interaction
set(stimfig,'Units','pixel');wSize=get(stimfig,'position');fontSize = .05*wSize(4);
instructh=text(min(get(ax,'xlim'))+.15*diff(get(ax,'xlim')),mean(get(ax,'ylim')),instructstr,'HorizontalAlignment','left','VerticalAlignment','middle','color',[0 1 0],'fontunits','pixel','FontSize',fontSize,'visible','off');

% add a 2nd figure for the detection curve?
detectfig=figure(3);set(detectfig,'Name','Detection curve');clf;
barh=bar((1:numel(levels))',zeros(size(levels)));
%set(gca,'xlim',[0 numel(levels)]);alphas(1)-diff(alphas(1:2)) alphas(end)+diff(alphas(end-1:end))]);
% ensure the stimulus figure is in the front
figure(2);

%==========================================================================
% 2. START STIMULUS PRESENTATION AND THE ACTUAL DISPLAY OF THINGS
%==========================================================================

%Change text object and display start-up texts
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'visible','off'); % make them all invisible
switch ( testType ) 
case 'color';   set(h(:),'facecolor',bgColor);
case 'images';  set(h(:),'cdata',repmat(reshape(bgColor,[1 1 3]),[20 20 1]));
end
set(instructh,'visible','on');
waitforbuttonpress;
set(instructh,'visible', 'off');

% ask for the target probability correct
set(instructh,'string',{'Please enter desired detection rate' 'in percent :'},'visible','on');
set(stimfig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
set(stimfig,'userdata',[]);
drawnow; % make sure the figure is visible
pcorrectstr=[];
while ( numel(pcorrectstr)<2 );
  modekey=[];  
  while ( isempty(modekey) ) 
	 pause(.2); modekey=get(stimfig,'userdata'); 
	 % BODGE: move the text a little to force key processing
	 if(exist('OCTAVE_VERSION','builtin'))
		if ( ~exist('dp','var') ) dp=+1e-3; else dp=-dp; end;
		set(instructh,'position',get(instructh,'position')+dp); 
	 end
  end;
  set(stimfig,'userdata',[]); % mark key consumed
  fprintf('key=%s\n',modekey);
  if ( isstr(modekey(1)) ) pcorrectstr=[pcorrectstr modekey(1)]; end
  set(instructh,'string',{'Please enter desired detection rate' ['in percent : ' pcorrectstr]});
  drawnow;
end
pcorrect=str2num(pcorrectstr)/100;
fprintf('pcorrect=%g\n',pcorrect);
pause(.5);
set(instructh,'visible','off');

%Send a start of training event
sendEvent('stimulus.training', 'start');

%Start the sequences
tgtIdx=1;
switch ( testType ) 
case 'color';   alphai=numel(levels)/2; % start in middle of the range
case 'images';  alphai=numel(levels); % start in edge of the range
end
hits = zeros(2,numel(levels));
for seqi = 1:nSeq
	 
  % make a simple odd-ball stimulus sequence, with targets mintti apart
  [stimSeq,stimTime,eventSeq] = mkStimSeqP300(1,seqDuration,isi,mintti,oddballp);
  
  % show the screen to alert the subject to trial start
  set(h(1:end-1),'visible','off');
  set(h(end),'visible','on');
  switch ( testType ) % red fixation indicates trial about to start/baseline
	 case 'color';      set(h(end),'facecolor',bgColor);
	 case 'images';     set(h(end),'cdata',repmat(reshape(fixColor,[1 1 3]),[20 20 1]));
  end
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');

  %Show target image
  switch ( testType ) % red fixation indicates trial about to start/baseline
	 case 'color';      set(h(end),'facecolor',tgtColor);
	 case 'images';     set(h(end),'cdata',repmat(reshape(tgtColor,[1 1 3]),[20 20 1]));
  end
  drawnow;
  sendEvent('stimulus.target',1);
  sleepSec(targetDuration);    
  set(h(:), 'visible', 'off');
  drawnow;
  if ( verb>0 ) fprintf('%d) tgt=%d\t',seqi,1); end;
  sleepSec(postTargetDuration);
  
  %Send an event to indicate that a sequence has started
  sendEvent('stimulus.sequence', 'start');
  % get current events status, i.e. discard all events before this time....
  status=buffer('wait_dat',[-1 -1 -1],buffhost,buffport); nevents=status.nevents;

  % now play the selected sequence
  seqStartTime=getwTime(); framei=0; ndropped=0; frametime=zeros(numel(stimTime),4); 
  nTgt=0; nPred=0; % track the stimulus, and prediction state
  while ( stimTime(end)>=getwTime()-seqStartTime ) % frame-dropping version    
	 framei=min(numel(stimTime),framei+1);
	 frametime(framei,1)=getwTime()-seqStartTime;
	 % find nearest stim-time
	 if ( framei<numel(stimTime) && frametime(framei,1)>=stimTime(min(numel(stimTime),framei+1)) ) 
      oframei = framei;
      for framei=framei+1:numel(stimTime); if ( frametime(oframei,1)<stimTime(framei) ) break; end; end; % find next valid frame
      if ( verb>=0 ) fprintf('%d) Dropped %d Frame(s)!!!\n',framei,framei-oframei); end;
      ndropped=ndropped+(framei-oframei);
	 end
	 
	 istarget=false;
	 ss=stimSeq(:,framei); % initial stimulus state, updated with actual used stimulus later
	 rawss=ss; % N.B. raw stim state used to decide what type of stimulus we should use
	 set(h(rawss<0),'visible','off');  % neg stimSeq codes for invisible stimulus
	 % everybody starts as background color
	 switch ( testType ) 
		case 'color';      set(h(rawss>=0),'facecolor',bgColor);
		case 'images';
		  % when oddball, 0=background & 2=standard, otherwise 0=standard
		  if ( oddballp ) set(h(rawss>=0),'cdata',repmat(reshape(bgColor*bgLevel,[1 1 3]),[20 20 1])); 
		  else            set(h(rawss>=0),'cdata',levels{1}); 
		  end
	 end
	 if(any(rawss==1))
		set(h(rawss>=0),'visible','on');
		istarget=true;
		% compute what stimulus we should use
		% alphai is index into the levels vector saying what stimulus we should actually be using
		leveli = max(1,min(round(alphai),numel(levels)));
		switch ( testType ) 
		  case 'color';
			 alpha = levels(leveli);
			 % interpolate between tgt/bgColor to get the 
			 color = colors(:,1) * alpha + colors(:,2)*(1-alpha);
			 set(h(rawss==1),'facecolor',color); 
			 ss(rawss==1)= alpha; % update the stim-state with the actual stim parameters
		  case 'images';
			 set(h(rawss==1),'cdata',levels{leveli});
			 ss(rawss==1)=leveli;
		end
	 end
	 if(any(rawss==2)) % std image
		set(h(rawss==2),'visible','on');
		switch ( testType ) 
		  case 'color';      
			 color=colors(:,min(size(colors,2),2));
			 set(h(rawss==2),'facecolor',color);
		  case 'images';
			 set(h(rawss==2),'cdata',levels{1});
		end
	 end;
	 if(any(rawss==3))
		set(h(rawss==3),'visible','on');
		color=colors(:,min(size(colors,2),3));
		switch ( testType ) 
		  case 'color';      set(h(rawss==2),'facecolor',color);
		  case 'images';     set(h(rawss==2),'cdata',repmat(reshape(color,[1 1 3]),[20 20 1]));
		end
	 end;
    
	 % sleep until time to update the stimuli the screen
	 if ( verb>1 ) fprintf('%d) Sleep : %gs\n',framei,stimTime(framei)-(getwTime()-seqStartTime)-flipInterval/2); end;
	 sleepSec(max(0,stimTime(framei)-(getwTime()-seqStartTime))); % wait until time to call the draw-now
	 if ( verb>1 ) frametime(framei,2)=getwTime()-seqStartTime; end;
	 drawnow;
	 if ( verb>1 ) 
      frametime(framei,3)=getwTime()-seqStartTime;
      fprintf('%d) dStart=%8.6f dEnd=%8.6f stim=[%s] lag=%g\n',framei,...
				  frametime(framei,2),frametime(framei,3),...
				  sprintf('%d ',stimSeq(:,framei)),stimTime(framei)-(getwTime()-seqStartTime));
	 elseif ( verb>=0 )
		if ( istarget ) fprintf('t'); else fprintf('.'); end;
	 end
	 % send event saying what we just showed
	 ev=[];
	 if ( ~isempty(eventSeq) )
		if ( ~isempty(eventSeq{si}) )
        ev=sendEvent(eventSeq{framei}{:});
		end
	 elseif ( any(ss>0) )
		ev=sendEvent('stimulus.stimState',ss);
	 end
    if (~isempty(ev) && verb>1) fprintf('%d) Event: %s\n',framei,ev2str(ev)); end;
	 
	 % record the displayed stimulus state, needed for decoding the classifier predictions later
	 % N.B. we only use targets, i.e NOT distractors for computing the hit rates....
	 if ( istarget )
		nTgt=nTgt+1;
		tgtSamp(1,nTgt)=ev.sample;  % record sample this event was sent
		dispStimSeq(:,nTgt)=ss;     % record the status of the display for this flash
	   % pred(:,nTgt)              % record of the classifier predictions for the corrospending events
	   % hits(:,2)                 % record the #times used, and #times hit for each stim
	 end

    % check for new events and collect
    status=buffer('wait_dat',[-1 -1 -1],buffhost,buffport); % non-blocking check for events
    if ( status.nevents > nevents ) % new events to process
      events=buffer('get_evt',[nevents status.nevents-1],buffhost,buffport);
      mi=matchEvents(events,'classifier.prediction');
      % store the predictions
      for ei=find(mi(:)');
        nPredei = find(tgtSamp(1:nTgt)==events(ei).sample); % find the flash this prediction is for
        if ( isempty(nPredei) ) % non-target, i.e. distractor response
          if ( verb>0 ) fprintf('Pred without flash =%g\n',events(ei).value); end;
			 % TODO: use the distractor outputs to adapt the hit/miss threshold...
          continue;
		  end
        nPred=max(nPred,nPredei(1)); % keep track of the number of predictions which are valid
        pred(:,nPredei)=events(ei).value;

		  ishit = pred(tgtIdx,nPredei)>0;
		  % update the hits list
		  switch ( testType ) % find the level-bin this is in
			 case 'color'; [ans,bini]=min(abs(levels-dispStimSeq(nPredei))); 
			 case 'images'; bini=dispStimSeq(nPredei);
		  end
		  hits(1,bini)=hits(1,bini)+1;      % counts
		  hits(2,bini)=hits(2,bini)+ishit;  % hits

		  % update the alphai, if hit then decrease alpha, is miss then decrease in porption to 
		  % desired target hit rate so at that hit-rate average value remains fixed
		  if ( ishit ) alphai=alphai-hitmissstep*(1-pcorrect); % hit so make harder => decrease
		  else 			alphai=alphai+hitmissstep*pcorrect;     % miss so make easier => increase
		  end;
		  alphai=min(numel(levels),max(1,alphai)); % limit the range of values...
		  
        if ( verb>0 ) 
			 if ( ishit ) hitmiss='hit'; else hitmiss='miss'; end;
			 fprintf('%d) samp=%d pred=%g (%4s) alphai=%g\n',...
						nTgt,tgtSamp(nPredei),pred(tgtIdx,nPredei),hitmiss,alphai); 
		  end;
      end

		% update the histogram display as we've got new predictions
		set(barh,'ydata',hits(2,:)'./max(1,hits(1,:)'));
    end
    nevents=status.nevents; % record which events we've processed

  end % sequence

  % reset the cue and fixation point to indicate trial has finished  
  switch ( testType ) 
	 case 'color';      set(h(:),'facecolor',bgColor,'visible','off');
	 case 'images';     set(h(:),'cdata',repmat(reshape(bgColor,[1 1 3]),[20 20 1]),'visible','off');
  end
  drawnow;
  sendEvent('stimulus.trial','end');
  sleepSec(interSeqDuration);

  fprintf('\n');
end

%Send an event to indicate that training has ended
sendEvent('stimulus.training', 'end');

%Thank subject and end experiment
if ( ishandle(instructh) ) 
set(instructh,'string', 'Thank you for participating!','visible', 'on');
drawnow;
end
