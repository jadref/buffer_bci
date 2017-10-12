try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end

%% load the data this contains
% X - [ channels x time x epochs ] raw EEG data
% Y - [ epochs x 1 ] class labels for X's epochs
% fs- [int] sample rate of X
% Cnames - {str nCh x 1} cell array of strings for the names of X's channels
% Cpos - [2 x nCh] x-y positions of each of X's channels (for plotting)
load('ERPdata'); 

%% plot the first 3 epochs of the data in a topo-graphic multi-plot
figure(1);set(gcf,'Name','Single Trials');clf;image3d(X(:,:,1:3),1,'plotPos',Cpos,'Xvals',Cnames,'disptype','plot','ticklabs','sw');
%% plot the class averages
erp = cat(3,mean(X(:,:,Y>0),3),mean(X(:,:,Y<=0),3));
figure(2);set(gcf,'Name','Class Average');clf;image3d(erp,1,'plotPos',Cpos,'Xvals',Cnames,'Zvals',{'pos','neg'},'disptype','plot','ticklabs','sw');
zoomplots; % allow interactive zooming of the plots to see better what's going on


%% 1) detrend and try again
X=detrend(X,2);
updateSigProcPlots; %Update the plots

%% 2) remove bad channels
badch = idOutliers(X,1,2.5);
X=X(~badch,:,:);
% don't forget to update the channel info too!
Cpos=Cpos(:,~badch);
Cnames=Cnames(~badch);

updateSigProcPlots; % update the plots

%% 3) re-reference - CAR
% CAR= Common-Average-Reference = average activity over channels = mean(X,1)
X =X - repmat(mean(X,1),[size(X,1),1,1]);
% alt faster version: X = repop(X,'-',mean(X,1));
updateSigProcPlots; % update the plots

%% 4) spectrally filter
% frequency bands = [low-cuttoff low-pass high-pass high-cutoff]
%    e.g. [.1 .3 12 15] => remove below .1Hz or above 15Hz, pass-unchanged above .3Hz and below 12Hz
filt=mkFilter(size(X,2)/2,[.1 .3 12 15],fs/size(X,2));
X   =fftfilter(X,filt,[],2);

updateSigProcPlots; % update the plots

%% 2.5) remove bad epochs
badep = idOutliers(X,3,3);
X=X(:,:,~badep);
Y=Y(~badep); % don't forget to update labels!

updateSigProcPlots; % update the plots


%%6) train classifier
fprintf('6) train classifier\n');
% N.B. this will overwrite your plots in any case
[clsfr, res]=cvtrainLinearClassifier(X,Y,[],10,'compKernel',0,'objFn','lr_cg');

%%7) use train_erp_clsfr which does all this for you!
[clsfr,res,X]=train_erp_clsfr(X,Y,'ch_pos',Cnames,'fs',fs,'compKernel',0,'objFn','lr_cg');
