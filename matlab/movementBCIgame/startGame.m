% Starts up an option menu for the movementBCI game.
function startGame()
    clear all
    close all
    
    cd(fullfile('~','buffer_bci','matlab','movementBCIgame'));
    
    global choice playerNr

    % Add all necessary paths
    try;
        run(fullfile('..','utilities','initPaths.m'))
        addpath('gameCode');
    catch
        msgbox({'Please change your directory to movementBCIgame'},'Change directory');
    end
    
    if ~exist ('data','dir')
        mkdir('data');
    end
    if ~exist ('classifier','dir')
        mkdir('classifier');
    end
    if ~exist ('logfiles','dir')
        mkdir('logfiles');
    end
    
    prompt = {'Player number'};
    dlg_title = 'Player';
    num_lines = 1;
    defaultans = {'1'};
    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
    playerNr = str2double(answer);
    save(fullfile('logfiles','playerNr'), 'playerNr');
    
    % set the desired input values
    game_options = {'Practice game', 'Play behavioural game (collect training data)', 'Play muscle game', 'Play brain game I (RP)', 'Play brain game II (ERD)', 'Play full game (muscle, ERD, RP)'};
    
    choice = 1;
    
    % Create figure
    % Position = [pixels from left, pixels from bottom, pixels across, pixels high]              
    handles.menuFigure = figure('Name','Game menu','units','pixels','position',[400,400,400,400],...
                  'toolbar','none','menu','none');

    handles.radio(1) = uicontrol('Style', 'radiobutton','fontsize',14,...
                           'Callback', @myRadio, ...
                           'Units',    'pixels', ...
                           'Position', [20, 300, 400, 22], ...
                           'String',   game_options{1}, ...
                           'Value',    1);
    handles.radio(2) = uicontrol('Style', 'radiobutton','fontsize',14, ...
                           'Callback', @myRadio, ...
                           'Units',    'pixels', ...
                           'Position', [20, 270, 400, 22], ...
                           'String',   game_options{2}, ...
                           'Value',    0);
    handles.radio(3) = uicontrol('Style', 'radiobutton','fontsize',14, ...
                           'Callback', @myRadio, ...
                           'Units',    'pixels', ...
                           'Position', [20, 240, 400, 22], ...
                           'String',   game_options{3}, ...
                           'Value',    0);
    handles.radio(4) = uicontrol('Style', 'radiobutton','fontsize',14, ...
                           'Callback', @myRadio, ...
                           'Units',    'pixels', ...
                           'Position', [20, 210, 400, 22], ...
                           'String',   game_options{4}, ...
                           'Value',    0);
    handles.radio(5) = uicontrol('Style', 'radiobutton','fontsize',14, ...
                           'Callback', @myRadio, ...
                           'Units',    'pixels', ...
                           'Position', [20, 180, 400, 22], ...
                           'String',   game_options{5}, ...
                           'Value',    0);
    handles.radio(6) = uicontrol('Style', 'radiobutton','fontsize',14, ...
                           'Callback', @myRadio, ...
                           'Units',    'pixels', ...
                           'Position', [20, 150, 400, 22], ...
                           'String',   game_options{6}, ...
                           'Value',    0);
                       
    % Add a text uicontrol to label the radiobuttons
    txt = uicontrol('Style','text','fontsize',14,'fontweight','bold',...
        'Position',[10 350 200 20],...
        'String','What do you want to do?');
    
    % Create OK pushbutton   
    handles.stimButton = uicontrol('style','pushbutton','units','pixels','fontsize',14,...
                'position',[120,20,170,50],'string','Start',...
                'callback',@hitStart);
    
    guidata(handles.menuFigure, handles); 
end

function myRadio(source,callbackdata)
    global choice
    
    handles = guidata(source);
    otherRadio = handles.radio(handles.radio ~= source);
    set(otherRadio, 'Value', 0);
    
    if get(handles.radio(1), 'value') == 1
        choice = 1;
    elseif get(handles.radio(2), 'value') == 1
        choice = 2;
    elseif get(handles.radio(3), 'value') == 1
        choice = 3;
    elseif get(handles.radio(4), 'value') == 1
        choice = 4;
    elseif get(handles.radio(5), 'value') == 1
        choice = 5;
    else
        choice = 6;
    end
end

function hitStart(source,callbackdata)
    global choice playerNr
    
    handles = guidata(source);

    set(handles.stimButton, 'Enable', 'off');
    pause(0.5);
    set(handles.stimButton, 'Enable', 'on');
   
    switch(choice)
        case 1 % practice
            handles.gameFigure = figure();
            movementBCI_game(playerNr);
        case 2 % collect EEG/EMG training data
            !"/Applications/MATLAB_R2015b.app/bin/matlab" -r "cd(fullfile('~','buffer_bci','matlab','movementBCIgame','gameCode'));  load(fullfile('..','logfiles','playerNr')); get_train_data(playerNr)" &
            handles.gameFigure = figure();
            movementBCI_training(playerNr);
            train_classifiers(playerNr);
        case 3 % online game with EMG feedback
            !"/Applications/MATLAB_R2015b.app/bin/matlab" -r "cd(fullfile('~','buffer_bci','matlab','movementBCIgame','gameCode'));  load(fullfile('..','logfiles','playerNr')); version = 4; cont_apply_classifiers(playerNr,version)" &
            handles.gameFigure = figure();
            movementBCI_testing(playerNr);
        case 4 % online game with RP feedback
            !"/Applications/MATLAB_R2015b.app/bin/matlab" -r "cd(fullfile('~','buffer_bci','matlab','movementBCIgame','gameCode'));  load(fullfile('..','logfiles','playerNr')); version = 3; cont_apply_classifiers(playerNr,version)" &
            handles.gameFigure = figure();
            movementBCI_testing(playerNr);
        case 5 % online game with ERD feedback
            !"/Applications/MATLAB_R2015b.app/bin/matlab" -r "cd(fullfile('~','buffer_bci','matlab','movementBCIgame','gameCode'));  load(fullfile('..','logfiles','playerNr')); version = 2; cont_apply_classifiers(playerNr,version)" &
            handles.gameFigure = figure();
            movementBCI_testing(playerNr);
        otherwise % online game with EMG, RP and ERD feedback
            !"/Applications/MATLAB_R2015b.app/bin/matlab" -r "cd(fullfile('~','buffer_bci','matlab','movementBCIgame','gameCode'))';  load(fullfile('..','logfiles','playerNr')); version = 1; cont_apply_classifiers(playerNr,version)" &
            handles.gameFigure = figure();
            movementBCI_testing(playerNr);
    end
end