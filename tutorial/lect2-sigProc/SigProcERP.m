% initialise the matlab paths
run ../../utilities/initPaths;

% load the data this contains
% X - [ channels x time x epochs ] raw EEG data
% Y - [ epochs x 1 ] class labels for X's epochs
% fs- [int] sample rate of X
% Cnames - {str nCh x 1} cell array of strings for the names of X's channels
% Cpos - [2 x nCh] x-y positions of each of X's channels (for plotting)
load('ERPdata'); 
times=(1:size(X,2))/fs;
yvals=times;

% plot the first 3 epochs of the data in a topo-graphic multi-plot
clf;image3d(X(:,:,1:3),1,'plotPos',Cpos,'Xvals',Cnames,'Yvals',yvals,'ylabel','time (s)','disptype','plot','ticklabs','sw');
% plot the class averages
erp = cat(3,mean(X(:,:,Y>0),3),mean(X(:,:,Y<=0),3));
clf;image3d(erp,1,'plotPos',Cpos,'Xvals',Cnames,'Yvals',yvals,'Zvals',{'pos','neg'},'disptype','plot','ticklabs','sw');

zoomplots; % allow interactive zooming of the plots to see better what's going on


% 1) detrend and try again
fprintf('1) Detrend\n');
X=detrend(X,2);

% 2) remove bad channels
fprintf('2) bad channel removal, ');
badch = idOutliers(X,1,2.5);
X=X(~badch,:,:);
% don't forget to update the channel info too!
Cpos=Cpos(:,~badch);
Cnames=Cnames(~badch);


% 3) re-reference - CAR
fprintf('3) CAR\n');
X =X - repmat(mean(X,1),[size(X,1),1,1]);
% alt faster version: X = repop(X,'-',mean(X,1));

% 4) spectrally filter
fprintf('4) filter\n');
filt=mkFilter(size(X,2)/2,[.1 .3 12 15],fs/size(X,2));
X   =fftfilter(X,filt,[],2);

% 4.5) remove bad epochs
fprintf('4.5) bad trial removal');
badep = idOutliers(X,3,3);
Xbad = X(:,:,badep); % store bad example to plot it..
% clf;image3d(Xbad,1,'plotPos',Cpos,'Xvals',Cnames,'disptype','plot','ticklabs','sw'); % plot bad info
X=X(:,:,~badep);
Y=Y(~badep); % don't forget to update labels!

%6) train classifier
fprintf('6) train classifier\n');
[clsfr, res]=cvtrainLinearClassifier(X,Y,[],10,'compKernel',0,'objFn','lr_cg');


%---------------------------------------------------------------------------------------------------
%7) use train_erp_clsfr which does all this for you!
[clsfr,res,X]=train_erp_clsfr(X,Y,'ch_pos',Cnames,'fs',fs,'compKernel',0,'objFn','lr_cg');