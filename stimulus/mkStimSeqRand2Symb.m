function [stimSeq,stimTime,eventSeq]=mkStimSeqRand(nSymbols,nStim,isi,mintti)
if ( nSymbols~=2 ) error('Only works for 2 symbol case'); end;
stimSeq=zeros(nSymbols*2,nStim); 
stimSeq(:,1)=[1 0 1 0]';
nFlip=2+[ceil(rand(1)*5) ceil(rand(1)*5)]; while(nFlip(1)==nFlip(2)) nFlip(2)=2+ceil(rand(1)*5); end; 
for i=2:size(stimSeq,2)
  stimSeq(:,i)=stimSeq(:,i-1);
  if ( i==nFlip(1) )
    stimSeq(1:2,i)=~stimSeq(1:2,i-1);
    nFlip(1)=i+1+ceil(rand(1)*5); while(nFlip(1)==nFlip(2)) nFlip(1)=i+1+ceil(rand(1)*5); end;
  elseif ( i==nFlip(2) )
    stimSeq(3:4,i)=~stimSeq(3:4,i-1);        
    nFlip(2)=i+1+ceil(rand(1)*5); while(nFlip(1)==nFlip(2)) nFlip(2)=i+1+ceil(rand(1)*5); end;
  end;
end
stimTime=(0:size(stimSeq,2)-1)*isi(1);
eventSeq =[zeros(2,1) stimSeq([1 3],1:end-1)~=stimSeq([1 3],2:end)];  
