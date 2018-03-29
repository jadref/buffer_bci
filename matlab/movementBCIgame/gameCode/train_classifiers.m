% Trains an EMG, RP and ERD classifier.
% Needs training data collected by get_train_data.
function train_classifiers(subject)
    
    % look for training data
    try
        datafile = ['data/raw_subject_data_',num2str(subject)];
        load(datafile);
    catch
        msgbox({'Training data was not found!'},'Error');
    end
    
    % decide what EEG or EMG channels to use
    if hdr.nChans < 10 % debug mode
        badCh=ones(hdr.nChans,1);
        badCh([2:3])=0; 
        badCh=logical(badCh); 
        iseeg=zeros(hdr.nChans,1);
        iseeg([1:2])=1;
        iseeg=logical(iseeg);
        ch_names=hdr.channel_names;
    else % biosemi
        badCh=ones(hdr.nChans,1);
        badCh([71:72])=0; % EMG channels
        badCh=logical(badCh); 
        iseeg=zeros(hdr.nChans,1);
        iseeg([1:64])=1;
        iseeg=logical(iseeg);
        ch_names=hdr.channel_names;
    end
    
    % train the classifiers
    % alpha/beta ERD
    [clsfr_ERD,res_ERD,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'fs', 256, 'badCh', ~iseeg, 'width_ms', 250,...
                        'badchrm', 0, 'badtrrm', 1, 'freqband',[4 8 30 40],'ch_names', ch_names,...
                        'overridechnms',1, 'spatialfilter', 'slap', 'windowType',...
                        'hanning', 'detrend', 0); 
    msgbox({'Press any key when you are ready...'},'Change directory');
    waitforbuttonpress;
    % RP
    [clsfr_RP,res_RP,X,Y]=buffer_train_erp_clsfr(data, devents,hdr, 'fs', 256, 'badCh', ~iseeg, 'badchrm', 0,...
                        'badtrrm', 1, 'freqband',[0 0 10 20], 'ch_names', ch_names, 'spatialfilter', 'slap',...
                        'overridechnms',1, 'detrend', 0); 
    msgbox({'Press any key when you are ready...'},'Change directory');
    waitforbuttonpress;
    % EMG
    [clsfr_EMG,res_EMG,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badCh', badCh, ...
                         'fs', 256, 'width_ms', 250, 'badchrm', 0, 'badtrrm', 1, ...
                         'freqband',[10 20 47 60],'ch_names', ch_names,...
                         'overridechnms',1, 'spatialfilter', [-1 1], 'windowType', 'hanning', 'detrend', 0); 
    msgbox({'Press any key when you are ready...'},'Change directory');
    waitforbuttonpress;
    
    % correct RP classifier
    if isfield(clsfr_RP,'preFiltFn')
        clsfr_RP = rmfield(clsfr_RP,'preFiltFn');
    end
    if isfield(clsfr_RP,'preFiltState') 
        clsfr_RP = rmfield(clsfr_RP,'preFiltState');
    end
    
    % save the classifiers
    classifiers = cat(1,clsfr_ERD,clsfr_RP,clsfr_EMG); % all classifiers combined
    save(sprintf('classifier/ERD_classifier_subject_%1g',subject), 'clsfr_ERD');
    save(sprintf('classifier/RP_classifier_subject_%1g',subject), 'clsfr_RP');
    save(sprintf('classifier/EMG_classifier_subject_%1g',subject), 'clsfr_EMG');
    save(sprintf('classifier/comb_classifier_subject_%1g',subject), 'classifiers');
    
    close(figure(2))
    close(figure(3))
    close(figure(4))
end