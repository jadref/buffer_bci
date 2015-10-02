seqLen=trainSeqLen;

%==========================================================================
% Initialize the display
%==========================================================================
%Set the frame size for the stimulus frame, make axes invisible, 
%remove menubar and toolbar. Also set the background color for the frame.
stimfig = figure(2);
clf;
set(stimfig,'Name','Experiment - Training',...
    'color',framebgColor,'menubar','none','toolbar','none',...
    'renderer','painters','doublebuffer','on','Interruptible','off');

ax=axes('position',[.1 .1 .8 .8],'visible','off','box','off','xtick',[], ...
        'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',axlim(:,1),'ylim',axlim(:,2),'ydir','reverse');
hold on;
    
%Create a text object with no text in it, center it, set font and color
set(stimfig,'Units','pixel');wSize=get(stimfig,'position');set(stimfig,'units','normalized');
txthdl = text(mean(axlim(:,1)),mean(axlim(:,2)), ' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',[0.75 0.75 0.75],'visible','off');
 
%Create the white square image
whiteSquare = ones(1,1,3); %RGB 1 white pixel

% Create image object with right size/position to hold the stimuli
% to update the image contents Use: set(imghdl,'cdata',newData)
% N.B.: Matlab automatically re-scales new data when added to fix the size of the 
%       box used here.
imghdl= image(axlim(:,1),axlim(:,2),whiteSquare, 'visible', 'off');

%==========================================================================
% LOAD & SET-UP TARGET PICTURES + TARGET PIECES + DISTRACTOR PIECES 
%==========================================================================
%Load the full target pictures
targets=loadnSliceImages(tgtDir);
dists  =loadnSliceImages(distDir);
fprintf('All images loaded.\n');

%==========================================================================
% 5. CREATE ARRAYS FOR RANDOM PICTURE/PIECE SELECTIONS AND FLASH ORDERS
%==========================================================================
    
%Create array to select shuffeled target pictures for all sequences 
tgtOrder = randperm(numel(targets));
tgtOrder = tgtOrder(1:min(end,nSeq));

%Create  arrays for all sequences with random numbers to select each 
%distractor piece that should be flashed
distOrder = zeros(seqLen,nSeq); % order of distractor pictures
distPieces= zeros(seqLen,nSeq); % order of distractor pieces of the picture
for i = 1:size(distPieces,2);
   for j = 1:size(distPieces,1);
	  distOrder(j,i)   = randi(numel(dists)); % randomly pick picture to get piece from
	  % randomly pick piece of this picture
	  distPieces(j, i) = randi(numel(dists(distOrder(j,i)).pieces)); 
   end
end

%==========================================================================
% 6. START STIMULUS PRESENTATION AND THE ACTUAL DISPLAY OF THINGS
%==========================================================================

%Change text object and display start-up texts
set(txthdl,'string', 'Click mouse when ready', 'visible', 'on')
waitforbuttonpress;
set(txthdl,'visible', 'off');

%Send a start of training event
sendEvent('stimulus.training', 'start');

