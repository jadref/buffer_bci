function optimal_threshold = get_optimal_threshold(player,fs,datafile)

load(fullfile('data',[datafile,'_validate']));
load(fullfile('data',[player,'_','validate_predictions']));

cumsumTrialPred = [];
ci = 1;
for t=1:numel(trialstarts)-1
    idx = find(predictions(:,3)> trialstarts(t) & predictions(:,3)< trialstarts(t+1));
    if ~isempty(idx)
        cumsumTrialPred{ci} = predictions(idx,[1,3]);
        cumsumTrialPred{ci}(:,1) = cumsum(cumsumTrialPred{ci}(:,1));
        ci = ci+1;
    end
end
idx = find(predictions(:,3)> trialstarts(t+1));
if ~isempty(idx)
    cumsumTrialPred{ci} = predictions(idx,[1,3]);
    cumsumTrialPred{ci}(:,1) = cumsum(cumsumTrialPred{ci}(:,1));
end

% find first move prediction per trial
earliest_move_thres = zeros(numel(trialstarts),1);
for t=1:numel(cumsumTrialPred)
    if playermoves(t)>0 % if player moved this trial
        idx = find(cumsumTrialPred{t}(:,2)>=(playermoves(t)-(0.5*fs)),1,'first')
        earliest_move_thres(t) = cumsumTrialPred{t}(idx,1);
    end
end
earliest_move_thres = earliest_move_thres(find(earliest_move_thres>0)); % delete all nonmove trials

% get optimal threshold
optimal_threshold = mean(earliest_move_thres);

save(fullfile('data',[player,'_threshold']), 'optimal_threshold');






