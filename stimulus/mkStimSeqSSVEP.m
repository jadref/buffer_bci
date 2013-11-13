function [stimSeq,stimTime,eventSeq]=mkStimSeqSSVEP(nSymbols,nStim,isi,periods)
% the isi tells us what the frequencies should be
minPeriod=lcm(periods(1),periods(2));
stimSeq  =zeros(nSymbols,max(minPeriod,nStim-rem(nStim,minPeriod))); % make it loopable
% make stim sequences
for i=0:periods(1):size(stimSeq,2)-1; 
  stimSeq(1,i+(1:floor(periods(1)/2)),1) =1; stimSeq(1,i+(floor(periods(1)/2)+1:periods(1)),1) =0;
  stimSeq(2,i+(1:floor(periods(1)/2)),1) =0; stimSeq(2,i+(floor(periods(1)/2)+1:periods(1)),1) =1;
end;
for i=0:periods(2):size(stimSeq,2)-1; 
  stimSeq(3,i+(1:floor(periods(2)/2)),1) =0; stimSeq(3,i+(floor(periods(2)/2)+1:periods(2)),1) =1;
  stimSeq(4,i+(1:floor(periods(2)/2)),1) =1; stimSeq(4,i+(floor(periods(2)/2)+1:periods(2)),1) =0;
end;
stimTime=(0:size(stimSeq,2)-1)*isi(1);
% event every 1s
eventSeq=zeros(1,size(stimSeq,2));
stimDur=size(eventSeq,2)*isi(1);
eventSeq(1,round((0:floor(stimDur))/isi(1))+1)=1;
return;
%-------------------------
function testCase()