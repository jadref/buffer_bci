% This file contains example scripts for off-line analysis of a previously gathered 
% experiments data.
%
% Raw data is stored in a directory containing 4 files:
%  header : contains the data header information, e.g. sample rate, channel names
%  events : the events recorded during this experiment.
%  samples: the actual raw data
%  timing : time from the start of the experiment each sample occured.
%
% By default the raw data is saved to a directory with the name:
%            MAC/LINUX: ~/output/test/YYMMDD/HHMM_PID/raw_buffer/0001 
%            WINDOWS: C:\output\test\YYMMDD\HHMM\raw_buffer\0001 
%     where YYMMDD is the date in year/month/day format,
%           HHMM is start time hourmin
%           PID is the buffer process ID (usually a 5 digit number)

% 0) Setup the paths so can find the functions ;)
run ../utilities/initPaths

% 1) slice 3000ms from start of all events with type 'stimulus.trial' and value 'start'
% Note: internally sliceraw consists of 3 main steps
%  1.1) read the header information
%  1.2) read all events and select the subset we want to get data from
%  1.3) read the data for the selected events
% If you have a more complex criteria for which events to slice and return
% then you should modify step 1.2 in the slice-raw function
[data,devents,hdr]=sliceraw('~/output/test/140117/2145_20681/raw_buffer/0001','startSet',{'stimulus.trial' 'start'});

% 2) train a ERsP classifier on this data.
[clsfr,X]=buffer_train_ersp_clsfr(data,devents,hdr);
% N.B. X now contains the pre-processed data which can be used for other purposes, e.g. making better plots.

% 3) apply this classifier to the same data (or new data)
[f]      =buffer_apply_ersp_clsfr(data,clsfr);  % f contains the classifier decision values
