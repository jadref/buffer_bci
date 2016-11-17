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

trlen_ms=600;
% ----------------------------------------------------------------------------
%    FILL IN YOUR CODE BELOW HERE
% ----------------------------------------------------------------------------

% useful functions.... how about 
[data,devents,state]=buffer_waitData(buffhost,buffport,[],'startSet',???,'trlen_ms',trlen_ms,'exitSet',???)
% don't forget to remove the final exit event before saving the data!

