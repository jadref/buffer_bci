function [robot_data, scientist_data] = flipThatBucket()
    % clear workspace
    clear all
    close all

    % define some game parameters
    global actionType;
    global actionTimeScientist;
    global playerActSamp;
    global checkKeys;
    global answer;
    scientist_highscore = 0.001;
    min_startup = 1;
    dur_premove = 1;
    train_size = 0.5; % size of train data length in seconds (what will be slices prior to a baseline/premove/nonmove event for training the classifier)
    update_rate = 0.2; % how often update screen
    baseline_duration = 2; % in secs
    post_trial_duration = 1; % in secs
    window_size = [90 50 890 570];
    color_slime_face = [34/255 181/255 115/255];
    min_actions_for_pred = 5;
    color_slime_edge = 'green';
    chance_blink = 20;
    score_width = 40;
    max_scorebar = 450;
    max_trials = [1 10 5 10];%[3 50 15 60]; % trials per block
    max_blocks = 4;
    min_trial_length = 4/0.2; 
    max_trial_length = 7/0.2; 
    muAct = 8;
    sigmaAct = 2;
    checkKeys = true;
    answer = 0;
    handles = [];
    images = [];
    threshold = 0; % classifier threshold for move prediction (based on SPRT)
    
    load('highscores');
    
    % memory for data
    robot_data = []; 
    robot_data.actionOnset = zeros(max(max_trials),max_blocks);
    robot_data.predOnset = zeros(max(max_trials),max_blocks);
    robot_data.won = zeros(max(max_trials),max_blocks);
    robot_data.score = zeros(max(max_trials),max_blocks);
    scientist_data = [];
    scientist_data.actionOnset = zeros(max(max_trials),max_blocks);
    scientist_data.won = zeros(max(max_trials),max_blocks);
    scientist_data.score = zeros(max(max_trials),max_blocks);
    scientist_data.wantedToact = ones(max(max_trials),max_blocks);
    scientist_data.questionnaire = zeros(max(max_blocks),4); % 4 questions per block

    % read in all stimuli files
    [images.background_level1,map,images.alpha_background_level1]               = imread(fullfile('stimuli','background_level1.png'));
    [images.bucket_no_slime,map,images.alpha_bucket_no_slime]                   = imread(fullfile('stimuli','bucket_no_slime.png'));
    [images.bucket_slime_1,map,images.alpha_bucket_slime_1]                     = imread(fullfile('stimuli','bucket_slime_1.png'));
    [images.bucket_slime_2,map,images.alpha_bucket_slime_2]                     = imread(fullfile('stimuli','bucket_slime_2.png'));
    [images.bucket_slime_3,map,images.alpha_bucket_slime_3]                     = imread(fullfile('stimuli','bucket_slime_3.png'));
    [images.bucket_slime_4,map,images.alpha_bucket_slime_4]                     = imread(fullfile('stimuli','bucket_slime_4.png'));
    [images.bucket_slime_5,map,images.alpha_bucket_slime_5]                     = imread(fullfile('stimuli','bucket_slime_5.png'));
    [images.bucket_slime_6,map,images.alpha_bucket_slime_6]                     = imread(fullfile('stimuli','bucket_slime_6.png'));
    [images.scientist_neutral,map,images.alpha_scientist_neutral]               = imread(fullfile('stimuli','scientist_neutral.png'));
    [images.scientist_blink,map,images.alpha_scientist_blink]                   = imread(fullfile('stimuli','scientist_blink.png'));
    [images.scientist_press_1,map,images.alpha_scientist_press_1]               = imread(fullfile('stimuli','scientist_press_1.png'));
    [images.scientist_press_2,map,images.alpha_scientist_press_2]               = imread(fullfile('stimuli','scientist_press_2.png'));
    [images.scientist_slime_1,map,images.alpha_scientist_slime_1]               = imread(fullfile('stimuli','scientist_slime_1.png'));
    [images.scientist_slime_little_2,map,images.alpha_scientist_slime_little_2] = imread(fullfile('stimuli','scientist_slime_little_2.png'));
    [images.scientist_slime_little_3,map,images.alpha_scientist_slime_little_3] = imread(fullfile('stimuli','scientist_slime_little_3.png'));
    [images.scientist_slime_little_4,map,images.alpha_scientist_slime_little_4] = imread(fullfile('stimuli','scientist_slime_little_4.png'));   
    [images.scientist_slime_medium_2,map,images.alpha_scientist_slime_medium_2] = imread(fullfile('stimuli','scientist_slime_medium_2.png'));
    [images.scientist_slime_medium_3,map,images.alpha_scientist_slime_medium_3] = imread(fullfile('stimuli','scientist_slime_medium_3.png'));
    [images.scientist_slime_medium_4,map,images.alpha_scientist_slime_medium_4] = imread(fullfile('stimuli','scientist_slime_medium_4.png'));
    [images.scientist_slime_lots_2,map,images.alpha_scientist_slime_lots_2]     = imread(fullfile('stimuli','scientist_slime_lots_2.png'));
    [images.scientist_slime_lots_3,map,images.alpha_scientist_slime_lots_3]     = imread(fullfile('stimuli','scientist_slime_lots_3.png'));
    [images.scientist_slime_lots_4,map,images.alpha_scientist_slime_lots_4]     = imread(fullfile('stimuli','scientist_slime_lots_4.png'));
    [images.robot_neutral,map,images.alpha_robot_neutral]                       = imread(fullfile('stimuli','robot_neutral.png'));
    [images.robot_blink,map,images.alpha_robot_blink]                           = imread(fullfile('stimuli','robot_blink.png'));
    [images.robot_press_1,map,images.alpha_robot_press_1]                       = imread(fullfile('stimuli','robot_press_1.png'));
    [images.robot_press_2,map,images.alpha_robot_press_2]                       = imread(fullfile('stimuli','robot_press_2.png'));
    [images.robot_press_3,map,images.alpha_robot_press_3]                       = imread(fullfile('stimuli','robot_press_3.png'));
    [images.robot_slime_1,map,images.alpha_robot_slime_1]                       = imread(fullfile('stimuli','robot_slime_1.png'));
    [images.robot_slime_little_2,map,images.alpha_robot_slime_little_2]         = imread(fullfile('stimuli','robot_slime_little_2.png'));
    [images.robot_slime_little_3,map,images.alpha_robot_slime_little_3]         = imread(fullfile('stimuli','robot_slime_little_3.png'));
    [images.robot_slime_little_4,map,images.alpha_robot_slime_little_4]         = imread(fullfile('stimuli','robot_slime_little_4.png'));
    [images.robot_slime_medium_2,map,images.alpha_robot_slime_medium_2]         = imread(fullfile('stimuli','robot_slime_medium_2.png'));
    [images.robot_slime_medium_3,map,images.alpha_robot_slime_medium_3]         = imread(fullfile('stimuli','robot_slime_medium_3.png'));
    [images.robot_slime_medium_4,map,images.alpha_robot_slime_medium_4]         = imread(fullfile('stimuli','robot_slime_medium_4.png'));
    [images.robot_slime_lots_2,map,images.alpha_robot_slime_lots_2]             = imread(fullfile('stimuli','robot_slime_lots_2.png'));
    [images.robot_slime_lots_3,map,images.alpha_robot_slime_lots_3]             = imread(fullfile('stimuli','robot_slime_lots_3.png'));
    [images.robot_slime_lots_4,map,images.alpha_robot_slime_lots_4]             = imread(fullfile('stimuli','robot_slime_lots_4.png'));

    slime_bucket = {images.bucket_slime_1 images.alpha_bucket_slime_1; images.bucket_slime_2 images.alpha_bucket_slime_2; images.bucket_slime_3 images.alpha_bucket_slime_3;...
                    images.bucket_slime_4 images.alpha_bucket_slime_4; images.bucket_slime_5 images.alpha_bucket_slime_5; images.bucket_slime_6 images.alpha_bucket_slime_6};
                
    % init paths to buffer BCI
    run(fullfile('~','buffer_bci','matlab','utilities','initPaths.m'));
    addpath('code');
                
    % connect to the BCI buffer:
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
    save('hdr','hdr');
                 
    % get pp code
    prompt = {'Enter participant code:'};
    title = 'Code';
    dims = [1 35];
    definput = {'laptop2_pp1'};
    code = inputdlg(prompt,title,dims,definput);
    datafile = [code{1} datestr(now,'mm-dd-yyyy_HH-MM')];
    sendEvent('participant',code{1});
    player = code{1};
    save(fullfile('player'), 'player');
    
    % start the ERPviewer
    % "/Applications/MATLAB_R2015b.app/bin/matlab" (for Mac)
    % "C:\Program Files\MATLAB\R2015b\bin\matlab" (for Windows)
    % cd('E:\Experiment\Documents\slimegame') (Windows demo computer)
    % cd('/Users/ceciverbaarschot/buffer_bci/matlab/movementBCIgame/FlipThatBucket') (my computer)
    !"/Applications/MATLAB_R2015b.app/bin/matlab" -nodesktop -r "cd('/Users/ceciverbaarschot/buffer_bci/matlab/movementBCIgame/FlipThatBucket'); addpath('code'); erpGameViewer" &
    pause(3); % wait for additional Matlab to start up
                
    % create game window
    game_figure = figure('color','black','Position',window_size,'WindowKeyPressFcn',@fh_kpfcn,'units','normalized','Name','Slime Game -press ESCAPE to quit-');
    pos = get(gcf, 'Position'); %// gives x left, y bottom, width, height
    axis off;
    
    % block1 = practice, block2 = training, [block3 = validation], block4 = testing
    sendEvent('experiment','start');
    for block=1:max_blocks
        % set max score and slime increments
        if block == 2 || block == 3
            max_score = 1/(max_trials(2)+max_trials(3));
            nr_increments = randi([min_trial_length,max_trial_length],max_trials(2)+max_trials(3),1);
        else
            max_score = 1/max_trials(block);
            nr_increments = randi([min_trial_length,max_trial_length],max_trials(block),1);
        end 
        
        % block1 = practice
        if block==2 % training
            % start additional matlab session to gather training data
            !"/Applications/MATLAB_R2015b.app/bin/matlab" -nodesktop -r "cd('/Users/ceciverbaarschot/buffer_bci/matlab/movementBCIgame/FlipThatBucket');  addpath('code'); load('player'); get_train_data(player)" &
            pause(20); % wait for additional Matlab to start up
        elseif block==3 % validation
            !"/Applications/MATLAB_R2015b.app/bin/matlab" -nodesktop -r "cd('/Users/ceciverbaarschot/buffer_bci/matlab/movementBCIgame/FlipThatBucket');  addpath('code'); load('player'); load('hdr'); cont_apply_classifiers(player,hdr,'validate')"&
            pause(20);
        elseif block==4 % testing
            !"/Applications/MATLAB_R2015b.app/bin/matlab" -nodesktop -r "cd('/Users/ceciverbaarschot/buffer_bci/matlab/movementBCIgame/FlipThatBucket');  addpath('code'); load('player'); load('hdr'); cont_apply_classifiers(player,hdr,'test')"& 
            pause(20);
        end
        
        figure(game_figure);
        
        if block ~= 3
            % wait for player to start
            checkKeys = true;
            clf;
            axis off;
            text(0.5,0.5,sprintf('Press ENTER to start...'),'Color','white','FontSize',20,'HorizontalAlignment','center');
            while checkKeys
                pause(update_rate);
            end   
            % initial score
            current_score_scientist = 0.001;
            current_score_robot = 0.001;
        end
        sendEvent('block',block);
        
        trialstarts = [];
        playermoves = [];
        fake_playermoves = [];
        % % start trial
        for trial=1:max_trials(block)   
            sendEvent('trial',trial);
     
            % set robot prediction
            if numel(nonzeros(scientist_data.actionOnset))>min_actions_for_pred
                muAct = median([nonzeros(scientist_data.actionOnset); fake_playermoves]);
                sigmaAct = std([nonzeros(scientist_data.actionOnset); fake_playermoves]);
                x = get_probe_distr(muAct,sigmaAct);
                robot_onset = normrnd(x(1),x(2),1,1); % based on behaviour
            else
                robot_onset = normrnd(muAct,sigmaAct,1,1); % random
            end

            % start scene (baseline)
            handles.background = image(images.background_level1);
            hold on;
            axis off;
            handles.bucket = image(images.bucket_no_slime,'AlphaData',images.alpha_bucket_no_slime);
            handles.robot = image(images.robot_neutral,'AlphaData',images.alpha_robot_neutral);
            handles.scientist = image(images.scientist_neutral,'AlphaData',images.alpha_scientist_neutral);
            handles.scorebar_scientist = rectangle('Position',[90 50+max_scorebar-(current_score_scientist*max_scorebar) score_width current_score_scientist*max_scorebar],'FaceColor',color_slime_face,'EdgeColor',color_slime_edge);
            handles.scorebar_scientist_edge = rectangle('Position',[90 50 score_width max_scorebar],'FaceColor','none','EdgeColor',color_slime_face);
            handles.scorebar_robot = rectangle('Position',[720 50+max_scorebar-(current_score_robot*max_scorebar) score_width current_score_robot*max_scorebar],'FaceColor',color_slime_face,'EdgeColor',color_slime_edge);
            handles.scorebar_robot_edge = rectangle('Position',[720 50 score_width max_scorebar],'FaceColor','none','EdgeColor',color_slime_face);          
            sendEvent('stimulus.baseline','start');
            pause(baseline_duration-train_size);
            sendEvent('train',-1); %nonmove data for training: last train_size ms before baseline end
            pause(train_size);
            sendEvent('stimulus.baseline','end');

            % wait for button press
            actionType = 0;
            actionTimeScientist = 0;
            actionTimeRobot = 0;
            checkKeys = true;
            increments = 0;
            state = [];
            samp0 = buffer('poll'); % set initial sample for getting relative premove/nonmove training data
            samp0 = samp0.nSamples;
            trialstarts = [trialstarts samp0];
            sumpredictions = 0;
            tic
            while checkKeys
                % check for robot prediction
                if block <= 3 % behavioural
                    if toc >= robot_onset
                        actionTimeRobot = toc
                        move = sendEvent('robot.act',round(actionTimeRobot*1000)/1000);
                        sendEvent('move','robot');
                        robotActSamp = move.sample;
                        actionType = 2;
                        checkKeys = false;
                    end
                else % BCI
                    [events,state]=buffer_newevents(buffhost,buffport,state,'classifier_prediction',[],0); % wait for next prediction event
                    if ~isempty(events)
                        sumpredictions = sumpredictions+sum([events.value])
                        if sumpredictions > threshold
                            actionTimeRobot = toc
                            move = sendEvent('robot.act',round(actionTimeRobot*1000)/1000);
                            sendEvent('move','robot');
                            robotActSamp = move.sample;
                            actionType = 2;
                            checkKeys = false;
                        end
                    end
                end

                rand_slime = randi(size(slime_bucket,1));
                rand_blink_scientist = randi(chance_blink);
                rand_blink_robot = randi(chance_blink);
                handles.slime = image(slime_bucket{rand_slime,1},'AlphaData',slime_bucket{rand_slime,2}); 

                % blink scientist
                if rand_blink_scientist == 1
                    handles.blink1 = image(images.scientist_blink,'AlphaData',images.alpha_scientist_blink);
                    sendEvent('stimulus.scientist_blink','start');
                end

                % blink scientist
                if rand_blink_robot == 1
                    handles.blink2 = image(images.robot_blink,'AlphaData',images.alpha_robot_blink);
                    sendEvent('stimulus.robot_blink','start');
                end

                pause(update_rate);
                increments = increments+1;
                if increments>nr_increments(trial) % max score reached
                    increments = nr_increments(trial);
                end

                % trim played animations
                delete(handles.slime);
                if rand_blink_scientist == 1
                    delete(handles.blink1);
                    sendEvent('stimulus.scientist_blink','end');
                end
                if rand_blink_robot == 1
                    delete(handles.blink2);
                    sendEvent('stimulus.robot_blink','end');
                end
            end
            % calculate collected amount of slime
            perc_score = increments/nr_increments(trial);
            score = perc_score*max_score;
            if perc_score<(1/3)
                type_score = 'little';
                sendEvent('stimulus.collected_slime','little');
            elseif perc_score>=(1/3) && perc_score <(2/3)
                type_score = 'medium';
                sendEvent('stimulus.collected_slime','medium');
            else
                type_score = 'lots';
                sendEvent('stimulus.collected_slime','lots');
            end

            if actionType <0 % check if player quit the game
                break;
            elseif actionType == 1 % scientist wins
                handles = scientist_wins(images,handles,update_rate,type_score);
                playermoves = [playermoves playerActSamp];
                if block==2 % label premove data for training the classifier            
                    start_samp = [((playerActSamp-(train_size*hdr.fSample))-samp0):-train_size*hdr.fSample:((playerActSamp-samp0)-(dur_premove*hdr.fSample))];
                    start_samp = min(start_samp(find(start_samp>0)));
                    event_offsets = [((playerActSamp-(train_size*hdr.fSample))-samp0):-train_size*hdr.fSample:start_samp];
                    for eo=1:numel(event_offsets)
                        sendEvent('train',1,round(event_offsets(eo)+samp0)); %premove
                    end
                end
                % update score
                current_score_scientist = current_score_scientist + score;
                sendEvent('player.winsThisTrial',round(current_score_scientist*10000)/10000);
                pause(post_trial_duration);
                hold off;
            elseif actionType == 2 % robot wins
                handles = robot_wins(images,handles,update_rate,type_score);
                post_prediction_question(update_rate);
                playermoves = [playermoves 0];
                if block==2 % label nonmove data for training classifier           
                    event_offsets = [min_startup*hdr.fSample:train_size*hdr.fSample:((robotActSamp-((dur_premove+1+train_size)*hdr.fSample))-samp0)];
                    for eo=1:numel(event_offsets)
                        sendEvent('train',-1,round(event_offsets(eo)+samp0)); %nonmove
                    end
                end
                % update score
                current_score_robot = current_score_robot + score;
                sendEvent('robot.winsThisTrial',round(current_score_robot*10000)/10000);
                pause(post_trial_duration);
                hold off;
            end
            % save trial data to variable
            robot_data.actionOnset(trial,block) = actionTimeRobot;
            robot_data.predOnset(trial,block) = robot_onset;
            robot_data.won(trial,block) = actionType==2;
            robot_data.score(trial,block) = current_score_robot;
            scientist_data.actionOnset(trial,block) = actionTimeScientist;
            scientist_data.won(trial,block) = actionType==1;
            scientist_data.score(trial,block) = current_score_scientist;
            if actionType==2
                scientist_data.wantedToact(trial,block) = answer;
                if numel(nonzeros(scientist_data.actionOnset))>min_actions_for_pred % if player moved a couple of times already
                    if answer == 0 % player did not intend to move when robot moved
                        fake_playermoves = [fake_playermoves; actionTimeRobot+2]; % slow down robot predictions (add fake player move of robot move + 2s)
                    end
                end
            end
            
            % clear figure
            clf;
            axis off;
        end
        % end of block 
         if block == 2 % training classifier after first block
            sendEvent('training','end'); % stop gathering training data
            pause(3);
         elseif block > 2
            sendEvent('testing','end'); % stop gathering validation data
            pause(3);
         end
        
        if actionType <0 % check if player quit the game
            break;
        end
        
        if block > 2
            if current_score_scientist > current_score_robot
                text(0.5,0.5,sprintf('Congratulations! You beat the robot :)'),'Color','white','FontSize',20,'HorizontalAlignment','center');
                sendEvent('player','wins');
                scientist_vs_robot = scientist_vs_robot + [1 0];
            else
                text(0.5,0.5,sprintf('Ai! The robot wins :('),'Color','white','FontSize',20,'HorizontalAlignment','center');
                sendEvent('robot','wins');
                scientist_vs_robot = scientist_vs_robot + [0 1];
            end
            pause(post_trial_duration);
            
            % questionnaire
            scientist_data.questionnaire(block,:) = questionnaire(update_rate,block);
            
            % update highscores
            if current_score_scientist > scientist_highscore
                scientist_highscore = current_score_scientist;
            end
            if current_score_scientist > overal_scientist_highscore
                overal_scientist_highscore = current_score_scientist;
            end
            if current_score_robot > overal_robot_highscore
                overal_robot_highscore = current_score_robot;
            end
            
            % show highscores
            clf;
            handles.background = image(images.background_level1);
            hold on;
            axis off;
            handles.highscore_you = rectangle('Position',[90 50+max_scorebar-(scientist_highscore*max_scorebar) score_width scientist_highscore*max_scorebar],'FaceColor',color_slime_face,'EdgeColor',color_slime_edge);
            handles.highscore_you_edge = rectangle('Position',[90 50 score_width max_scorebar],'FaceColor','none','EdgeColor',color_slime_face);
            handles.highscore_scientist = rectangle('Position',[400 50+max_scorebar-(overal_scientist_highscore*max_scorebar) score_width overal_scientist_highscore*max_scorebar],'FaceColor',color_slime_face,'EdgeColor',color_slime_edge);
            handles.highscore_scientist_edge = rectangle('Position',[400 50 score_width max_scorebar],'FaceColor','none','EdgeColor',color_slime_face);
            handles.highscore_robot = rectangle('Position',[720 50+max_scorebar-(overal_robot_highscore*max_scorebar) score_width overal_robot_highscore*max_scorebar],'FaceColor',color_slime_face,'EdgeColor',color_slime_edge);
            handles.highscore_robot_edge = rectangle('Position',[720 50 score_width max_scorebar],'FaceColor','none','EdgeColor',color_slime_face);
            text(420,30,sprintf(['Overal scientist vs robot [', num2str(scientist_vs_robot(1)),' ', num2str(scientist_vs_robot(2)), ']']),'Color','black','FontSize',20,'HorizontalAlignment','center');
            text(110,520,sprintf(['you: ', num2str(round(scientist_highscore*100))]),'Color','black','FontSize',20,'HorizontalAlignment','center');
            text(420,520,sprintf(['best scientist: ', num2str(round(overal_scientist_highscore*100))]),'Color','black','FontSize',20,'HorizontalAlignment','center');
            text(740,520,sprintf(['best robot: ', num2str(round(overal_robot_highscore*100))]),'Color','black','FontSize',20,'HorizontalAlignment','center');
            text(420,560,sprintf('press ENTER to continue...'),'Color','black','FontSize',20,'HorizontalAlignment','center');
            checkKeys = true;
            while checkKeys
                pause(update_rate);
            end 
        end
        % clear figure
        clf;
        axis off;
            
        % save data
        if block==2
            save(fullfile('data',[datafile,'_train']),'scientist_data','robot_data','playermoves','trialstarts');
        elseif block==3
            save(fullfile('data',[datafile,'_validate']),'scientist_data','robot_data','playermoves','trialstarts');
        elseif block==4
            save(fullfile('data',[datafile,'_test']),'scientist_data','robot_data','playermoves','trialstarts')
        end
        
        if block == 2 % training classifier after first block
            train_classifiers(player);
        elseif block == 3 % set classifier threshold
            threshold = get_optimal_threshold(player,hdr.fSample,datafile);
        end
        
       save('highscores','overal_scientist_highscore','overal_robot_highscore','scientist_vs_robot');
    end
    close all;
    sendEvent('experiment','end');
    
    % show classification accuracy
    load(fullfile('data',[player,'_comb_classifier']));
    msgbox(['classifier accuracy [train, test]: ', '[',num2str(round(res_ERP_ERD.opt.trn*100)),'%, ',num2str(round(res_ERP_ERD.opt.tst*100)),'%]']);
