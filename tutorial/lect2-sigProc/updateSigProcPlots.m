%Update the plots
figure(1);clf;image3d(X(:,:,1:3),1,'plotPos',Cpos,'Xvals',Cnames,'disptype','plot','ticklabs','sw');
figure(2);clf;image3d(cat(3,mean(X(:,:,Y>0),3),mean(X(:,:,Y<=0),3)),1,'plotPos',Cpos,'Xvals',Cnames,'Zvals',{'pos','neg'},'disptype','plot','ticklabs','sw');
