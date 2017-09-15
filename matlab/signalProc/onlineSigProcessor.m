function []=onlineSigProcessor(varargin);
% run the on-line signal processor process -- this does real-time processing which must reponsed as fast as possible
ignorePhases={'calibrate','calibration','erpviewcalibrate','erpviewercalibrate','calibrateerp','sliceraw','loadtraining','cleartraining'};
startSigProcBuffer(varargin{:},'ignorePhases',ignorePhases);
