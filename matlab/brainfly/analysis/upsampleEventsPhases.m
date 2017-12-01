function [triggerEvents]=upsampleEventsPhases(allevents,triggerSet,trlen_samp,step_samp,startPhase,endPhase)
              % up-sample event stream by inserting new events at new samples
if( nargin<4 ) startPhase=[]; end;

if( isempty(startPhase) ) % fast-path, no phase stuff...
  triggerEvents = upsampleEvents(allevents,triggerSet,step_samp,trlen_samp);
  return;
end
  
                              % 2) get the phase specific sub-set(s) (if wanted)
if( ischar(startPhase) ) startPhase={startPhase}; end;
bgnPhase=matchEvents(allevents,startPhase{:});
bgnPhaseEvt=allevents(bgnPhase);
if( ischar(endPhase) )   endPhase  ={endPhase}; end;
endPhase=matchEvents(allevents,endPhase{:});
endPhaseEvt=allevents(endPhase);
fprintf('Got %d bgns %d ends\n',numel(bgnPhaseEvt),numel(endPhaseEvt));

                                    %3) up-sample
triggerEvents=[];
evtsamples=[allevents.sample];
for phi=1:numel(bgnPhaseEvt); % phases..
  phaseIdx = bgnPhaseEvt(phi).sample < evtsamples & evtsamples < endPhaseEvt(phi).sample ;
  ptriggerEvents = upsampleEvents(allevents(phaseIdx),triggerSet,trlen_samp,step_samp);
  triggerEvents=[triggerEvents; ptriggerEvents]; % accumulate trigger events    
end
return;

                                %-----------------------------------------
function testCase();
step_ms  =750;
trlen_ms =5000;
hdr      =read_buffer_offline_header(fullfile(datadir,'header'))
allevents=read_buffer_offline_events(fullfile(datadir,'events'))
step_samp = ceil(step_ms*hdr.Fs/1000);
trlen_samp= ceil(trlen_ms*hdr.Fs/1000);
uu=upsampleEventsPhases(allevents,'stimulus.target',trlen_samp,step_samp,{'brainfly' 'start'},{'brainfly' 'end'});
ev2str(uu)
