function [stimSeq,stimTime,eventSeq]=mkStimSeqRand2Color(nSymbols,nStim,isi,mintti)
if ( nargin<4 || isempty(mintti) ) mintti=max(round(nSymbols)/2,nSymbols-2); end;
% make normal 1 color stim seq
[stimSeq,stimTime,eventSeq,stimCode]=mkStimSeqRand(nSymbols,nStim,isi,mintti);
% now add 2nd color, 1 every repetition
for seqi=1:floor(nStim/nSymbols);
  seqStart=seqi*nSymbols;
  sci=mod(seqi-1,nSymbols)+1;
  if ( sci==1 ) stimCode2=randperm(nSymbols); end;
  tgtSymb=stimCode2(sci);
  tgtEventi=seqStart-1+find(stimSeq(tgtSymb,seqStart:min(end,seqStart+nSymbols))>0,1);
  stimCode(tgtEventi) = nSymbols+tgtSymb; % code is nSymbs + symb#
  stimSeq(tgtSymb,tgtEventi)=2; % code in the sequ is 2
end
return;

%----------------------
function testCase();
nSymbs=6;
ss=mkStimSeqRand2Color(nSymbs,2*nSymbs*nSymbs,100); sum(ss,2), 
% compute mean tti statistics for each symb
for si=1:size(ss,1); tti=diff(find(ss(si,:)));fprintf('%g\t%g\t%g\t%g\n',min(tti),mean(tti),max(tti),var(tti));end;
% simple play sequence function
clf;
for hi=1:nSymbs; 
  theta=hi/nSymbs*2*pi; x=cos(theta); y=sin(theta);
  h(hi)=rectangle('curvature',[1 1],'position',[x,y,.5,.5],'facecolor',[0 0 0]); 
end;
set(gca,'visible','off')
for i=1:size(ss,2);
  set(h(ss(:,i)>0),'facecolor',[.5 .5 .5]);
  set(h(ss(:,i)<=0),'facecolor',[0 0 0]);
  set(h(ss(:,i)>1),'facecolor',[0 1 0]);
  pause(.1);
end
