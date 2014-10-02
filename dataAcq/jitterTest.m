run ../utilities/initPaths.m
buffer('con');
pause(3);
t0=buffer('get_time');
times=0:3:60*10; tic; 
clear sampest time
for ti=1:numel(times)-1; 
  sampest(ti)=buffer('get_samp'); time(ti)=(buffer('get_time')-t0)/1000;
  fprintf('%3g)\test =%6d\t dEst =%3d\n',time(ti),sampest(ti),sampest(ti)-sampest(max(1,ti-1)));
  tmp=buffer('poll'); samp(ti)=tmp.nSamples; 
  fprintf('      \ttrue=%6d\t dTrue=%3d\t true-est=%3d\n',samp(ti),samp(ti)-samp(max(1,ti-1)),sampest(ti)-samp(ti)); 
  pause(times(ti+1)-toc);
end;