%Start the sequences
for seqi = 1:nSeq
	 
	 tgtIdx = tgtOrder(1,seqi);
	 tgtInfo= targets(tgtIdx);

	 % generate flash the ordering for this sequence, min-3, max-9 between flashes
	 flashOrder = zeros(seqLen,1);
	 si=ceil(rand(1)*tti/2); while si<numel(flashOrder); flashOrder(si)=1; si=si+ceil((.5+rand(1))*tti); end; 
	 % generate a piece order for this sequence
	 % random order of bits, but not the same one within 3 of itself
	 tgtPiecesSeq=mkStimSeqRand(numel(tgtInfo.pieces),sum(flashOrder>0),1,3);
	 tgtPieces=[]; for ei=1:size(tgtPiecesSeq,2); tgtPieces(ei,1)=find(tgtPiecesSeq(:,ei)>0,1); end;

    %When it is not the last sequence, show the countdown
    if (~(seqi==nSeq))
        endTime=getwTime()+countdownDuration;
        while getwTime()<endTime;
            set(txthdl,'string', ...
                sprintf('Next sequence in.. %3.1f',endTime-getwTime()),...
                'visible', 'on');
            drawnow;
            sleepSec(1);
        end
        set(txthdl,'visible', 'off');
        drawnow;
    end
    
    % [fn] = uigetfile(fullfile(fileparts(mfilename('fullpath')),'pictures/targets/*.jpg'),'Pick a Target');
    % fn = fn(1:end-4);
    % for tix = 1:size(targets,2)
        % if (find(strcmp(targets(tix).name, fn)) == 1)
            % tgtIdx = tix;
        % end
    % end
    %Show target image
    set(imghdl,'cdata',tgtInfo.image,'visible','on');
    drawnow;
    sendEvent('stimulus.target.image',tgtInfo.name);
    sleepSec(targetDuration);
    
    set(imghdl, 'visible', 'off');
    drawnow;
	 if ( verb>0 ) fprintf('%d) tgt=%s\t',seqi,tgtInfo.name); end;
    sleepSec(postTargetDuration);
     
    %Send an event to indicate that a sequence has started
    sendEvent('stimulus.sequence', 'start');

    piecesTaken = 0;
    distTaken = 0;
    %Flash pieces in the center of the screen
    seqStartTime=getwTime();
    % time in sec from seq start when stimulus should occur
    stimTime=(1:seqLen)*(stimDuration+whiteSquareDuration);
    for stimi = 1:seqLen
        %Flash the next piece
        %If the random order array says target take the next target piece
        if (flashOrder(stimi, min(end,seqi)) == 1)
           piecesTaken= piecesTaken + 1;
			  flashVal   = 'target';
			  imgInfo    = tgtInfo;
           piece      = tgtPieces(piecesTaken, min(end,seqi));

        %If the random order array says distractor take the next distractor
        elseif (flashOrder(stimi, min(end,seqi)) == 0)
          distTaken  = distTaken + 1;
			 distIdx    = distOrder(distTaken,seqi);
			 flashVal   = 'dist';
			 imgInfo    = dists(distIdx);
          piece      = distPieces(distTaken, seqi);
		  end

		  % show the choosen image
		  img    = imgInfo.pieces{piece};
		  set(imghdl,'cdata',imgInfo.pieces{piece}); % update the image
		  %% imghdl = image(linspace(0,1,size(img,2)),linspace(0,1,size(img,1)),...
		  %% 					  img, 'visible', 'off');
        set(imghdl, 'visible', 'on');
        % sleep until the draw time
        sleepSec(max(0,stimTime(stimi) - (getwTime()-seqStartTime)));
        drawnow;        
        %send events describing what just happened
        sendEvent('stimulus.target', flashVal);                       % target state
		  sendEvent('stimulus.image', sprintf('%s/%d',imgInfo.name,piece)); % image info
		  if ( verb>0 ) if flashOrder(stimi, min(end,seqi)) fprintf('t'); else fprintf('.'); end; end;
        
        %Flash the white square
        set(imghdl,'cdata',whiteSquare,'visible','on');
        % sleep until the white-square time
        sleepSec(max(0,stimTime(stimi)+stimDuration - (getwTime()-seqStartTime)));
        drawnow;
        sendEvent('stimulus.blank', 1);
    end
    sleepSec(whiteSquareDuration);
	if ( verb>0 ) fprintf('\n'); end;

    %Cover last flashed piece up
    set(imghdl,'visible','off');
    drawnow;    
    %Send an event to indicate the sequence has ended
    sendEvent('stimulus.sequence', 'end');
    
    sleepSec(interSeqDuration);    
end

%Send an event to indicate that training has ended
sendEvent('stimulus.training', 'end');

%Thank subject and end experiment
set(txthdl,'string', 'Thank you for participating!','visible', 'on');
drawnow;
sleepSec(textDuration);
