function [stimSeq,stimTime,eventSeq,colors]=mkStimSeqSSEP(nSymbs,duration,isi,periods,smooth)
% make a periodic flicker stimulus
% 
%   [stimSeq,stimTime,eventSeq,colors]=mkStimSeqSSEP(nSymbs,duration,isi,periods,mkTarget,smooth)
%
% Inputs:
%  nSymbs        - [int] number of symbols to make flicker sequence for
%           OR
%             [nSymbs x 1] handles to the objects to flicker
%  duration - [float] duration of stimulus in seconds           (3)
%  isi      - [single] inter stimulus duration in seconds       (2/60)
%  periods  - [nSymbs x 1] period in *seconds* for targets cycle  ([2 4 ..])
%             OR
%             [nSymbs x 2]  period+phase for each targets cycle
%  smooth   - [bool] continuous outputs? or binary?             (false)
%             N.B. you need about 5-samples/period to get a smooth sin approx
% Outputs:
%  stimSeq  -- [bool nSymbols x nStim] logical matrix with true indicating that this symbol 
%                       should flashed at this time
%  stimTime -- [1 x nStim] time in seconds each stimulus event should take place
%  eventSeq -- {1 x nStim} cell array containing {2x1} event info which should be sent at each stimulus time.
%                   Each entry is either empty (i.e. {}) indicating no event to be sent or
%                   {type value} a cell array with the event type and value to send
%  colors   -- [3x nCol] colors for each of the different stimulus values 
%
% See also: mkStimSeqRand, mkStimSeq2Color
if ( numel(nSymbs)>1 ) nSymbs=numel(nSymbs); end;
if ( nargin<2 || isempty(duration) ) duration=3; end; % default to 3sec
if ( nargin<3 || isempty(isi) ) isi=2/60; end; % default to 60Hz
if ( nargin<4 || isempty(periods) ) periods=(1:nSymbs)*2; end;
if ( nargin<5 || isempty(smooth) )   smooth=false; end;
if ( size(periods,2)==nSymbs && size(periods,1)<=2 ) periods=periods'; end;
if ( size(periods,1)<nSymbs ) warning('Insufficient flicker periods given... set to off'); end;
if ( size(periods,2)==1 ) periods=[periods(:) zeros(size(periods))]; end; % add 0-phase info
% make a simple visual intermittent flash stimulus
nStim = duration/isi;
stimTime=(1:nStim)*isi(1);
eventSeq=[]; 
stimSeq =zeros(nSymbs,nStim); % make stimSeq where everything is in background state
for stimi=1:size(periods,1);
  % N.B. include slight phase offset to prevent value being exactly==0
  stimSeq(stimi,:) = cos((stimTime+.0001+periods(stimi,2))/periods(stimi,1)*2*pi); 
end
if ( smooth ) 
  stimSeq=(stimSeq+1)/2; % ensure all positive values in range 0-1
  colors =[]; % no color table
else
  stimSeq=single(stimSeq>0); 
  colors=[1 1 1;...   % color(1) = flash
			 0 1 0]';    % color(2) = target
end;


return;
%---------------------
function testCase()
% binary
[stimSeq,stimTime]=mkStimSeqSSEP(10,10,1/20,1+[1:10]');
% continuous
[stimSeq,stimTime]=mkStimSeqSSEP(10,10,1/20,6+[1:10]',1);
% phase shifts
[stimSeq,stimTime]=mkStimSeqSSEP(10,10,1/20,[6*ones(1,10);2*pi*(randperm(10))]',1);

clf;mcplot(stimTime(1:size(stimSeq,2)),stimSeq,'lineWidth',1)
clf;playStimSeq(stimSeq,stimTime,'cont',1)