end

function post_prediction_question(update_rate)
    global checkKeys;
    global answer;
    
    % wait for player to start
    checkKeys = true;
    clf;
    axis off;
    text(0.5,0.5,sprintf('Did you want to act?\n[Y]es     [N]o'),'Color','white','FontSize',20,'HorizontalAlignment','center');
    sendEvent('player.wantedToact','start');
    while checkKeys
        pause(update_rate);
    end     
    clf;
    axis off;
    if answer==1
        text(0.5,0.5,sprintf('Yes'),'Color','white','FontSize',20,'HorizontalAlignment','center');
        sendEvent('player.wantedToact','yes');
    else
        text(0.5,0.5,sprintf('No'),'Color','white','FontSize',20,'HorizontalAlignment','center');
        sendEvent('player.wantedToact','no');
    end
    pause(update_rate);
end

function completed_answers = questionnaire(update_rate,block)
    global checkKeys;
    global answer;
    
    % question 1
    checkKeys = true;
    clf;
    axis off;
    text(0.5,0.5,sprintf('What did you think about the game?\n\n[boring] 1     2     3     4     5 [fun]'),'Color','white','FontSize',20,'HorizontalAlignment','center');
    sendEvent('stimulus.question1','start');
    while checkKeys
        pause(update_rate);
    end  
    clf;
    axis off;
    text(0.5,0.5,sprintf(num2str(answer)),'Color','white','FontSize',20,'HorizontalAlignment','center');
    sendEvent('stimulus.question1',answer);
    completed_answers(1) = answer;
    pause(update_rate);
    
    % question 2
    checkKeys = true;
    clf;
    axis off;
    text(0.5,0.5,sprintf('Did you feel free to do what you want?\n\n[Y]es     [N]o'),'Color','white','FontSize',20,'HorizontalAlignment','center');
    sendEvent('stimulus.question2','start');
    while checkKeys
        pause(update_rate);
    end  
    clf;
    axis off;
    if answer==1
        text(0.5,0.5,sprintf('Yes'),'Color','white','FontSize',20,'HorizontalAlignment','center');
        sendEvent('stimulus.question2','yes');
    else
        text(0.5,0.5,sprintf('No'),'Color','white','FontSize',20,'HorizontalAlignment','center');
        sendEvent('stimulus.question2','no');
    end
    completed_answers(2) = answer;
    pause(update_rate);
    
    % question 3
    checkKeys = true;
    clf;
    axis off;
    text(0.5,0.5,sprintf('How difficult was it to win?\n\n[easy] 1     2     3     4     5 [difficult]'),'Color','white','FontSize',20,'HorizontalAlignment','center');
    sendEvent('stimulus.question3','start');
    while checkKeys
        pause(update_rate);
    end  
    clf;
    axis off;
    text(0.5,0.5,sprintf(num2str(answer)),'Color','white','FontSize',20,'HorizontalAlignment','center');
    sendEvent('stimulus.question3',answer);
    completed_answers(3) = answer;
    pause(update_rate);
    
    % question 4
    checkKeys = true;
    clf;
    axis off;
    text(0.5,0.5,sprintf('How accurate was the robot in predicting your actions?\n\n[inaccurate] 1     2     3     4     5 [accurate]'),'Color','white','FontSize',20,'HorizontalAlignment','center');
    sendEvent('stimulus.question4','start');
    while checkKeys
        pause(update_rate);
    end  
    clf;
    axis off;
    text(0.5,0.5,sprintf(num2str(answer)),'Color','white','FontSize',20,'HorizontalAlignment','center');
    sendEvent('stimulus.question4',answer);
    completed_answers(4) = answer;
    pause(update_rate);
    
    % question 5 (only at the end)
    if (block > 3)
        checkKeys = true;
        clf;
        axis off;
        text(0.5,0.5,sprintf('How good were the robot predictions in this block compared to the previous one?\n\n[worse] 1     2     3     4     5 [better]'),'Color','white','FontSize',20,'HorizontalAlignment','center');
        sendEvent('stimulus.question5','start');
        while checkKeys
            pause(update_rate);
        end  
        clf;
        axis off;
        text(0.5,0.5,sprintf(num2str(answer)),'Color','white','FontSize',20,'HorizontalAlignment','center');
        sendEvent('stimulus.question5',answer);
        completed_answers(4) = answer;
        pause(update_rate);
    end
