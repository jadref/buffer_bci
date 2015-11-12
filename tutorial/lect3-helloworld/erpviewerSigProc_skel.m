try; cd(fileparts(mfilename('fullpath')));catch; end;
run ../../utilities/initPaths.m
  
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

% load the cap layout from file
[ch_names latlong ch_pos ch_pos3d]=readCapInf('1010');

trlen_samp = 50; % #samples per epoch
nSymbols = 2;
% initialize the information we store about the class averages
erp      = zeros(sum(iseeg),trlen_samp,nSymbols);
nTarget  = zeros(nSymbols,1);

% make the figure window
clf;
hdls=image3d(erp,1,'plotPos',ch_pos,'xlabel','ch','Xvals',ch_names,'zlabel','class','disptype','plot','ticklabs','sw');


% ----------------------------------------------------------------------------
%    FILL IN YOUR CODE BELOW HERE
% ----------------------------------------------------------------------------

state=[];

% block until we've got new events *and* data to process
[data,devents,state]=buffer_waitData([],[],state,'startSet',{'stimulus.epoch'},'trlen_samp',trlen_samp,'exitSet',{'data' 'stimulus.sequences' 'end'});

% loop over all matching events and data
for ei=1:numel(devents)
  % update the class averages
  %...?
  evt=devents(ei); % this events info
  dat=data(ei);  % and associated data
end

% update the ERP plot
hdls=image3d(erp,1,'handles',hdls,'xlabel','ch','Xvals',ch_names,'zlabel','class','disptype','plot','ticklabs','sw');
drawnow;    
