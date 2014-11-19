run ../../utilities/initPaths.m;

% N.B. only really need the header to get the channel information, and sample rate
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

% Constants
capFile='cap_tmsi_mobita_im.txt';
overridechnm=1; % capFile channel names override those from the header!
dname  ='training_data';
cname  ='clsfr';

%useful functions
load(dname);
% train classifier
clsfr=buffer_train_ersp_clsfr(data,devents,hdr,'spatialfilter','slap','freqband',[6 10 26 30],'badchrm',0,'capFile',capFile,'overridechnm',overridechnm);
fprintf('Saving classifier to : %s\n',cname);
save(cname,'-struct','clsfr');
sendEvent('phase.training','start');
