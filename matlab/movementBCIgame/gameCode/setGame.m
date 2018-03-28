% Define all game settings
function setGame(subject)
    % define stimuli:
    neutralColor       = [.8 .8 .8];
    compWinsColor      = [1 0 0];
    humanWinsColor     = [0 1 0];
    feedbackColor      = [0 0 0];
    textColor          = [1 1 1];

    % set game specific variables:
    min_trial_dur      = 3; % minimum time during which the circle stays visible after a button press in secs.
    max_trial_dur      = 6; % maximum time during which the circle stays visible after a button press in secs.
    min_time           = 3; % minimum time after which the computer can act in secs.
    max_time           = 15; % maximum time after which the computer can act in secs.
    sim_time           = 2; % added time (in secs) to computer move to simulate a human move in that trial (to slow computer predictions down)
    baselineDuration   = 2; % time of fixation cross in secs.
    trialDuration      = 15; % maximum trial duration in secs.
    interTrialDuration = 1; % time black screen in beween trials in secs.
    nSeq               = 5; % nr of trials within a round
    nr_blocks          = 2; % nr of rounds in the game
    start_range        = (0:.05:.2); % initial size of the circle
    max_range          = (.8:.05:1); % growth of the circle
    
    % initialize data variables:
    score              = [0 0]; % human vs. computer
    rthuman            = []; % action time human
    rtcomputer         = []; % action time computer
    planned_comp       = []; % planned action of computer

    % durations for the labelling of EMG and EEG data
    eventInterval      = 0.25; % send event every eventInterval (in secs)
    startupArtDur      = 1; % period at start of trial to remain unlabeled (in secs)
    endArtDur          = -1.5; % period at end of trial to remain unlabeled (in secs)
    nonMoveLowerBound  = -3.5; % minimum rest period prior to an action (in secs)
    nonMoveUpperBound  = 2; % minimum rest period after an action (in secs)
    premoveLowerBound  = -2; % minimum movement preparation period prior to an action (in secs)
    premoveUpperBound  = -1.5; % maximum movement preparation period prior to an action (in secs)
    postmoveLowerBound = 0; % minimum movement period after an action (in secs)
    postmoveUpperBound = 0.5; % maximum movement period after an action (in secs)
    
    save(['gameSettings_subject_',num2str(subject)]);
end