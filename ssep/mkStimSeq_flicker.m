function [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_flicker(nTgts,duration,isi,periods,mkTarget,smooth)
% make a periodic flicker stimulus
% 
%   [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_flicker(nTgts,duration,isi,periods,mkTarget,smooth)
%
% Inputs:
%  nTgts    - [int] number of targets to generate
%  duration - [float] duration of stimulus in seconds           (3)
%  isi      - [single] inter stimulus duration in seconds       (2/60)
%  periods  - [nTgts x 1] period for each targets cycle         ([2 4 ..])
%             OR
%             [nTgts x 2]  period+phase for each targets cycle
%  mkTarget - [bool] make a target choice for this epoch and    (true)
%             additional transitions to indicate it and events to show it.
%  smooth   - [bool] continuous outputs? or binary?             (false)
%
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
if ( numel(nTgts)>1 ) nTgts=numel(nTgts); end;
if ( nargin<2 || isempty(duration) ) duration=3; end; % default to 3sec
if ( nargin<3 || isempty(isi) ) isi=2/60; end; % default to 60Hz
if ( nargin<4 || isempty(periods) ) periods=(1:nTgts)*2; end;
if ( nargin<5 || isempty(mkTarget) ) mkTarget=true; end;
if ( nargin<6 || isempty(smooth) )   smooth=false; end;
if ( size(periods,2)==1 ) periods=[periods(:) zeros(size(periods))]; end; % add 0-phase info
% make a simple visual intermittent flash stimulus
colors=[1 1 1;...   % color(1) = flash
        0 1 0]';    % color(2) = target
stimTime=0:isi:duration; % event every isi
stimSeq =zeros(nTgts,numel(stimTime)); % make stimSeq where everything is in background state
stimSeq(2:end-1,:)=0; % turn-on only the central square
for stimi=1:size(periods,1);
  % N.B. include slight phase offset to prevent value being exactly==0
  stimSeq(stimi,:) = cos(((0:numel(stimTime)-1)+.0001+periods(stimi,2))/periods(stimi,1)*2*pi); 
end
if ( ~smooth ) stimSeq=double(stimSeq>0); end;
eventSeq=cell(numel(stimTime),1); % No events...

% add a target queue
if ( mkTarget )
  % Pick who is going to be the target
  tgt=randi(numel(h)-1);
  freqs=[]; for i=1:numel(periods); freqs(i) = 1/(periods(i,1)*isi); end;

  % every 1s we send a SSVEP event
  evTime=0:1:stimTime(end)-1;
  for i=1:numel(evTime); 
    [ans,si]=min(abs(stimTime-evTime(i))); % find nearest stim time
    eventSeq{si}={'stimulus',sprintf('SSVEP %g',freqs(tgt))};
  end

  stimTime=[0 stimTime+1];
  flashStim=-ones(numel(h),1); flashStim(1:end-1)=0; flashStim(tgt)=2; % tgt has 2 set
  stimSeq=cat(2,flashStim,stimSeq);
  eventSeq=cat(1,{{'stimulus.target',tgt}},eventSeq);
end

return;
