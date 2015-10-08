function []=playStimSeq(stimSeq,stimTime,colors,speedup)
if ( nargin<3 || isempty(colors) )  colors=[0 0 0;.5 .5 .5; 1 1 1]'; end;
if ( nargin<4 || isempty(speedup) ) speedup=1; end;
if ( isequal(colors,'cont') ) colors=[]; end;
% simple play sequence function
nSymbs=size(stimSeq,1);
clf;
for hi=1:nSymbs; 
  theta=hi/nSymbs*2*pi; x=cos(theta); y=sin(theta);
  h(hi)=rectangle('curvature',[1 1],'position',[x,y,.5,.5],'facecolor',[0 0 0]); 
end;
set(gca,'visible','off')

tic, t0=toc;
for i=1:numel(stimTime);
  set(h(stimSeq(:,i)<0),'visible','off');
  set(h(stimSeq(:,i)>0),'visible','on');
  if ( ~isempty(colors) )
	 set(h(stimSeq(:,i)==0),'facecolor',colors(:,1));
	 set(h(stimSeq(:,i)>0),'facecolor',colors(:,2));
	 set(h(stimSeq(:,i)>1),'facecolor',colors(:,min(end,3)));
  else
	 for hi=find(stimSeq(:,i)>=0)';		
		set(h(hi),'facecolor',stimSeq(hi,i)*[1 1 1]);
	 end
  end
  fi(i)=toc;
  drawnow;
  pause(max(0,stimTime(i)/speedup-fi(i)));
end
df=diff(fi);df(1)=[];
fprintf('total=%g  frame:mean,std,max s=%gs (%ghz), %g, %g \n',toc-t0,mean(df),1/mean(df),std(df),max(df));

