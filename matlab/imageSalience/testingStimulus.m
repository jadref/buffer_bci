%==========================================================================
% 1. STANDARD STUFF (CONNECTING TO BUFFER & SETTING TIME):
%==========================================================================

run ../utilities/initPaths.m;

buffhost='localhost'; buffport=1972;
% Wait for the buffer to return valid header information
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

% Set the real-time-clock to use
initgetwTime;
initsleepSec;

%==========================================================================
% 2. SET 'GLOBAL' VARIABLES FOR EXPERIMENT VARIABLES
%==========================================================================

tgtDir ='pictures/test';
distDir='pictures/distractors';

nSeq = 6;
nFlashes = 30; 
nPicFlashes = 6;
nPicPieces = 12;
nTargets = 2;

textDuration=5;
targetDuration=5;
countdownDuration = 1;
whiteSquareDuration=0.1;
stimDuration=0.4;
feedbackDuration = 7;

%==========================================================================
% 3. CREATE STIMULUS FRAME AND SET UP TEXT OBJECT + WHITE SQUARE
%==========================================================================

frameWidth = 1024;
frameHeight = 768;
frameBackgroundColor = [0 0 0];
whiteSquareColor = [1 1 1];
pictureWidth = 800;
pictureHeight = 600;
pieceHeight = 200; 
pieceWidth = 200;
fullPicLocation = [((frameWidth/2)-(pictureWidth/2)), ((frameHeight/2)-(pictureHeight/2))];
pieceLocation = [((frameWidth/2)-(pieceWidth*0.5)), ((frameHeight/2)-(pieceHeight*0.5))];
widthGrid = 4;
heightGrid = 3;
deltaOpacity = 1/(nSeq/2);

