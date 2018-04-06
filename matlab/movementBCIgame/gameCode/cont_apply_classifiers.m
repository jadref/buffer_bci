% Predict human movement intent.
% Needs a trained classifier from train_classifiers.
% version = 1: combines all classifiers
% version = 2: ERD classifier
% version = 3: RP classifier
% version = 4: EMg classifier
% Needs a running buffer and EMG or EEG data source
function cont_apply_classifiers(subject,version)

    run(fullfile('..','..','utilities','initPaths.m'));

    if version == 1 % all classifiers combined (it sums over all classifier predictions and applies the percentile filter on that single value)
        try
            load(fullfile('..','classifier',['comb_classifier_subject_',num2str(subject)]));
        catch
            msgbox({'Collect training data first!'},'Error');
        end
        [comb_data,comb_events,comb_predevents]=cont_applyClsfr(classifiers, 'endType', 'end_testing', 'endValue', 1,'maxFrameLag',50,...
            'predFilt',@(x,s,samples) percFilt(x,s,300,0.95),'predEventType',...
            'classifier_prediction','step_ms', 100, 'trlen_ms',1500);
        dname=fullfile('..','data',['predevents_comb_',num2str(subject)]);   
        save(dname,'comb_predevents');
    elseif version == 2 % ERD classifier
        try
            load(fullfile('..','classifier',['ERD_classifier_subject_',num2str(subject)]));
        catch
            msgbox({'Collect training data first!'},'Error');
        end
        [ERDdata,ERDevents,ERDpredevents]=cont_applyClsfr(clsfr_ERD, 'endType', 'end_testing', 'endValue', 1,'maxFrameLag',50,...
            'predFilt',@(x,s,samples) percFilt(x,s,300,0.95),'predEventType',...
            'classifier_prediction','step_ms', 100, 'trlen_ms',1500);
        dname=fullfile('..','data',['predevents_ERD_',num2str(subject)]);
        save(dname,'ERDpredevents');
    elseif version == 3 % RP classifier
        try
            load(fullfile('..','classifier',['RP_classifier_subject_',num2str(subject)]));
        catch
            msgbox({'Collect training data first!'},'Error');
        end
        [RPdata,RPevents,RPpredevents]=cont_applyClsfr(clsfr_RP, 'endType', 'end_testing', 'endValue', 1,'maxFrameLag',50,...
            'predFilt',@(x,s,samples) percFilt(x,s,300,0.95),'predEventType',...
            'classifier_prediction','step_ms', 100, 'trlen_ms',1500);
        dname=fullfile('..','data',['predevents_RP_',num2str(subject)]);
        save(dname,'RPpredevents');
    elseif version == 4 % EMG classifier
        try
            load(fullfile('..','classifier',['EMG_classifier_subject_',num2str(subject)]));
        catch
            msgbox({'Collect training data first!'},'Error');
        end
        [EMGdata,EMGevents,EMGpredevents]=cont_applyClsfr(clsfr_EMG, 'endType', 'end_testing', 'endValue', 1,'maxFrameLag',50,...
            'predFilt',@(x,s,samples) percFilt(x,s,300,0.95),'predEventType',...
            'classifier_prediction','step_ms', 100, 'trlen_ms',1500);
        dname=fullfile('..','data',['predevents_EMG_',num2str(subject)]);
        save(dname,'EMGpredevents');
    end
end

 