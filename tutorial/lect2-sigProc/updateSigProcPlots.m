if( ~exist('yvals','var')  ) yvals=[]; end;
if( ~exist('ylab','var') )   ylab='time'; end;
%Update the plots
figure(1);set(gcf,'Name','Single Trials');clf;image3d(X(:,:,1:3),1,'plotPos',Cpos,'Xvals',Cnames,'Yvals',yvals,'ylabel',ylab,'disptype','plot','ticklabs','sw');
%% plot the class averages
figure(2);set(gcf,'Name','Class Average');clf;image3d(cat(3,mean(X(:,:,Y>0),3),mean(X(:,:,Y<=0),3)),1,'plotPos',Cpos,'Xvals',Cnames,'Yvals',yvals,'ylabel',ylab,'Zvals',{'pos','neg'},'disptype','plot','ticklabs','sw');
zoomplots; % allow interactive zooming of the plots to see better what's going on
