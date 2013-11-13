function [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_Vis(h,duration,isi)
if ( nargin<2 || isempty(duration) ) duration=3; end; % default to 3sec
if ( nargin<3 || isempty(isi) ) isi=6/60; end; % default to 10Hz
% make a simple visual intermittent flash stimulus
colors=[1 1 1]';  % color(1) = baseline
stimTime=0:.1:duration; % 10Hz, i.e. event every 100ms
stimSeq =-ones(numel(h),numel(stimTime)); % make stimSeq where everything is turned off
stimSeq(1,:)=0; % turn-on only the central square
flashStim=-ones(numel(h),1); flashStim(1)=1; % flash only has symbol 1 set
eventSeq=cell(numel(stimTime),1);
[eventSeq{:}]=deal({'stimulus','Non-Tgt'}); % all events are non-target
% seq is random flash about 1/sec
t=fix(rand(1)*10)/10;
while (t<max(stimTime))
  [ans,si]=min(abs(stimTime-t)); % find nearest stim time
  stimSeq(:,si)=flashStim;
  eventSeq{si}={'stimulus','Tgt'}; % this is a target event
  dt=.5+fix(rand(1)*5)/10;
  t=t+dt;
end
return;
