% Listens to events from movementBCI_training and slices data for training
% a classifier.
% Needs a running buffer and EEG or EMG source
function get_train_data(subject)
    run '../../utilities/initPaths.m';

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
    
    % Grab 1500 ms before a premove or prenonmove event
    [data,devents,state]=buffer_waitData(buffhost,buffport,[],'startSet',{{'stimulus.target'} {'premove' 'prenonmove'}},'exitSet',{'end_training'},'trlen_ms',1500);
    mi=matchEvents(devents,'end_training'); devents(mi)=[]; data(mi)=[]; % remove the exit event
    fprintf('Saving %d epochs to : %s\n',numel(devents),dname);
    save(sprintf('../data/raw_subject_data_%1g',subject), 'data','devents','hdr');
end