%Set the frame size for the stimulus frame, make axes invisible, 
%remove menubar and toolbar. Also set the background color for the frame.
stimulusFig = figure(1);
set(stimulusFig, 'Position', [0 0 frameWidth frameHeight]);
set(stimulusFig, 'MenuBar', 'none');
set(stimulusFig, 'ToolBar', 'none');
set(stimulusFig, 'Name', 'Experiment - Training');
ax=axes('position',[0 0 1 1],'visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[0 frameWidth],'ylim',[0 frameHeight],'ydir','reverse');
set(stimulusFig, 'Color', frameBackgroundColor);
hold on;

%Create a text object with no text in it, center it, set font and color
t = text((frameWidth/2), (frameHeight/2), '',...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
    'FontUnits', 'normalized', 'fontsize', 0.07,...
    'color',[0.75 0.75 0.75],'visible','off');

%Create the white square and a cover up
whiteSquare = rectangle('Position', [pieceLocation(1,1),... 
        pieceLocation(1,2), pieceWidth-1, pieceHeight-1],...
        'EdgeColor' , frameBackgroundColor,...
        'FaceColor', whiteSquareColor, 'visible', 'off'); 
black = rectangle('Position', [0, 0, frameWidth, frameHeight],...
        'EdgeColor', frameBackgroundColor,...
        'FaceColor', frameBackgroundColor, 'visible', 'off');

%==========================================================================
% 4. LOAD & SET-UP TARGET PICTURES + TARGET PIECES + DISTRACTOR PIECES 
%==========================================================================

%Load the full target pictures
targets=loadnSliceImages(tgtDir);
dists=loadnSliceImages(distDir);
   
%==========================================================================
% 5. SET-UP OF VARIABLES FOR DISPLAYING THE RECONSTRUCTED PICTURE
%==========================================================================

%There should be a grid matrix with the target pieces
cityGridPieces = {target1, target2, target3, target4;...
                  target5, target6, target7, target8;...
                  target9, target10, target11, target12};
logoGridPieces = {Logos1, Logos2, Logos3, Logos4;...
                  Logos5, Logos6, Logos7, Logos8;...
                  Logos9, Logos10, Logos11, Logos12};

%The grid matrices are put into a general grid array
gridArrays = {cityGridPieces, logoGridPieces};
              
%Define the locations for the display of picture pieces in the
%reconstruction
pieceLoc1  = [((frameWidth/2) - (2*pieceWidth)),...
             ((frameHeight/2) - (1.5*pieceHeight))];
pieceLoc2  = [((frameWidth/2) - (1*pieceWidth)),...
             ((frameHeight/2) - (1.5*pieceHeight))];
pieceLoc3  = [((frameWidth/2) + (0*pieceWidth)),...
             ((frameHeight/2) - (1.5*pieceHeight))];
pieceLoc4  = [((frameWidth/2) + (1*pieceWidth)),...
             ((frameHeight/2) - (1.5*pieceHeight))];
pieceLoc5  = [((frameWidth/2) - (2*pieceWidth)),...
             ((frameHeight/2) - (0.5*pieceHeight))];
pieceLoc6  = [((frameWidth/2) - (1*pieceWidth)),...
             ((frameHeight/2) - (0.5*pieceHeight))];
pieceLoc7  = [((frameWidth/2) + (0*pieceWidth)),...
             ((frameHeight/2) - (0.5*pieceHeight))];
pieceLoc8  = [((frameWidth/2) + (1*pieceWidth)),...
             ((frameHeight/2) - (0.5*pieceHeight))];
pieceLoc9  = [((frameWidth/2) - (2*pieceWidth)),...
             ((frameHeight/2) + (0.5*pieceHeight))];
pieceLoc10 = [((frameWidth/2) - (1*pieceWidth)),...
             ((frameHeight/2) + (0.5*pieceHeight))];
pieceLoc11 = [((frameWidth/2) + (0*pieceWidth)),...
             ((frameHeight/2) + (0.5*pieceHeight))];
pieceLoc12 = [((frameWidth/2) + (1*pieceWidth)),...
             ((frameHeight/2) + (0.5*pieceHeight))];

%Put all of the locations in a single array
pieceLocs = {pieceLoc1, pieceLoc2, pieceLoc3, pieceLoc4; pieceLoc5, pieceLoc6,...
             pieceLoc7, pieceLoc8; pieceLoc9, pieceLoc10, pieceLoc11, pieceLoc12};

%==========================================================================
% 6. CREATE ARRAYS FOR RANDOM PICTURE/PIECE SELECTIONS AND FLASH ORDERS
%==========================================================================

%Choose one of the targets at random and set its pieces and grid
targetNo = randi(nTargets);
targetPicture = targetPictures{1, targetNo};
targetPiecesArray = targetPieces{1, targetNo};
gridPieces = gridArrays{1, targetNo};

%This array indicates whether a target or distractor should be flashed
%ALSO has a build in check for at least 3 zero's in between 1's.
%A 0 is a distractor, a 1 is a target 
randomFlashOrder = zeros(nFlashes, nSeq);
for i = 1:nSeq
    ok = true;
    while (ok)
        ok = true;
        x = [ones(1, nPicFlashes) zeros(1, nFlashes-nPicFlashes)];
        y = randperm(nFlashes);
        randomFlashOrder(:,i) = x(y)';
        indices = find(randomFlashOrder(:,i) == 1);
        if (all(diff(indices) > 3))
            ok = false;
        end
    end
end

%Create random arrays for all sequences with random numbers to select each
%target piece that should be flashed
randomPicPieces = zeros(nPicPieces/2, nSeq);
for i = 1:2:nSeq
    x = randperm(nPicPieces)';
    randomPicPieces(:,i) = x(1:floor(nPicPieces/2), 1);
    randomPicPieces(:,i+1) = x(ceil((nPicPieces/2)+1):nPicPieces, 1);
end

%Create random arrays for all sequences with random numbers to select each 
%distractor piece that should be flashed (= number of flashes - number of
%target pieces that is flashed)
randomDistractors = zeros((nFlashes-nPicFlashes),nSeq);
for i = 1:nSeq
   for j = 1:(nFlashes - nPicFlashes)
      randomDistractors(j, i) = randi(size(distractorPieces, 2)); 
   end
end

%Preallocate pieces to array
pArray = cell(nFlashes, nSeq);
for seq = 1:nSeq
    piecesTaken = 0;
    distTaken = 0;
    for nF = 1:nFlashes
        %If the random order array says target take the next target piece
        if (randomFlashOrder(nF, seq) == 1)
            piecesTaken = piecesTaken + 1;
            chosenPiece = randomPicPieces(piecesTaken, seq);
            
            pArray{nF, seq} = targetPiecesArray{1, chosenPiece};
        
        %If the random order array says distractor take the next distractor
        elseif (randomFlashOrder(nF, seq) == 0)
            distTaken = distTaken + 1;
            chosenPiece = randomDistractors(distTaken, seq);
            
            pArray{nF, seq} = distractorPieces{1, chosenPiece};
        end
    end
end

%Initialize a matrix to save the opacity of the recognized pieces
seen = zeros(heightGrid,widthGrid);

%==========================================================================
% 6. START STIMULUS PRESENTATION AND THE ACTUAL DISPLAY OF THINGS
%==========================================================================

%Change text object and display start-up texts
set(t, 'string', 'Press SPACE when ready');
set(t, 'visible', 'on')
waitforbuttonpress;
set(t, 'visible', 'off');

%Set the state
state = hdr.nEvents;
sendEvent('stimulus.testing', 'start');

%Start the sequences
for seq = 1:nSeq
    
    %Send an event to indicate that a sequence has started
    sendEvent('stimulus.sequence', 'start');

    %Show target image
    I = image(fullPicLocation(1,1), fullPicLocation(1,2),...
        targetPicture, 'visible', 'off');
    set(I, 'visible', 'on');
    drawnow;
    sleepSec(targetDuration);
    
    set(I, 'visible', 'off');
    drawnow;
    
    %Flash pieces in the center of the screen
    for nF = 1:nFlashes
        
        %Flash the next piece
        I = image(pieceLocation(1,1), pieceLocation(1,2), pArray{nF, seq}, 'visible', 'off');
        set(I, 'visible', 'on');
        drawnow;
        
        %Send an event to indicate that a picture was flashed
        sendEvent('stimulus.flashPicture', 'flash');
        sleepSec(stimDuration);
        
        %Flash the white square
        delete(I);
        uistack(whiteSquare, 'top');
        set(whiteSquare, 'visible', 'on');
        drawnow;
        sleepSec(whiteSquareDuration);
    end

    %Remove the white square
    set(whiteSquare, 'visible', 'off');
    drawnow;
    
    %Send an event to indicate the sequence has ended
    sendEvent('stimulus.sequence', 'end');
    
    %Wait for predictions (= predictions event)
    fprintf(1,'Waiting for predictions\n');
    %Collect predictions even
    [devents,state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],500);
    
    %If there is at least one event read out predictions if available
    if ( ~isempty(devents) ) 
        predictions = devents(1).value(:);
        pp = 0;
        %Look in the flash order and if a piece was a target piece check if
        %it was recognized
        for i = 1:size(randomFlashOrder,1)
            if(randomFlashOrder(i, seq) == 1)
                pp = pp+1;
                pieceNr = randomPicPieces(pp, seq);
                pred = 0;
                %Seen = < 0
                if (predictions(i) < 0)
                    pred = 1;
                end
                
                %Change the opacity for the pieces that have been seen
                switch pieceNr
                    case 1
                    seen(1,1) = seen(1,1) + pred*deltaOpacity;
                    case 2
                    seen(1,2) = seen(1,2) + pred*deltaOpacity;
                    case 3
                    seen(1,3) = seen(1,3) + pred*deltaOpacity;
                    case 4
                    seen(1,4) = seen(1,4) + pred*deltaOpacity;    
                    case 5
                    seen(2,1) = seen(2,1) + pred*deltaOpacity;    
                    case 6
                    seen(2,2) = seen(2,2) + pred*deltaOpacity;    
                    case 7
                    seen(2,3) = seen(2,3) + pred*deltaOpacity;    
                    case 8
                    seen(2,4) = seen(2,4) + pred*deltaOpacity;    
                    case 9 
                    seen(3,1) = seen(3,1) + pred*deltaOpacity;    
                    case 10
                    seen(3,2) = seen(3,2) + pred*deltaOpacity;    
                    case 11
                    seen(3,3) = seen(3,3) + pred*deltaOpacity;   
                    case 12
                    seen(3,4) = seen(3,4) + pred*deltaOpacity;    
                    otherwise
                    disp('otherwise')
                end
            end
        end
        
        %Display the reconstructed picture with the 'seen' opacities
        for i = 1:heightGrid
            for j = 1:widthGrid
                if (seen(i,j) == 1)
                    image(pieceLocs{i, j}(1,1), pieceLocs{i, j}(1,2), gridPieces{i, j}, 'visible', 'on');
                else
                    image(pieceLocs{i, j}(1,1), pieceLocs{i, j}(1,2), gridPieces{i, j}, 'visible', 'on', 'AlphaData', seen(i,j));
                end
            end
        end
        drawnow;
    end;
    sleepSec(feedbackDuration);
    
    %Cover the reconstructed image up
    uistack(black, 'top');
    set(black, 'visible', 'on');
    drawnow;
    
    %When it is not the last sequence, show the countdown
    if (~(seq==nSeq))
        uistack(t, 'top');
        set(t, 'string', 'Next sequence in.. 3');
        set(t, 'visible', 'on');
        drawnow;
        sleepSec(countdownDuration);
        set(t, 'visible', 'off');
        drawnow;

        set(t, 'string', 'Next sequence in.. 2');
        set(t, 'visible', 'on');
        drawnow;
        sleepSec(countdownDuration);
        set(t, 'visible', 'off');
        drawnow;

        set(t, 'string', 'Next sequence in.. 1');
        set(t, 'visible', 'on');
        drawnow;
        sleepSec(countdownDuration);
        set(t, 'visible', 'off');
        drawnow;
    end
    
end

%Send an event to indicate that testing has ended
sendEvent('stimulus.testing', 'end');

%Thank subject and end experiment
uistack(t, 'top');
set(t, 'string', 'Thank you for participating!');
set(t, 'visible', 'on');
drawnow;
sleepSec(textDuration);
set(t, 'visible', 'off');
drawnow;

%Show the final reconstructed image again
for i = 1:heightGrid
    for j = 1:widthGrid
        if (seen(i,j) == 1)
            image(pieceLocs{i, j}(1,1), pieceLocs{i, j}(1,2), gridPieces{i, j}, 'visible', 'on');
        else
            image(pieceLocs{i, j}(1,1), pieceLocs{i, j}(1,2), gridPieces{i, j}, 'visible', 'on', 'AlphaData', seen(i,j));
        end
    end
end
drawnow;
