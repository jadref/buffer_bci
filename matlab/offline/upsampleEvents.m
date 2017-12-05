function [triggerEvents]=upsampleEvents(allevents,triggerSet,trlen_samp,step_samp,ustest)
% up-sample event stream by duplicating the trigger event every step_samp samples until trlen_samp
%
%Inputs:
%  allevents - [struct] set of all events to process
% triggerSet - {mtype mval} match specification of which events are trigger/trial events in
%              specification compatiable with matchEvents.
% trlen_samp - [int] maximum trial length, i.e. no upsampled events after this point relative
%                    to the starting trigger event
% step_samp  - [int] number of samples between upsampled trigger events
if( nargin<5 || isempty(ustest) ) ustest=false; end;

                                %1) get the trigger set
triggerEvents=allevents; % default to all events
if ( ~isempty(triggerSet) )
  if( ischar(triggerSet) ) triggerSet={triggerSet}; end;
  mi=matchEvents(allevents,triggerSet{:});
  triggerEvents=allevents(mi);
end
if( isempty(triggerEvents) ) return; end;

                                %2) up-sample the triggerEvents
triggerSamp = [triggerEvents.sample];
dtriggerSamp= [diff(triggerSamp) inf];
                    %BODGE: trigger test, to avoid up-sampling when uncessary
if( ustest>0  )
  if( numel(triggerEvents)<=1 )
    ustest = 0;
  else 
    ustest = abs(median(dtriggerSamp(1:end-1))-step_samp)<ustest;%most triggers ~= step_samp
  end
  if( ~ustest ) fprintf('Upsampling triggers\n'); else fprintf('Not upsampling triggers\n'); end;
else
  ustest = false;
end
ntriggerEvents=[];
for ei=1:numel(triggerEvents);
     % get the end-sample for the up-sampling, min next-trigger or trlen_samp
  evttrlen = min(trlen_samp,dtriggerSamp(ei)); 
    % number of copies of event to fit in this gap
  evt  = triggerEvents(ei);
  if( ~ustest && evttrlen >= 2*step_samp )
    rsamp = 0:step_samp:evttrlen-step_samp; %up-sample positions
    evt=repmat(evt,[numel(rsamp),1]);
    for ri=1:numel(rsamp); evt(ri).sample=evt(1).sample+rsamp(ri); end;
  end
                                % add to the updated event list
  ntriggerEvents=[ntriggerEvents;evt];
end
if( ~ustest )
  fprintf('Upsampled: %d -> %d events\n',numel(triggerEvents),numel(ntriggerEvents));
end;
triggerEvents = ntriggerEvents;
return;

  %----------------------------------------------------------------
function testCase();
  step_ms  =750;
  trlen_ms =5000;
  hdr      =read_buffer_offline_header(fullfile(datadir,'header'))
  allevents=read_buffer_offline_events(fullfile(datadir,'events'))
  step_samp = ceil(step_ms*hdr.Fs/1000);
  trlen_samp= ceil(trlen_ms*hdr.Fs/1000);
  uu=upsampleEvents(allevents,[],trlen_samp,step_samp);
  uu=upsampleEvents(allevents,'stimulus.target',trlen_samp,step_samp);