end

function handles = scientist_wins(images,handles,update_rate,type_score)
    switch type_score
        case 'little'
            robot_slime_2 = images.robot_slime_little_2;
            alpha_robot_slime_2 = images.alpha_robot_slime_little_2;
            robot_slime_3 = images.robot_slime_little_3;
            alpha_robot_slime_3 = images.alpha_robot_slime_little_3;
            robot_slime_4 = images.robot_slime_little_4;
            alpha_robot_slime_4 = images.alpha_robot_slime_little_4;
        case 'medium'
            robot_slime_2 = images.robot_slime_medium_2;
            alpha_robot_slime_2 = images.alpha_robot_slime_medium_2;
            robot_slime_3 = images.robot_slime_medium_3;
            alpha_robot_slime_3 = images.alpha_robot_slime_medium_3;
            robot_slime_4 = images.robot_slime_medium_4;
            alpha_robot_slime_4 = images.alpha_robot_slime_medium_4;
        otherwise
            robot_slime_2 = images.robot_slime_lots_2;
            alpha_robot_slime_2 = images.alpha_robot_slime_lots_2;
            robot_slime_3 = images.robot_slime_lots_3;
            alpha_robot_slime_3 = images.alpha_robot_slime_lots_3;
            robot_slime_4 = images.robot_slime_lots_4;
            alpha_robot_slime_4 = images.alpha_robot_slime_lots_4;
    end
    delete(handles.scientist);
    handles.scientist = image(images.scientist_press_1,'AlphaData',images.alpha_scientist_press_1);
    pause(update_rate);
    delete([handles.scientist, handles.bucket, handles.robot]);
    handles.scientist = image(images.scientist_press_2,'AlphaData',images.alpha_scientist_press_2);
    handles.robot = image(images.robot_slime_1,'AlphaData',images.alpha_robot_slime_1);
    pause(update_rate);
    delete([handles.scientist,handles.robot]);
    handles.scientist = image(images.scientist_press_1,'AlphaData',images.alpha_scientist_press_1);
    handles.robot = image(robot_slime_2,'AlphaData',alpha_robot_slime_2);
    pause(update_rate);
    delete(handles.robot);
    handles.robot = image(robot_slime_3,'AlphaData',alpha_robot_slime_3);
    pause(update_rate);
    delete(handles.robot);
    handles.robot = image(robot_slime_4,'AlphaData',alpha_robot_slime_4);
    pause(update_rate);
