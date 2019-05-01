% Trains an EMG, RP and ERD classifier.
% Needs training data collected by get_train_data.
function train_classifiers(subject)
    
    % look for training data
    try
        datafile = fullfile('data',[subject,'_raw_data']);
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
    else % Porti
        badCh=ones(hdr.nChans,1);
        badCh([15:17])=0; % EMG channels + DIG
        badCh=logical(badCh); 
        iseeg=zeros(hdr.nChans,1);
        iseeg([1:14])=1;
        iseeg=logical(iseeg);
        ch_names=hdr.channel_names;
    end
    
    % preprocess data
    % alpha/beta ERD
    [preproc_ERD,res_ERD,X_ERD,Y_ERD]=buffer_train_ersp_clsfr(data,devents,hdr,'fs', hdr.fSample, 'badCh', ~iseeg, 'width_ms', 250,...
                        'badchrm', 0, 'badtrrm', 0, 'freqband',[3 5 30 40],'ch_names', ch_names,...
                        'overridechnms',1, 'windowType','hanning', 'detrend', 0,'classify',0,'visualize',0); 
    % RP
    [preproc_ERP,res_RP,X_ERP,Y_ERP]=buffer_train_erp_clsfr(data, devents,hdr, 'fs', hdr.fSample, 'badCh', ~iseeg, 'badchrm', 0,...
                        'badtrrm', 0, 'freqband',[0.1 0.2 15 20], 'ch_names', ch_names,'overridechnms',1, 'detrend', 0,'classify',0,'visualize',0); 
    
    % concatenate ERP and ERD features
    X_ERP = reshape(X_ERP, [], size(X_ERP, 3));
    X_ERD = reshape(X_ERD, [], size(X_ERD, 3));
    X_ERP_ERD = cat(1, X_ERP, X_ERD);
    
    % Train combined ERP+ERD classifier
    [clsfr_ERP_ERD, res_ERP_ERD] = cvtrainLinearClassifier(X_ERP_ERD, Y_ERP, [], 10, 'objFn', 'rkls_cg'); 
    
    % save the classifiers   
    save(fullfile('data',[subject,'_comb_classifier']), 'clsfr_ERP_ERD','res_ERP_ERD');
end