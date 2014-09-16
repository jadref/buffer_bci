function [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_Aud(h,duration,isi,tti,oddp)
if ( nargin<2 || isempty(duration) ) duration=3; end; % default to 3sec
if ( nargin<3 || isempty(isi) ) isi=6/60; end; % default to 10Hz
if ( nargin<4 || isempty(tti) ) tti=isi*10; end; % default to ave target every 5th event
if ( nargin<5 || isempty(oddp) ) oddp=false; end; % only stimulate on odd events, even cause reset to no stim
% make a simple visual intermittent flash stimulus
colors=[0 1 0;... % color(1)=tgt
        0 1 0;...
        0 1 0]';  % color(2)=std
stimTime=0:isi:duration; % 10Hz, i.e. event every 100ms
stimSeq =-ones(numel(h),numel(stimTime)); % make stimSeq which is all off
% default to the standard
stimSeq(1,:)=-5;
stimSeq(4,:)=1; % turn-on only the central square
if ( oddp ) stimSeq(1,1:2:end-1)=0; stimSeq(4,2:2:end-1)=3;end; % Nothing on even events
eventSeq=cell(numel(stimTime),1);
% seq is random flash about 1/sec
t=tti/2+fix(rand(1)*5)/10*tti/2;
while (t<max(stimTime))
  [ans,si]=min(abs(stimTime-t)); % find nearest stim time
  if( oddp ) si=2*fix(si/2); end % round to nearest even stimulus position
  stimSeq(1,si)=-4;
  stimSeq(4,si)=2; %optional flashing to check stimulus timing
  t=stimTime(si);
  dt=(2+rand(1)*8)/10*tti; % roughly tti between stimulus events
  t=t+dt;
end
sval='aud'; if (oddp) sval='odd'; end;
for si=1:size(stimSeq,2);
  switch (stimSeq(1,si))
   case 1; eventSeq{si} = {'stimulus' [sval ' tgt']}; 
   case 2; eventSeq{si} = {'stimulus' [sval ' non-tgt']}; 
   case -4; eventSeq{si} = {'stimulus' [sval ' tgt']};
   case -5; eventSeq{si} = {'stimulus' [sval ' non-tgt']};
   otherwise; 
  end
end

return;
