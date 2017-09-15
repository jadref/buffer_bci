function []=batchSigProcessor(varargin);
% run the background signal processor process -- this does non-real-time background processes, e.g. saving calibration data, classifier training
catchPhases={'calibrate','calibration','erpviewcalibrate','erpviewercalibrate','calibrateerp','sliceraw','loadtraining','cleartraining',...
             'train','training','trainerp','trainersp','train_subset','trainerp_subset','trainersp_subset','train_useropts','trainerp_useropts','trainersp_useropts'};
% additionally catch training data events during these phases
calibrateExtraPhases={'test','testing','epochfeedback','eventfeedback','contfeedback'};
startSigProcBuffer(varargin{:},'catchPhases',{catchPhases{:},calibrateExtraPhases{:}},'calibrateExtraPhases',calibrateExtraPhases);
