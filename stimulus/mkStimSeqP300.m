function [stimSeq,stimTime,eventSeq,colors]=mkStimSeqP300(nSymbs,duration,isi,tti,oddp)
% make a P300/oddball type of stimulus sequence
%
% [stimSeq,stimTime,eventSeq,stimCode]=mkStimSeqP300(nSymbs,duration,isi,mintti,oddp)
%
%  The stimSeq generated has the property that the same symbol will not flash again within
%  mittti seconds
%
% Inputs:
%  nSymbs -- [int] number of symbols to make the sequence for
%  duration  -- [int] duration of the stimulus in seconds
%  isi    -- [float] inter-stimulus interval in seconds                (1)
%  tti    -- [float] target-to-target interval, add non-stim events to ensure this many seconds
%                on average between highlighing this symbol
%  oddp   -- [bool] oddball, i.e. 3 stimulus types = target/standard/distractor, paradigm?
%                   all non-flashed stimuli have distractor value.
% Outputs:
%  stimSeq  -- [bool nSymbs x nStim] logical matrix with true indicating that this symbol 
%                       should flashed at this time
%  stimTime -- [1 x nStim] time in seconds each stimulus event should take place
%  eventSeq -- {1 x nStim} cell array containing {2x1} event info which should be sent at each stimulus time.
%                   Each entry is either empty (i.e. {}) indicating no event to be sent or
%                   {type value} a cell array with the event type and value to send
if ( numel(nSymbs)>1 ) nSymbs=numel(nSymbs); end;
if ( nargin<2 || isempty(duration) ) duration=3; end; % default to 3sec
if ( nargin<3 || isempty(isi) )  isi=1/5; end;        % default to 5hz
if ( nargin<4 || isempty(tti) )  tti =1; end;         % default to ave target every second
if ( nargin<5 || isempty(oddp) ) oddp=false; end;
tti=tti*isi; % convert to in terms of event times
% make a simple visual intermittent flash stimulus
colors=[1 1 1;...  % color(1) = flash
        0 1 0]';   % color(2) = target
nStim = duration/isi;
stimTime=(1:nStim)*isi(0); % event every isi
stimSeq =-ones(nSymbs,numel(stimTime)); % make stimSeq where everything is turned off
stimSeq(2:end-1,:)=0; % turn-on all symbols, to background color
if ( oddp ) 
  colors=[0  1  0;...   % flash
          0  1  0;...   % target
          .7 .7 .7]';   % std - approx iso-luminant
  stimSeq(2:end-1,2:2:end-1)=3; % every stimulus event
end
eventSeq=cell(numel(stimTime),1);
% seq is random flash about 1/sec
for stimi=1:nSymbs;
  flashStim=-ones(nSymbs,1); 
  flashStim(2:end-1)=0; 
  if ( oddp ) flashStim(2:end-1)=3; end;
  flashStim(1+stimi)=1; % flash only has symbol 1 set
  t=isi+fix(rand(1)*10)/10; dt=0;
  while (t<max(stimTime)) % loop to find a flash time not at the same time as another symbol
    [ans,si]=min(abs(stimTime-t)); % find nearest stim time    
    si=2*fix(si/2);
    if ( ~any(stimSeq(2:end-1,si)==1) || rand(1)>.99 ) % only insert if nothing else happening
      stimSeq(:,si)=flashStim;
      t=stimTime(si); % only update t if we inserted something
    else
      t=t-dt; % revert the previous candidate and try again
    end; 
    dt=(.5+rand(1)/2)*tti;
    t=t+dt;
  end
end
return;
%----------------------
function testCase();
% binary
[stimSeq,stimTime]=mkStimSeqP300(10,10,1/10,2,1);
clf;mcplot(stimTime,stimSeq,'lineWidth',1)
clf;playStimSeq(stimSeq,stimTime)
