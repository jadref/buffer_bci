% Note: this solution works differently to the proposal in the slides.  Here the signal-processor
% internally accumulates the predictions for each flash event, and then sends all the predictions in
% 1 big event value when requested by sending a ('stimulus.sequence,'end') event

try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end
try; cd(fileparts(mfilename('fullpath')));catch; end; %ARGH! fix bug with paths on Octave
  
buffhost='localhost';buffport=1972;
% wait for the buffer to return valid header information
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
  try 
    hdr=buffer('get_hdr',[],buffhost,buffport); 
  catch
    hdr=[];
    fprintf('Invalid header info... waiting.\n');
  end;
  pause(1);
end;

% set the real-time-clock to use
initgetwTime;
initsleepSec;

verb=1;
cname='clsfr';
trlen_ms=600;
clsfr=load(cname);if(isfield(clsfr,'clsfr'))clsfr=clsfr.clsfr;end;

state=[];  % initialize state to empty to ignore predictions before the 1st call
endTest=0; fs=0;
while ( endTest==0 )
  % wait for data to apply the classifier to, return as soon as some data is ready
  % N.B. propgate 'state' between calls to ensure 'pending' but not ready events aren't forgotten
  [data,devents,state]=buffer_waitData(buffhost,buffport,state,'startSet','stimulus.flash','trlen_ms',trlen_ms,'exitSet',{'data' 'stimulus.feedback'});
  
  % process these events
  for ei=1:numel(devents) % N.B. may be more than 1 trigger event between calls!
    if ( matchEvents(devents(ei),'stimulus.sequence','end') ) % end sequence
      endSeq=ei; % record which is the end-seq event
    elseif (matchEvents(devents(ei),'stimulus.feedback','end') ) % end training
      endTest=ei; % record which is the end-feedback event
    elseif ( matchEvents(devents(ei),'stimulus.flash') ) % flash, apply the classifier
      if ( verb>0 ) fprintf('Processing event: %s',ev2str(devents(ei))); end;
                          % apply classification pipeline to this events data
      [f,fraw,p]=buffer_apply_erp_clsfr(data(ei).buf,clsfr);
      % send prediction, using the trigger-event sample number for matching later
      sendEvent('classifier.prediction',f,devents(ei).sample);
    end
  end % devents 
end % feedback phase
