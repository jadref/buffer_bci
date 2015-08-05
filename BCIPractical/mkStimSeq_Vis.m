function [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_Vis(h,duration,isi,tti,oddp)
if ( nargin<2 || isempty(duration) ) duration=3; end; % default to 3sec
if ( nargin<3 || isempty(isi) ) isi=1/10; end; % default to 10Hz
if ( nargin<5 || isempty(oddp) ) oddp=false; end; % standard between stimuli, and stimuli only on even event times
if ( nargin<4 || isempty(tti) ) tti=isi*8; if (oddp) tti=tti*2; end; end; % default to ave target every 5th event
% make a simple visual intermittent flash stimulus
colors=[ 0  1  0;... % color(1)=tgt
        .7 .7 .7]';     % color(2)=std
stimTime=0:isi:duration; % 10Hz, i.e. event every 100ms
stimSeq =-ones(numel(h),numel(stimTime)); % make stimSeq which is all off
stimSeq(1,:)=0; % turn-on only the central square
if ( oddp ) stimSeq(1,2:2:end-1)=2; end; % stimulus events only on even times
eventSeq=cell(numel(stimTime),1);
% seq is random flash about 1/sec
t=(.3+rand(1)*.7)*tti;
while (t<max(stimTime))
  [ans,si]=min(abs(stimTime-t)); % find nearest stim time
  if( oddp ) si=2*fix(si/2); end % round to nearest even stimulus position
  stimSeq(1,si)=1;
  t=stimTime(si);
  dt=(.5+rand(1)*.7)*tti;
  t=t+dt;
end
sval='vis'; if (oddp) sval='odd'; end;
for si=1:size(stimSeq,2);
  switch (stimSeq(1,si))
   case 1; eventSeq{si} = {'stimulus' [sval ' tgt']}; 
   case 2; eventSeq{si} = {'stimulus' [sval ' non-tgt']}; 
   otherwise; 
  end
end
return;
