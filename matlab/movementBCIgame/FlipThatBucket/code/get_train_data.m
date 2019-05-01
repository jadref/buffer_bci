% Listens to events from movementBCI_training and slices data for training
% a classifier.
% Needs a running buffer and EEG or EMG source
function get_train_data(subject)
    run(fullfile('~','buffer_bci','matlab','utilities','initPaths.m'));

    % connect to the buffer
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

    dname='raw_subject_data';
    
    % Grab 500 ms before a player.act or robot.act event
    [data,devents,state]=buffer_waitData(buffhost,buffport,[],'startSet',{{'train'} {1 -1}},'exitSet',{{'training'} {'end'}},'trlen_ms',500);
    mi=matchEvents(devents,'training'); devents(mi)=[]; data(mi)=[]; % remove the exit event
    fprintf('Saving %d epochs to : %s\n',numel(devents),dname);
    save(fullfile('data',[subject,'_raw_data']), 'data','devents','hdr');
end
