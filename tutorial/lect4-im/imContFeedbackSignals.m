run ../../utilities/initPaths.m;

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
initsleepSec;

% constants
trialDuration=3;
trlen_ms   = trialDuration*1000;
step_ms    = 500; % new classification every 1/2 second
timeout_ms = 5000; % how long to wait for new data..
trlen_samp = round(trlen_ms*hdr.fSample/1000);
step_samp  = round(step_ms*hdr.fSample/1000);
state=[]; % for the buffer_newevents waiting for exit event
nEvents=hdr.nEvents; nSamples=hdr.nSamples; % current number events/samples
endTest=false;
while( ~endTest )
  % block until new data to process
  status=buffer('wait_dat',[nSamples+trlen_samp -1 timeout_ms],buffhost,buffport);
  if ( status.nsamples < nSamples ) 
    fprintf('Buffer restart detected!'); 
    nSamples=status.nsamples;
    continue;
  end
  if ( ispc() ) drawnow; end;
  
  % get the data
  data = buffer('get_dat',[nSamples nSamples+trlen_samp-1],buffhost,buffport);
  
  % apply classification pipeline to this events data
  [f,fraw,p]=buffer_apply_ersp_clsfr(data.buf,clsfr);    
  % Send prediction event when wanted
  sendEvent('stimulus.prediction',f);
  
  % check for exit events -- any event with t:stimulus.testing v:end
  [devents,state]=buffer_newevents(buffhost,buffport,state,'stimulus.testing','end',0);
  if ( numel(devents)>0 ) 
    fprintf('Got exit event. Stopping'); endTest=true; 
  end;
end % while not finished
