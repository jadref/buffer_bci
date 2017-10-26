% call the below function to do the actual work....
try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end

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

trlen_ms=3000;

%load the saved classifier
clsfr=load('clsfr');
if ( isfield(clsfr,'clsfr') ) clsfr=clsfr.clsfr; end; % check is saved variable or struc

state=[]; 
endTest=false;
while ( ~endTest )
  % wait for data to apply the classifier to
  [data,devents,state]=buffer_waitData(opts.buffhost,opts.buffport,state,'startSet',{'stimulus.trial','start'},'trlen_ms',trlen_ms,'exitSet',{'data' {'stimulus.testing'}});
  
  % process these events
  for ei=1:numel(devents)
    if ( strcmp(events.type,'stimulus.training') )
      endTest=True;
    else
      % apply classification pipeline to this events data
      [f,fraw,p]=buffer_apply_ersp_clsfr(data(ei).buf,clsfr);
      sendEvent('classifier.prediction',f,devents(ei).sample);
    end
  end % devents 
end 
