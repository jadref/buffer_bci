function [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_SSVEP(h,duration,isi,name)
if ( nargin<2 || isempty(duration) ) duration=3; end; % default to 3sec
if ( nargin<3 || isempty(isi) ) isi=2/60; end; % default to 15Hz
if ( nargin<4 || isempty(name) ) name='SSVEP'; end;
% make a simple visual intermittent flash stimulus
colors=[1 1 1]';% color(1) = flash
stimTime=0:isi:duration; % event every isi
stimSeq =-ones(numel(h),numel(stimTime)); % make stimSeq where everything is turned off
stimSeq(1,:)=0; % turn-on only the central square
flashStim=-ones(numel(h),1); flashStim(1)=1; % flash only has symbol 1 set
stimSeq(1,2:2:end)=1; % on-off alternation for the central square
eventSeq=cell(numel(stimTime),1); % No events...
% except every 1s we send a SSVEP event
evTime=0:1:stimTime(end)-1;
for i=1:numel(evTime); 
  [ans,si]=min(abs(stimTime-evTime(i))); % find nearest stim time
  eventSeq{si}={'stimulus',name};
end
return;
