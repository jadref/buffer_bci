function [stimSeq,stimTime,eventSeq,stimCode]=mkStimSeqRand(nSymbols,nStim,isi,mintti)
% [stimSeq,stimTime,eventSeq,stimCode]=mkStimSeqRand(nSymbols,nStim,isi,mintti)
if ( nargin<3 || isempty(isi) ) isi=1; end;
if ( nargin<4 || isempty(mintti) ) mintti=max(round(nSymbols)/2,nSymbols-2); end;
stimSeq=zeros(nSymbols,nStim); 
stimCode=zeros(1,nStim);
lastUsed=randperm(nSymbols); % index i'th symbol was last usedx
leftSymbs=true(1,nSymbols);  % symbol still available for use
stimCode(lastUsed)=1:nSymbols;
for si=nSymbols+1:nSymbols:nStim;
  leftSymbs(:)=true;
  for ssi=0:nSymbols-1;
    posSymbs=find(lastUsed<si+ssi-mintti & leftSymbs);
    if (isempty(posSymbs)) continue; end;
    sel     =posSymbs(max(1,ceil(rand(1)*numel(posSymbs))));
    lastUsed(sel)    = si+ssi; % mark as used in big seq
    leftSymbs(sel)   = false;  % mark as used in this subset of nSymbs
    stimCode(si+ssi) = sel;    % record selection
  end
end
for si=1:nStim; stimSeq(stimCode(si),si)=1; end;
stimTime=(0:size(stimSeq,2)-1)*isi(1);
eventSeq=stimSeq;
return;

%----------------------
function testCase();
nSymbs=8;
ss=mkStimSeqRand2Color(nSymbs,120,100); sum(ss,2), 
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
  set(h(ss(:,i)>0), 'facecolor',[0 0 0]);
  set(h(ss(:,i)<=0),'facecolor',[.5 .5 .5]);  
  pause(.1);
end
