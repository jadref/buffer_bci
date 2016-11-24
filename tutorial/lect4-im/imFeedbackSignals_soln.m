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


%load the saved classifier
clsfr=load('clsfr');
if ( isfield(clsfr,'clsfr') ) clsfr=clsfr.clsfr; end; % check is saved variable or struc

% call the feedback signals function to do the classifier application
[testdata,testevt]=imFeedbackSignals(clsfr);

