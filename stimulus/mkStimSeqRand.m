function [stimSeq,stimTime,eventSeq,colors,stimCode]=mkStimSeqRand(nSymb,duration,isi,mintti)
% make a stimulus sequence / stimTim pair for a set of nSymb
%
% [stimSeq,stimTime,eventSeq,colors,stimCode]=mkStimSeqRand(nSymb,duration,isi,mintti)
%
%  The stimSeq generated has the property that each symbols are are not flashed 
%  within mintti flashes of each other
%
% Inputs:
%  nSymb -- [int] number of symbols to make the sequence for
%  duration    -- [int] number of stimulus events to make the sequence for
%  isi      -- [float] inter-stimulus interval in seconds                (1)
%  mintti   -- [int] minimum number of stimulus events before same symbol can flash again (nSymb/2)
% Outputs:
%  stimSeq  -- [bool nSymb x nStim] logical matrix with true indicating that this symbol 
%                       should flashed at this time
%  stimTime -- [1 x nStim] time in seconds each stimulus event should take place
%  eventSeq -- {1 x nStim} cell array containing {2x1} event info which should be sent at each stimulus time.
%                   Each entry is either empty (i.e. {}) indicating no event to be sent or
%                   {type value} a cell array with the event type and value to send
%  stimCode -- [1 x nStim] number of the symbol to be flashed at each time
if ( nargin<3 || isempty(isi) ) isi=1; end;
if ( nargin<4 || isempty(mintti) ) mintti=max(round(nSymb)/2,nSymb-2); end;
colors=[1 1 1]'; % flash is white
nStim = ceil(duration/isi);
stimTime=(1:nStim)*isi(1);
eventSeq=[];
stimSeq=zeros(nSymb,nStim); 
stimCode=zeros(1,nStim);
lastUsed=randperm(nSymb); % index i'th symbol was last usedx
leftSymbs=true(1,nSymb);  % symbol still available for use
stimCode(lastUsed)=1:nSymb;
for si=nSymb+1:nSymb:nStim;
  leftSymbs(:)=true;
  for ssi=0:nSymb-1;
    posSymbs=find(lastUsed<si+ssi-mintti & leftSymbs);
    if (isempty(posSymbs)) continue; end;
    sel     =posSymbs(max(1,ceil(rand(1)*numel(posSymbs))));
    lastUsed(sel)    = si+ssi; % mark as used in big seq
    leftSymbs(sel)   = false;  % mark as used in this subset of nSymbs
    stimCode(si+ssi) = sel;    % record selection
  end
end
for si=1:nStim; if ( stimCode(si)>0) stimSeq(stimCode(si),si)=1; end; end;
return;

%----------------------
function testCase();
[stimSeq,stimTime]=mkStimSeqRand(10,10,1/10,2,1); 
clf;mcplot(stimTime,stimSeq,'lineWidth',1)
% compute mean tti statistics for each symb
for si=1:size(ss,1); tti=diff(find(stimSeq(si,:)));fprintf('%g\t%g\t%g\t%g\n',min(tti),mean(tti),max(tti),var(tti));end;
% simple play sequence function
clf;playStimSeq(stimSeq,stimTime)
