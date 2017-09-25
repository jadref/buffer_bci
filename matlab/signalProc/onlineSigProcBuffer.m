function []=onlineSigProcBuffer(varargin);
% run the on-line signal processor process -- this does real-time processing which must reponsed as fast as possible
ignorePhases={'calibrate','calibration','erpviewcalibrate','erpviewercalibrate','calibrateerp','sliceraw','loadtraining','cleartraining',...
              'train','training','trainerp','trainersp','train_subset','trainerp_subset','trainersp_subset','train_useropts','trainerp_useropts','trainersp_useropts'};
startSigProcBuffer('label','online',varargin{:},'ignorePhases',ignorePhases);
