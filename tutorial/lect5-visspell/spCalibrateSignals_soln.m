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
initgetwTime;
initsleepSec;

verb=1;
trlen_ms=600;
dname='calibrate_data';

[data,devents,state]=buffer_waitData(buffhost,buffport,[],'startSet',{{'stimulus.tgtFlash'}},'exitSet',{'stimulus.training' 'end'},'verb',verb,'trlen_ms',trlen_ms);
mi=matchEvents(devents,'stimulus.training','end'); devents(mi)=[]; data(mi)=[]; % remove the exit event
fprintf('Saving %d epochs to : %s\n',numel(devents),dname);
save('calibrate_data','data','devents');
