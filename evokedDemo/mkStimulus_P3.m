function [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_P3(h,duration,isi)
if ( nargin<2 || isempty(duration) ) duration=3; end; % default to 3sec
if ( nargin<3 || isempty(isi) ) isi=6/60; end; % default to 10Hz
% make a simple visual intermittent flash stimulus
colors=[1 1 1;...;  % color(1) = flash
        0 1 0]';    % color(2) = target
stimSeq =-ones(numel(h),numel(stimTime)); % make stimSeq where everything is turned off
stimSeq(1,:)=0; % turn-on only the central square
eventSeq=cell(numel(stimTime),1);
% Pick who is going to be the target
tgt=randi(numel(h)-2);

% seq is random flash about 1/sec
for stimi=1:numel(h)-2;
  flashStim=-ones(numel(h),1); flashStim(2:end-1)=0; flashStim(1+stimi)=1; % flash only has symbol 1 set
  t=fix(rand(1)*10)/10;
  while (t<max(stimTime))
    [ans,si]=min(abs(stimTime-t)); % find nearest stim time
    stimSeq(:,si)=flashStim;
    if ( tgt==stimi ) 
      eventSeq{si}={'stimulus','Tgt'}; % this is a target event
    else
      eventSeq{si}={'stimulus','Non-Tgt'}; % this is a target event
    end
    dt=.5+fix(rand(1)*5)/10;
    t=t+dt;
  end
end
return;
