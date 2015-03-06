function [start width]=compWinLoc(N,nwindows,overlap,start_samp,width_samp)
% Compute equally spaced windows based on the given specs
%
% [start width]=compWinLoc(N,nwindows,overlap[,start_samp,width_samp])
% Inputs:
%  N          -- [1x1] length of the time course
%  nwindows   -- [1x1] number of windows to cut it up into
%  overlap    -- [1x1] fractional overlap between windows
%  start_samp -- [1x1] index of the start of the 1st window (1)
%                 OR
%                [nwindows x 1] sample number of each window start
%                 OR
%                [nwindows x ...] set of sampled numbers for start each window
%  width_samp -- [1x1] width in elments of the window (comp from nwin+overlap)
if ( nargin < 3 || isempty(overlap) ) overlap=0; end;
if ( nargin < 4 ) start_samp=[]; end;
if ( nargin < 5 ) width_samp=[]; end;
% Convert input spects to window start/width pairs
if ( ~isempty(width_samp) && ~isempty(start_samp) ) % use start + width
   width = width_samp;
   start = start_samp; 
elseif ( isempty(width_samp) && isempty(start_samp) ) % use #win + overlap
   width = floor(N/((nwindows-1)*(1-overlap)+1));
   start = round(0:width*(1-overlap):N-width)'+1;   
elseif ( ~isempty(width_samp) ) % use width + overlap
   width = width_samp;
   start = round(0:width*(1-overlap):N-width)'+1;
elseif ( ~isempty(start_samp) ) % use start + overlap
   if( ~all(abs(diff(diff(start_samp,1)))<=1) ) warning('Start should be equally spaced'); end;
   start = start_samp;
   width = round(mean(diff(start,1))*(1+overlap));
else
   error('Couldnt determine the window locations');
end
% treat start as start point only
if ( numel(start)==1 )
  if ( isempty(nwindows) && ~isempty(overlap) ) % non-1 start point
    start = round(start-1:width*(1-overlap):N-width)'+1;
  elseif ( ~isempty(nwindows) && isempty(overlap) ) % given num windows
    start = round(linspace(start-1,N,nwindows)');
  elseif ( ~isempty(nwindows) && ~isempty(overlap) ) % given max size
    start = start-1+width*(1-overlap)*(0:nwindows-1)'+1;
  end
end
return;
