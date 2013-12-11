function [stimSeq,stimTime,eventSeq]=mkStimSeqRand(nSymbols,nStim,isi,mintti)
% make a random stimulus sequence of a set of symbols with a min-time between stimulus events
%
% [stimSeq,stimTime,eventSeq,stimCode]=mkStimSeqRand2Symb(nSymbols,nStim,isi,mintti)
%
% 
% N.B. the mintti means that for much of the time *nothing is flashed* (otherwise it would happen too soon)
%
% Inputs:
%  mxSz     -- [2 x 1] number of [rows cols] in the matrix
%  nStim    -- [int] number of stimulus events to make the sequence for
%  isi      -- [float] inter-stimulus interval in seconds                (1)
% Outputs:
%  stimSeq  -- [2*nSymbols x nStim] logical matrix with true indicating that this symbol 
%                       should flashed at this time
%               N.B. 2*nSymbols as we assume each symbol has 2 'states' and a stimulus event
%                    switches the symbol from state=1 to state=2, i.e. turns one symbol off and the other on.
%  stimTime -- [1 x nStim] time in seconds each stimulus event should take place
%  eventSeq -- {1 x nStim} cell array containing {2x1} event info which should be sent at each stimulus time.
%                   Each entry is either empty (i.e. {}) indicating no event to be sent or
%                   {type value} a cell array with the event type and value to send
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
eventSeq=[zeros(2,1) stimSeq([1 3],1:end-1)~=stimSeq([1 3],2:end)];  
