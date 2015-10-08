function [stimSeq,stimTime,eventSeq]=mkStimSeqRand2Color(nSymbols,nStim,isi,mintti)
% make a random stimulus sequence of a set of symbols with 2 stimulus types (colors)
%
% [stimSeq,stimTime,eventSeq]=mkStimSeqRand2Color(nSymbols,nStim,isi,mintti)
%
% N.B. The 2nd color flash happens only *once* per "repetition", that is once every nSymbols
%
% Inputs:
%  mxSz     -- [2 x 1] number of [rows cols] in the matrix
%  nStim    -- [int] number of stimulus events to make the sequence for
%  isi      -- [float] inter-stimulus interval in seconds                (1)
% Outputs:
%  stimSeq  -- [int nSymbols x nStim] logical matrix with true indicating that this symbol 
%                       should flashed at this time
%                 This has 2 possible values:  0=don't flash, 1=normal flash, 2=2nd color flash
%  stimTime -- [1 x nStim] time in seconds each stimulus event should take place
%  eventSeq -- {1 x nStim} cell array containing {2x1} event info which should be sent at each stimulus time.
%                   Each entry is either empty (i.e. {}) indicating no event to be sent or
%                   {type value} a cell array with the event type and value to send
if ( nargin<4 || isempty(mintti) ) mintti=max(round(nSymbols)/2,nSymbols-2); end;
% make normal 1 color stim seq
[stimSeq,stimTime,eventSeq,colors,stimCode]=mkStimSeqRand(nSymbols,nStim,isi,mintti);
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
