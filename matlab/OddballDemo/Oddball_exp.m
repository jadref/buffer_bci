%% Oddball experiment - EEG Demo %%

%% SETTINGS %%

% Clear the workspace and the screen
sca;
close all;
clearvars;

% Buffer_bci toolbox
addpath('../utilities/');
initPaths;

% Connect to the buffer:
buffhost='localhost';buffport=1972;
% wait for the buffer to return valid header information
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

% User settings
picture_version = true; % true = run picture version, false = run non-picture version
n_trials = 3 0; % indicate number of trials
stimulus_duration = 0.07; % secs
%handle = PsychRTBox('Open', [], [0]); % uncomment to send markers (then
%also uncomment buttonbox(marker)

Screen('Preference', 'SkipSyncTests', 1);

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if available
screenNumber = max(screens);

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Open an on screen window
[window, rect] = PsychImaging('OpenWindow', screenNumber, black,[75 75 950 950]);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Setup the text type for the window
Screen('TextFont', window, 'Ariel');
Screen('TextSize', window, 36);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(rect);

% Enable to send markers
%handle = PsychRTBox('Open', [], [0]);

%% STIMULI %%

% Here we set the size of the arms of our fixation cross
fixCrossDimPix = 20;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

% Set the line width for our fixation cross
lineWidthPix = 2;

if picture_version
    % Here we load in an images from file
    Image1_Location = fullfile('image','donders.jpg');
    Image_1 = imread(Image1_Location);
    
    Image2_Location = fullfile ('image','stress.jpg');
    Image_2 = imread(Image2_Location);
    
    % Get the size of the image
    [s1, s2, s3] = size(Image_1);
    [s4, s5, s6] = size(Image_2);
    
    % Here we check if the image is too big to fit on the screen and abort if
    % it is. See ImageRescaleDemo to see how to rescale an image.
    if s1 > screenYpixels || s2 > screenYpixels
        disp('ERROR! Image is too big to fit on the screen');
        sca;
        return;
    end
    
    % Resize images so that they are equal
    % Get size of existing image A.
    [rowsImage_1 colsImage_1 numberOfColorChannelsImage_1] = size(Image_1);
    % Get size of existing image B.
    [rowsImage_2 colsImage_2 numberOfColorChannelsImage_2] = size(Image_2);
    % See if lateral sizes match.
    if rowsImage_2 ~= rowsImage_1 || colsImage_1 ~= colsImage_2;
        % Size of B does not match A, so resize B to match A's size.
        Image_2 = imresize(Image_2, [rowsImage_1 colsImage_1]);
    end
    
    % Make the image into a texture
    imageTexture_1 = Screen('MakeTexture', window, Image_1);
    imageTexture_2 = Screen('MakeTexture', window, Image_2);
end

% Create array of ones and zeros with 1=75% prob and 0=25% prob
percentageOfOnes = 75; 
numberOfOnes = round(n_trials * percentageOfOnes / 100);
% Make initial signal with proper number of 0's and 1's.
S = [ones(1, numberOfOnes), zeros(1, n_trials - numberOfOnes)];
% Scramble them up with randperm
S = S(randperm(length(S)));
% Count them just to prove it
numOnes = sum(S);

%% RUN EXPERIMENT %%

% Start screen
% Draw text in the middle of the screen in Courier in white
Screen('TextSize', window, 15);
Screen('TextFont', window, 'Arial');
DrawFormattedText(window, 'Press a key to start', 'center', 'center', white);

% Flip to the screen
Screen('Flip', window);

% Send trigger to start
sendEvent('experiment','start');

% Wait for a key press 
KbStrokeWait

for i=1:n_trials
    
    % Draw the fixation cross in white, set it to the center of our screen and
    % set good quality antialiasing
    Screen('DrawLines', window, allCoords,...
        lineWidthPix, white, [xCenter yCenter], 2);
    
    % Flip to the screen
    Screen('Flip', window);
    display(sprintf('Trial %d out of %d', i, n_trials))
    
    % Wait for two seconds
    WaitSecs((randi([750 1250],1)/1000));
    
    if S(i) == 1
        if picture_version
            % Draw the image to the screen, unless otherwise specified PTB will draw
            % the texture full size in the center of the screen.
            Screen('DrawTexture', window, imageTexture_1, [], [], 0);
        else
            Screen('TextSize', window, 60);
            DrawFormattedText(window, 'H', 'center', 'center', white);
        end
        
        % Flip to the screen
        Screen('Flip', window);
        sendEvent('stimulus','target'); % send trigger for target stimulus (1st argument = event type, 2nd argument = event value)
        %buttonbox(1); % stimulus marker for regular stimuli
        display(sprintf('Sent marker for %s at time = %.2f', 'regular', GetSecs()));
        
        % Wait for stimulus duration
        WaitSecs(stimulus_duration);
    elseif S(i) == 0
        if picture_version
            % Draw the image to the screen, unless otherwise specified PTB will draw
            % the texture full size in the center of the screen.
            Screen('DrawTexture', window, imageTexture_2, [], [], 0);
        else
            Screen('TextSize', window, 60);
            DrawFormattedText(window, 'O', 'center', 'center', white);
        end
        
        % Flip to the screen
        Screen('Flip', window);
        sendEvent('stimulus','deviant'); % send trigger for odd (1st argument = event type, 2nd argument = event value)
        %buttonbox(2); % stimulus marker for odd stimuli
        display(sprintf('Sent marker for %s at time = %.2f', 'odd', GetSecs()));
        
        % Wait for stimulus duration
        WaitSecs(stimulus_duration);
    end
end

% Flip to the screen
Screen('Flip', window);

% Wait for 2 seconds
WaitSecs(2);

% Draw text in the middle of the screen in Courier in white
Screen('TextSize', window, 15);
Screen('TextFont', window, 'Arial');
DrawFormattedText(window, 'Thank you', 'center', 'center', white);

% Flip to the screen
Screen('Flip', window);

% Send trigger to end
sendEvent('experiment','end');

% Now we have drawn to the screen we wait for a keyboard button press (any
% key) to terminate the demo
KbStrokeWait;

% Clear the screen
sca;