end

function handles = robot_wins(images,handles,update_rate,type_score)
    switch type_score
        case 'little'
            scientist_slime_2 = images.scientist_slime_little_2;
            alpha_scientist_slime_2 = images.alpha_scientist_slime_little_2;
            scientist_slime_3 = images.scientist_slime_little_3;
            alpha_scientist_slime_3 = images.alpha_scientist_slime_little_3;
            scientist_slime_4 = images.scientist_slime_little_4;
            alpha_scientist_slime_4 = images.alpha_scientist_slime_little_4;
        case 'medium'
            scientist_slime_2 = images.scientist_slime_medium_2;
            alpha_scientist_slime_2 = images.alpha_scientist_slime_medium_2;
            scientist_slime_3 = images.scientist_slime_medium_3;
            alpha_scientist_slime_3 = images.alpha_scientist_slime_medium_3;
            scientist_slime_4 = images.scientist_slime_medium_4;
            alpha_scientist_slime_4 = images.alpha_scientist_slime_medium_4;
        otherwise
            scientist_slime_2 = images.scientist_slime_lots_2;
            alpha_scientist_slime_2 = images.alpha_scientist_slime_lots_2;
            scientist_slime_3 = images.scientist_slime_lots_3;
            alpha_scientist_slime_3 = images.alpha_scientist_slime_lots_3;
            scientist_slime_4 = images.scientist_slime_lots_4;
            alpha_scientist_slime_4 = images.alpha_scientist_slime_lots_4;
    end
    delete(handles.robot);
    handles.robot = image(images.robot_press_1,'AlphaData',images.alpha_robot_press_1);
    pause(update_rate);
    delete([handles.scientist, handles.bucket, handles.robot]);
    handles.robot = image(images.robot_press_2,'AlphaData',images.alpha_robot_press_2);
    handles.scientist = image(images.scientist_slime_1,'AlphaData',images.alpha_scientist_slime_1);
    pause(update_rate);
    delete([handles.scientist,handles.robot]);
    handles.robot = image(images.robot_press_3,'AlphaData',images.alpha_robot_press_3);
    handles.scientist = image(scientist_slime_2,'AlphaData',alpha_scientist_slime_2);
    pause(update_rate);
    delete(handles.scientist);
    handles.scientist = image(scientist_slime_3,'AlphaData',alpha_scientist_slime_3);
    pause(update_rate);
    delete(handles.scientist);
    handles.scientist = image(scientist_slime_4,'AlphaData',alpha_scientist_slime_4);
    pause(update_rate);
end

function fh_kpfcn(H,E)  
    global actionType;
    global answer;
    global actionTimeScientist;
    global checkKeys;
    global playerActSamp;
    E.Key
    sendEvent('keys',E.Key);
    if checkKeys
        switch E.Key
            case 'space'
                checkKeys = false;
                actionTimeScientist = toc
                actionType = 1;
                move = sendEvent('player.act',round(actionTimeScientist*1000)/1000);
                sendEvent('move','scientist');
                playerActSamp = move.sample;
            case 'escape'
                checkKeys = false;
                actionType = -1;
            case 'return'
                checkKeys = false;
            case 'y'
                checkKeys = false;
                answer = 1;
            case 'n'
                checkKeys = false;
                answer = 0;
            case '1'
                checkKeys = false;
                answer = 1;
            case '2'
                checkKeys = false;
                answer = 2;
            case '3'
                checkKeys = false;
                answer = 3;
            case '4'
                checkKeys = false;
                answer = 4;
            case '5'
                checkKeys = false;
                answer = 5;
            otherwise  
                E.Key
        end
    end
end