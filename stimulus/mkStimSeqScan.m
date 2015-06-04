function [stimSeq,stimTime,eventSeq,colors]=mkStimSeqScan(nSymbs,duration,isi)
% make a simple linear scan a stimulus sequence / stimTim pair for a set of nSymbs
%
% [stimSeq,stimTime,eventSeq,colors]=mkStimSeqScan(nSymbs,duration,isi,mintti)
%
%  Each of the nSymbs are highlighted in order in a simple linear scan  
%
% Inputs:
%  nSymbs -- [int] number of symbols to make the sequence for
%  duration    -- [int] number of stimulus events to make the sequence for
%  isi      -- [float] inter-stimulus interval in seconds                (1)
% Outputs:
%  stimSeq  -- [bool nSymbs x nStim] logical matrix with true indicating that this symbol 
%                       should flashed at this time
%  stimTime -- [1 x nStim] time in seconds each stimulus event should take place
%  eventSeq -- {1 x nStim} cell array containing {2x1} event info which should be sent at each stimulus time.
%                   Each entry is either empty (i.e. {}) indicating no event to be sent or
%                   {type value} a cell array with the event type and value to send
%  stimCode -- [1 x nStim] number of the symbol to be flashed at each time
if ( nargin<3 || isempty(isi) ) isi=1; end;
colors=[1 1 1]';
nStim = duration/isi;
stimTime=(1:nStim)*isi(1);
eventSeq=[]; 
stimSeq=zeros(nSymbs,nStim); 
stimSeq(mod(0:nStim-1,nSymbs)+1+(0:nStim-1))=1;
return;

%----------------------
function testCase();
[stimSeq,stimTime]=mkStimSeqScan(10,10,1/10); 
clf;mcplot(stimTime(1:size(stimSeq,2)),stimSeq,'lineWidth',1)
% compute mean tti statistics for each symb
for si=1:size(ss,1); tti=diff(find(stimSeq(si,:)));fprintf('%g\t%g\t%g\t%g\n',min(tti),mean(tti),max(tti),var(tti));end;
% simple play sequence function
clf;playStimSeq(stimSeq,stimTime)
