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
initgetwTime;
initsleepSec;

% load the cap layout from file
[ch_names latlong ch_pos ch_pos3d]=readCapInf('1010');
% mark only num-channels send by amp as EEG and to-be plotted
iseeg=false(size(ch_names));iseeg(1:numel(hdr.labels))=true; 

trlen_samp = 50; % #samples per epoch
nSymbols = 2;
erp      = zeros(sum(iseeg),trlen_samp,nSymbols);
nTarget  = zeros(nSymbols,1);

% make the figure window, but only for the channels which are actually EEG channels
clf;
hdls=image3d(erp,1,'plotPos',ch_pos(:,iseeg),'xlabel','ch','Xvals',ch_names(iseeg),'zlabel','class','disptype','plot','ticklabs','sw');

state=[];
endTest=false; 
while( ~endTest )
  % block until we've got new events *and* data to process
  [data,devents,state]=buffer_waitData([],[],state,'startSet',{'stimulus.epoch'},'trlen_samp',trlen_samp,'exitSet',{'data' 'stimulus.sequences' 'end'});

  for ei=numel(devents):-1:1; % process in reverse order = temporal order
    event=devents(ei);
    % check for exit events
    if( isequal('stimulus.sequences',event.type) && isequal('end',event.value) ) % end event
      endTest=true; 
      fprintf('Discarding all subsequent events: exit\n');
      break;
    end;

    % update the ERPs info
    class=devents(ei).value; % WARNING: here we assume event value is integer class ID
    erp(:,:,class) = (erp(:,:,class)*nTarget(class) + data.buf(iseeg,:))/(nTarget(class)+1);
    nTarget(class) = nTarget(class)+1;        
    
    % update the ERP plot
    hdls=image3d(erp,1,'handles',hdls,'xlabel','ch','Xvals',ch_names,'zlabel','class','disptype','plot','ticklabs','sw');
    drawnow;    
  end % for ei=1:numel(devents)
end
