function [stimSeq,stimTime,eventSeq]=mkStimSeqRand2Symb(nSymb,duration,isi,mintti)
% make a random stimulus sequence of a set of symbols with a min-time between stimulus events
%
% [stimSeq,stimTime,eventSeq]=mkStimSeqRand2Symb(nSymb,duration,isi,mintti)
% 
% N.B. the mintti means that for much of the time *nothing is flashed* (otherwise it would happen too soon)
%
% Inputs:
%  mxSz     -- [2 x 1] number of [rows cols] in the matrix
%  nStim    -- [int] number of stimulus events to make the sequence for
%  isi      -- [float] inter-stimulus interval in seconds                (1)
% Outputs:
%  stimSeq  -- [nSymb x nStim] logical matrix with true indicating that this symbol 
%                       should flashed at this time
%  stimTime -- [1 x nStim] time in seconds each stimulus event should take place
%  eventSeq -- {1 x nStim} cell array containing {2x1} event info which should be sent at each stimulus time.
%                   Each entry is either empty (i.e. {}) indicating no event to be sent or
%                   {type value} a cell array with the event type and value to send
if ( nSymb~=2 ) error('Only works for 2 symbol case'); end;
if ( nargin<4 || isempty(mintti) ) mintti=2; end;
if ( numel(mintti)<2 ) mintti(2)=5; end;
ttirange=mintti(2)-mintti(1);
nStim = duration/isi;
stimTime=(1:nStim)*isi(1);
stimSeq=zeros(nSymb,nStim); 
nFlip=[ceil(rand(1)*5) ceil(rand(1)*5)]; while(nFlip(1)==nFlip(2)) nFlip(2)=ceil(rand(1)*5); end; 
for i=1:size(stimSeq,2)
  %stimSeq(:,i)=stimSeq(:,i-1);
  if ( i==nFlip(1) )
    stimSeq(1,i)=1;%~stimSeq(1,i-1);
    nFlip(1)=i+mintti(1)+ceil(rand(1)*ttirange); 
    while(nFlip(1)==nFlip(2)) nFlip(1)=i+mintti(1)+ceil(rand(1)*ttirange); end;
  elseif ( i==nFlip(2) )
    stimSeq(2,i)=1;%~stimSeq(2,i-1);        
    nFlip(2)=i+mintti(1)+ceil(rand(1)*ttirange); 
    while(nFlip(1)==nFlip(2)) nFlip(2)=i+mintti(1)+ceil(rand(1)*ttirange); end;
  end;
end
stimTime=(0:size(stimSeq,2)-1)*isi(1);
eventSeq=[zeros(2,1) stimSeq(:,1:end-1)~=stimSeq(:,2:end)];  
