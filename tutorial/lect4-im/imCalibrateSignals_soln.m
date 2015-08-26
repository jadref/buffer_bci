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

trialDuration=3;
trlen_ms=trialDuration*1000;
dname  ='training_data';
cname  ='clsfr';

% Grab 600ms data after every stimulus.target event
[data,devents,state]=buffer_waitData(buffhost,buffport,[],'startSet',{{'stimulus.target'}},'exitSet',{'stimulus.training' 'end'},'verb',verb,'trlen_ms',trlen_ms);
mi=matchEvents(devents,'stimulus.training','end'); devents(mi)=[]; data(mi)=[]; % remove the exit event
fprintf('Saving %d epochs to : %s\n',numel(devents),dname);
save(dname,'data','devents');

