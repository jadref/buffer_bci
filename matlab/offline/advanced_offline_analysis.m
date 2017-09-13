% This file contains example scripts for off-line analysis of a previously gathered 
% experiments data.
%
% Raw data is stored in a directory containing 4 files:
%  header : contains the data header information, e.g. sample rate, channel names
%  header.txt : contains the same info as in header but in human-readable text format
%  events : the events recorded during this experiment.
%  samples: the actual raw data
%  timing : time from the start of the experiment each sample occured.
%
% By default the raw data is saved to a directory with the name:
%            MAC/LINUX: ~/output/test/YYMMDD/HHMM/raw_buffer/0001 
%            WINDOWS: C:\output\test\YYMMDD\HHMM\raw_buffer\0001 
%     where YYMMDD is the date in year/month/day format,
%           HHMM is start time hourmin

% 0) Setup the paths so can find the functions ;)
run ../utilities/initPaths.m

% 1) slice 3000ms from -750 to 2500ms after the events with type 'stimulus.target'
[data,devents,hdr,allevents]=sliceraw('example_data/raw_buffer/0001','startSet',{'stimulus.tgtFlash'},'trlen_ms',1500,'offset_ms',[-750 750]);

% 2) train a ERP (time-locked) classifier on this data.
%        assuming that [events.value] contains a class indicator for each epoch
capFile='1010'; % you should change this to represent whatever cap layout was used in your experiment

% 2.3) Actually train an ERP classifier with:
%      i)  a 5.-10hz frequency range : 
%                'freqband',[.1 .5 10 12]
%      ii) sub-set to the time-range [0 1500]ms after filtering to avoid filtering artifacts
%                'timeband_ms',[750 750+1500]  % N.B. DANGER! DANGER! start of data is time=0!!
%      iii) common average spatial filter, i.e. no CAR
%                'spatialfilter','none'
%      iii) eye-artifact removal from the channel Oz
%                'adaptspatialfiltFn',{'artChRegress',{'Oz'}} 
%      iv) no-bad trial removal
%                'badtrrm',0
[clsfr,res,X,Y]=buffer_train_erp_clsfr(data,devents,hdr,'freqband',[.1 .5 10 12],'capFile',capFile,'timeband_ms',[750 750+1500],'spatialfilter','car','adaptspatialfiltFn',{'artChRegress',[],{'Oz'}},'badtrrm',0);

% 2.4) Actually train an ERP classifier with:
%      i)  a 5.-10hz frequency range : 
%                'freqband',[.1 .5 10 12]
%      ii) sub-set to the time-range [0 1500]ms after filtering to avoid filtering artifacts
%                'timeband_ms',[750 750+1500]  % N.B. DANGER! DANGER! start of data is time=0!!
%      iii) common average spatial filter
%                'spatialfilter','car'
%      iii) apply an adaptive filter pipeline with 2 stages.
%             a) eye-artifact removal from the channel Oz +
%             b) adaptive spatial whitening with 5 call exp-smoothing window
%                'adaptspatialfiltFn',{'filtPipeline' {{'artChRegress',{'Oz'}} {'adaptWhitenFilt' 'covFilt',5}} 
[clsfr,res,X,Y]=buffer_train_erp_clsfr(data,devents,hdr,'freqband',[.1 .5 10 12],'capFile',capFile,'timeband_ms',[750 750+1500],'spatialfilter','car','adaptspatialfiltFn',{'filtPipeline' {{'artChRegress',{'Oz'}} {'adaptWhitenFilt' 'covFilt',5}});


% This analysis should generate two summary figures:
%
% a) ERP / ERsP data.  
% This should be a head plot showing the averaged response for each of the
% different training conditions (as determined by the unique values of the
% trial events).  For ERP training this will be the signal amplitude over
% time after the trigger event.  For the ERsP training this will be the
% signal amplitude at different frequencies.
%
% b) AUC data.
% This plot shows where the signals for the different training conditions
% are most different and some indication of the magnitude of this
% difference.  Again is shows a head plot.  In this case the color of the
% plot shows the significance of the difference between conditions, with
% white=no-significant difference, and the strength of the color indicating
% the difference strength.  The magnitude of this difference is a rough
% indication of the classification performancy you could expect.
%
% c) Classifier performance.
% The final window will be a summary of the classifier performance on this
% data.  This is simply a number which is the fraction of trials the
% classifier would get correct.
% N.B. this is a so-called, balanced classification rate, so .5=chance and
% 1. is perfect performance.

% N.B. X now contains the pre-processed data which can be used for other purposes, e.g. making better plots.

% 3) apply this classifier to the same data (or new data)
[f]      =buffer_apply_clsfr(data,clsfr);  % f contains the classifier decision values
% visualise the classifier output
%figure(3);clf;plot([Y*10 f]);legend('true *10','prediction');

return;
