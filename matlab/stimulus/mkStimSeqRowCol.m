function [stimSeq,stimTime,eventSeq]=mkStimSeqRowCol(mxSz,duration,isi)
% make a random rows-then-cols flash sequence for given matrix size
%
% [stimSeq,stimTime,eventSeq,stimCode]=mkStimSeqRowCol(mxSz,duration,isi)
%
% Inputs:
%  mxSz     -- [2 x 1] number of [rows cols] in the matrix
%  duration -- [int] number of stimulus events to make the sequence for
%  isi      -- [float] inter-stimulus interval in seconds                (1)
% Outputs:
%  stimSeq  -- [bool nSymbols x nStim] logical matrix with true indicating that this symbol 
%                       should flashed at this time
%  stimTime -- [1 x nStim] time in seconds each stimulus event should take place
%  eventSeq -- {1 x nStim} cell array containing {2x1} event info which should be sent at each stimulus time.
%                   Each entry is either empty (i.e. {}) indicating no event to be sent or
%                   {type value} a cell array with the event type and value to send
nStim = duration/isi;
stimTime=(1:nStim)*isi(1);
eventSeq=[];
stimSeq=zeros(prod(mxSz),nStim); 

% stimKey - translates from stimCode into who's highlighted
subSeqR=1:mxSz(1); subSeqC=numel(subSeqR)+(1:mxSz(2));
stimKey=false([mxSz,numel(subSeqR)+numel(subSeqC)]);
for i=subSeqR; stimKey(i,:,i)=true; end; 
for i=subSeqC; stimKey(:,i-numel(subSeqR),i)=true; end;

% queue - gives the stim-code for each event
queue=zeros(numel(subSeqR)+numel(subSeqC),ceil(nStim/(numel(subSeqR)+numel(subSeqC))));
for i=1:size(queue,2); 
  queue(1:numel(subSeqR),i)                  = subSeqR(randperm(numel(subSeqR))); % rows
  queue(numel(subSeqR)+(1:numel(subSeqC)),i) = subSeqC(randperm(numel(subSeqC))); % cols
end;

% convert from stim-code to indicator set
for i=1:size(stimSeq,2);
  stimSeq(:,i)=reshape(stimKey(:,:,queue(i)),[],1);
end
return;

