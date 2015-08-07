function [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_flicker(h,duration,isi,periods,mkTarget,smooth)
if ( nargin<2 || isempty(duration) ) duration=3; end; % default to 3sec
if ( nargin<3 || isempty(isi) ) isi=1/60; end; % default to 60Hz
if ( nargin<4 || isempty(periods) ) periods=[2 4]; end;
if ( nargin<5 || isempty(mkTarget) ) mkTarget=true; end;
if ( nargin<6 || isempty(smooth) )   smooth=false; end;
% make a simple visual intermittent flash stimulus
colors=[1 1 1;...;  % color(1) = flash
        0 1 0]';    % color(2) = target
stimTime=0:isi:duration; % event every isi
stimSeq =-ones(numel(h),numel(stimTime)); % make stimSeq where everything is turned off
%stimSeq(2:end-1,:)=0; % turn-on only the central square
%flashStim=-ones(numel(h),1); flashStim(1)=1; % flash only has symbol 1 set
for stimi=1:numel(h)-2;
  % N.B. include slight phase offset to prevent value being exactly==0
  stimSeq(stimi+1,:) = cos(((0:numel(stimTime)-1)+.0001)/periods(stimi)*2*pi); 
  if ( ~smooth ) stimSeq(stimi+1,:)=double(stimSeq(stimi+1,:)>0); end;
end
eventSeq=cell(numel(stimTime),1); % No events...

% Pick who is going to be the target
tgt=randi(numel(h)-2);
freqs=[]; for i=1:numel(periods); freqs(i) = 1/(periods(i)*isi); end;

% except every 1s we send a SSVEP event
evTime=0:1:stimTime(end)-1;
for i=1:numel(evTime); 
  [ans,si]=min(abs(stimTime-evTime(i))); % find nearest stim time
  eventSeq{si}={'stimulus',sprintf('flicker %g',freqs(tgt))};
end

% add a target queue
if ( mkTarget )
  stimTime=[0 stimTime+1];
  flashStim=-ones(numel(h),1); flashStim(2:end-1)=0; flashStim(1+tgt)=2; % tgt has 2 set
  stimSeq=cat(2,flashStim,stimSeq);
  eventSeq=cat(1,{{'stimulus.target',tgt}},eventSeq);
end

return;
