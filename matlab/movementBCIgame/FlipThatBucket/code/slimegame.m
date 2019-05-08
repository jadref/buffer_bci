function [robot_data, scientist_data] = slimegame()
    % clear workspace
    clear all
    close all

    % define some game parameters
    global actionType;
    global actionTimeScientist;
    global checkKeys;
    global answer;
    update_rate = 0.1; % how often update screen
    baseline_duration = 1; % in secs
    post_trial_duration = 1; % in secs
    window_size = [90 100 1090 700];
    color_slime_face = [34/255 181/255 115/255];
    min_actions_for_pred = 5;
    color_slime_edge = 'green';
    chance_blink = 20;
    score_width = 40;
    max_scorebar = 450;
    max_trials = 20;
    max_blocks = 1;
    min_trial_length = 4/update_rate; 
    max_trial_length = 7/update_rate; 
    max_score = 1/max_trials;
    nr_increments = randi([min_trial_length,max_trial_length],max_trials,1);
    muAct = 8;
    sigmaAct = 2;
    checkKeys = true;
    answer = 0;
    handles = [];
    images = [];
    
    % memory for data
    robot_data = []; 
    robot_data.actionOnset = zeros(max_trials,max_blocks);
    robot_data.predOnset = zeros(max_trials,max_blocks);
    robot_data.won = zeros(max_trials,max_blocks);
    robot_data.score = zeros(max_trials,max_blocks);
    scientist_data = [];
    scientist_data.actionOnset = zeros(max_trials,max_blocks);
    scientist_data.won = zeros(max_trials,max_blocks);
    scientist_data.score = zeros(max_trials,max_blocks);
    scientist_data.wantedToact = ones(max_trials,max_blocks);
    scientist_data.questionnaire = zeros(max_blocks,4); % 4 questions per block

    % read in all stimuli files
    [images.background_level1,map,images.alpha_background_level1]               = imread('stimuli/background_level1.png');
    [images.bucket_no_slime,map,images.alpha_bucket_no_slime]                   = imread('stimuli/bucket_no_slime.png');
    [images.bucket_slime_1,map,images.alpha_bucket_slime_1]                     = imread('stimuli/bucket_slime_1.png');
    [images.bucket_slime_2,map,images.alpha_bucket_slime_2]                     = imread('stimuli/bucket_slime_2.png');
    [images.bucket_slime_3,map,images.alpha_bucket_slime_3]                     = imread('stimuli/bucket_slime_3.png');
    [images.bucket_slime_4,map,images.alpha_bucket_slime_4]                     = imread('stimuli/bucket_slime_4.png');
    [images.bucket_slime_5,map,images.alpha_bucket_slime_5]                     = imread('stimuli/bucket_slime_5.png');
    [images.bucket_slime_6,map,images.alpha_bucket_slime_6]                     = imread('stimuli/bucket_slime_6.png');
    [images.scientist_neutral,map,images.alpha_scientist_neutral]               = imread('stimuli/scientist_neutral.png');
    [images.scientist_blink,map,images.alpha_scientist_blink]                   = imread('stimuli/scientist_blink.png');
    [images.scientist_press_1,map,images.alpha_scientist_press_1]               = imread('stimuli/scientist_press_1.png');
    [images.scientist_press_2,map,images.alpha_scientist_press_2]               = imread('stimuli/scientist_press_2.png');
    [images.scientist_slime_1,map,images.alpha_scientist_slime_1]               = imread('stimuli/scientist_slime_1.png');
    [images.scientist_slime_little_2,map,images.alpha_scientist_slime_little_2] = imread('stimuli/scientist_slime_little_2.png');
    [images.scientist_slime_little_3,map,images.alpha_scientist_slime_little_3] = imread('stimuli/scientist_slime_little_3.png');
    [images.scientist_slime_little_4,map,images.alpha_scientist_slime_little_4] = imread('stimuli/scientist_slime_little_4.png');   
    [images.scientist_slime_medium_2,map,images.alpha_scientist_slime_medium_2] = imread('stimuli/scientist_slime_medium_2.png');
    [images.scientist_slime_medium_3,map,images.alpha_scientist_slime_medium_3] = imread('stimuli/scientist_slime_medium_3.png');
    [images.scientist_slime_medium_4,map,images.alpha_scientist_slime_medium_4] = imread('stimuli/scientist_slime_medium_4.png');
    [images.scientist_slime_lots_2,map,images.alpha_scientist_slime_lots_2]     = imread('stimuli/scientist_slime_lots_2.png');
    [images.scientist_slime_lots_3,map,images.alpha_scientist_slime_lots_3]     = imread('stimuli/scientist_slime_lots_3.png');
    [images.scientist_slime_lots_4,map,images.alpha_scientist_slime_lots_4]     = imread('stimuli/scientist_slime_lots_4.png');
    [images.robot_neutral,map,images.alpha_robot_neutral]                       = imread('stimuli/robot_neutral.png');
    [images.robot_blink,map,images.alpha_robot_blink]                           = imread('stimuli/robot_blink.png');
    [images.robot_press_1,map,images.alpha_robot_press_1]                       = imread('stimuli/robot_press_1.png');
    [images.robot_press_2,map,images.alpha_robot_press_2]                       = imread('stimuli/robot_press_2.png');
    [images.robot_press_3,map,images.alpha_robot_press_3]                       = imread('stimuli/robot_press_3.png');
    [images.robot_slime_1,map,images.alpha_robot_slime_1]                       = imread('stimuli/robot_slime_1.png');
    [images.robot_slime_little_2,map,images.alpha_robot_slime_little_2]         = imread('stimuli/robot_slime_little_2.png');
    [images.robot_slime_little_3,map,images.alpha_robot_slime_little_3]         = imread('stimuli/robot_slime_little_3.png');
    [images.robot_slime_little_4,map,images.alpha_robot_slime_little_4]         = imread('stimuli/robot_slime_little_4.png');
    [images.robot_slime_medium_2,map,images.alpha_robot_slime_medium_2]         = imread('stimuli/robot_slime_medium_2.png');
    [images.robot_slime_medium_3,map,images.alpha_robot_slime_medium_3]         = imread('stimuli/robot_slime_medium_3.png');
    [images.robot_slime_medium_4,map,images.alpha_robot_slime_medium_4]         = imread('stimuli/robot_slime_medium_4.png');
    [images.robot_slime_lots_2,map,images.alpha_robot_slime_lots_2]             = imread('stimuli/robot_slime_lots_2.png');
    [images.robot_slime_lots_3,map,images.alpha_robot_slime_lots_3]             = imread('stimuli/robot_slime_lots_3.png');
    [images.robot_slime_lots_4,map,images.alpha_robot_slime_lots_4]             = imread('stimuli/robot_slime_lots_4.png');

    slime_bucket = {images.bucket_slime_1 images.alpha_bucket_slime_1; images.bucket_slime_2 images.alpha_bucket_slime_2; images.bucket_slime_3 images.alpha_bucket_slime_3;...
                    images.bucket_slime_4 images.alpha_bucket_slime_4; images.bucket_slime_5 images.alpha_bucket_slime_5; images.bucket_slime_6 images.alpha_bucket_slime_6};
                
    % get pp code
    prompt = {'Enter participant code:'};
    title = 'Code';
    dims = [1 35];
    definput = {'laptop1_pp1'};
    code = inputdlg(prompt,title,dims,definput);
    datafile = ['data/' code{1} datestr(now,'mm-dd-yyyy_HH-MM') '.mat'];
                
    % create game window
    figure('color','black','Position',window_size,'keypressfcn',@fh_kpfcn,'units','normalized');
    pos = get(gcf, 'Position'); %// gives x left, y bottom, width, height
    axis off;
    
    for block=1:max_blocks
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

        % % start trial
        for trial=1:max_trials    
     
            % set robot prediction
            if numel(nonzeros(scientist_data.actionOnset))>min_actions_for_pred
                muAct = median(nonzeros(scientist_data.actionOnset));
                sigmaAct = std(nonzeros(scientist_data.actionOnset));
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
            pause(baseline_duration);

            % wait for button press
            actionType = 0;
            actionTimeScientist = 0;
            actionTimeRobot = 0;
            checkKeys = true;
            increments = 0;
            tic
            while checkKeys
                % check for robot prediction
                if toc >= robot_onset
                    actionTimeRobot = toc
                    actionType = 2;
                    checkKeys = false;
                end

                rand_slime = randi(size(slime_bucket,1));
                rand_blink_scientist = randi(chance_blink);
                rand_blink_robot = randi(chance_blink);
                handles.slime = image(slime_bucket{rand_slime,1},'AlphaData',slime_bucket{rand_slime,2}); 

                % blink scientist
                if rand_blink_scientist == 1
                    handles.blink1 = image(images.scientist_blink,'AlphaData',images.alpha_scientist_blink); 
                end

                % blink scientist
                if rand_blink_robot == 1
                    handles.blink2 = image(images.robot_blink,'AlphaData',images.alpha_robot_blink);
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
                end
                if rand_blink_robot == 1
                    delete(handles.blink2);
                end
            end
            % calculate collected amount of slime
            perc_score = increments/nr_increments(trial);
            score = perc_score*max_score;
            if perc_score<(1/3)
                type_score = 'little';
            elseif perc_score>=(1/3) && perc_score <(2/3)
                type_score = 'medium';
            else
                type_score = 'lots';
            end

            if actionType <0 % check if player quit the game
                break;
            elseif actionType == 1 % scientist wins
                handles = scientist_wins(images,handles,update_rate,type_score);
                % update score
                current_score_scientist = current_score_scientist + score;
                pause(post_trial_duration);
                hold off;
            elseif actionType == 2 % robot wins
                handles = robot_wins(images,handles,update_rate,type_score);
                post_prediction_question(update_rate);
                % update score
                current_score_robot = current_score_robot + score;
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
            end
            
            % save data
            save(datafile,'scientist_data','robot_data');
        end
        
        if actionType <0 % check if player quit the game
                break;
        else
            % end of block
            clf;
            axis off;
            if current_score_scientist > current_score_robot
                text(0.5,0.5,sprintf('Congratulations! You beat the robot :)'),'Color','white','FontSize',20,'HorizontalAlignment','center');
            else
                text(0.5,0.5,sprintf('Ai! The robot wins :('),'Color','white','FontSize',20,'HorizontalAlignment','center');
            end
            pause(post_trial_duration);

            % questionnaire
            scientist_data.questionnaire(block,:) = questionnaire(update_rate,block);
        end
        
        % save data
        save(datafile,'scientist_data','robot_data')
    end
    close all;
