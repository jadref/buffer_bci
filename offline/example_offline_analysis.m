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

% 1) slice 3000ms from start of all events with type 'stimulus.target'
% Note: internally sliceraw consists of 3 main steps
%  1.1) read the header information
%  1.2) read all events and select the subset we want to get data from
%  1.3) read the data for the selected events
% If you have a more complex criteria for which events to slice and return
% then you should modify step 1.2 in the sliceraw.m file
[data,devents,hdr,allevents]=sliceraw('example_data/raw_buffer/0001','startSet',{'stimulus.target'});

% 2) train a ERsP classifier on this data.
[clsfr,X]=buffer_train_ersp_clsfr(data,devents,hdr,'freqband',[8 10 24 28],'capFile',capFile);
% N.B. X now contains the pre-processed data which can be used for other purposes, e.g. making better plots.

% 3) apply this classifier to the same data (or new data)
[f]      =buffer_apply_ersp_clsfr(data,clsfr);  % f contains the classifier decision values

%%---------------------------------------------------------------------------------
% Alt1 : just run the pre-processing on this data
%        assuming that [events.value] contains a class indicator for each epoch
[X_pp,pipeline]=preproc_erp(data,'Y',events,'fs',hdr.Fs,'freqband',[8 10 24 28],'capFile',capFile,'overridechnms',1);
[X_pp,pipeline]=preproc_ersp(data,'Y',events,'fs',hdr.Fs,'freqband',[8 10 24 28],'capFile',capFile,'overridechnms',1);

%%---------------------------------------------------------------------------------
% Alt2: Manually pre-process the data
dd=cat(3,data.buf); % get 3-d array
dd=detrend(dd,2);   % temporal trend removal
dd=repop(dd,'-',mean(dd,1)); % CAR - spatial mean removal
dd=fftfilter(dd,mkFilter(floor(size(dd,2)/2),[0 0 30 40],1/3),[],2); % spectral low pass 30Hz
clf;imagesc(mean(dd,3)); % plot average time-locked data
% Alt2: Plot with channels in the right positions
[ch_name,ans,ch_pos]=readCapInf('1010'); % get electrode names and positions
clf;image3d(mean(dd,3),1,'disptype','plot','plotPos',ch_pos,'xvals',ch_name);%plot average time-locked data