end

function post_prediction_question(update_rate)
    global checkKeys;
    global answer;
    
    % wait for player to start
    checkKeys = true;
    clf;
    axis off;
    text(0.5,0.5,sprintf('Did you want to act?\n[Y]es\t\t[N]o'),'Color','white','FontSize',20,'HorizontalAlignment','center');
    while checkKeys
        pause(update_rate);
    end     
    clf;
    axis off;
    if answer==1
        text(0.5,0.5,sprintf('Yes'),'Color','white','FontSize',20,'HorizontalAlignment','center');
    else
        text(0.5,0.5,sprintf('No'),'Color','white','FontSize',20,'HorizontalAlignment','center');
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
    text(0.5,0.5,sprintf('What did you think about the game?\n\n[boring]\t1\t2\t3\t4\t5\t[fun]'),'Color','white','FontSize',20,'HorizontalAlignment','center');
    while checkKeys
        pause(update_rate);
    end  
    clf;
    axis off;
    text(0.5,0.5,sprintf(num2str(answer)),'Color','white','FontSize',20,'HorizontalAlignment','center');
    completed_answers(1) = answer;
    pause(update_rate);
    
    % question 2
    checkKeys = true;
    clf;
    axis off;
    text(0.5,0.5,sprintf('Did you feel free to do what you want?\n\n[Y]es\t\t[N]o'),'Color','white','FontSize',20,'HorizontalAlignment','center');
    while checkKeys
        pause(update_rate);
    end  
    clf;
    axis off;
    if answer==1
        text(0.5,0.5,sprintf('Yes'),'Color','white','FontSize',20,'HorizontalAlignment','center');
    else
        text(0.5,0.5,sprintf('No'),'Color','white','FontSize',20,'HorizontalAlignment','center');
    end
    completed_answers(2) = answer;
    pause(update_rate);
    
    % question 3
    checkKeys = true;
    clf;
    axis off;
    text(0.5,0.5,sprintf('How difficult was it to win?\n\n[easy]\t1\t2\t3\t4\t5\t[difficult]'),'Color','white','FontSize',20,'HorizontalAlignment','center');
    while checkKeys
        pause(update_rate);
    end  
    clf;
    axis off;
    text(0.5,0.5,sprintf(num2str(answer)),'Color','white','FontSize',20,'HorizontalAlignment','center');
    completed_answers(3) = answer;
    pause(update_rate);
    
    % question 4
    checkKeys = true;
    clf;
    axis off;
    text(0.5,0.5,sprintf('How accurate was the robot in predicting your actions?\n\n[inaccurate]\t1\t2\t3\t4\t5\t[accurate]'),'Color','white','FontSize',20,'HorizontalAlignment','center');
    while checkKeys
        pause(update_rate);
    end  
    clf;
    axis off;
    text(0.5,0.5,sprintf(num2str(answer)),'Color','white','FontSize',20,'HorizontalAlignment','center');
    completed_answers(4) = answer;
    pause(update_rate);
    
    % question 5 (only at the end)
    if (block > 1)
        checkKeys = true;
        clf;
        axis off;
        text(0.5,0.5,sprintf('How good were the robot predictions in this block compared to the previous one?\n\n[worse]\t1\t2\t3\t4\t5\t[better]'),'Color','white','FontSize',20,'HorizontalAlignment','center');
        while checkKeys
            pause(update_rate);
        end  
        clf;
        axis off;
        text(0.5,0.5,sprintf(num2str(answer)),'Color','white','FontSize',20,'HorizontalAlignment','center');
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
    E.Key
    if checkKeys
        switch E.Key
            case 'space'
                checkKeys = false;
                actionTimeScientist = toc
                actionType = 1;
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



