function [start width]=compWinLoc(N,nwindows,overlap,start_samp,width_samp,step_samp)
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
%  step_samp  -- [1x1] step between window starts in samples 
if ( nargin < 3 ) overlap=[]; end;
if ( nargin < 4 ) start_samp=[]; end;
if ( nargin < 5 ) width_samp=[]; end;
if ( nargin < 6 ) step_samp=[]; end;
% Convert input spects to window start/width pairs
if ( ~isempty(width_samp) && ~isempty(start_samp) ) % use start + width
   width = width_samp;
   start = start_samp; 
elseif ( ~isempty(width_samp) && ~isempty(step_samp) ) % use width and step
   width = width_samp;
   start = round(0:step_samp:max(0,N-width))'+1;   
elseif ( isempty(width_samp) && isempty(start_samp) && ~isempty(nwindows) && ~isempty(overlap) ) % use #win + overlap
   width = floor(N/((nwindows-1)*(1-overlap)+1));
   start = round(0:width*(1-overlap):max(0,N-width))'+1;   
elseif ( ~isempty(width_samp) && ~isempty(nwindows) ) % use width + nwindows  (windows overrides overlap)
   width = width_samp;
   start = round(linspace(0,max(0,N-width),nwindows)'+1);
elseif ( ~isempty(width_samp) && ~isempty(overlap) ) % use width + overlap
   width = width_samp;
   start = round(0:width*(1-overlap):max(0,N-width))'+1;
	if ( N-(start(end)+width*(1-overlap))>.9*width )% miss almost a whole window, tweak overlap to make fit
	  start = round(linspace(0,N-width,numel(start)+1))+1;
	end
elseif ( ~isempty(start_samp) && ~isempty(overlap) ) % use start + overlap
   if( ~all(abs(diff(diff(start_samp,1)))<=1) ) warning('Start should be equally spaced'); end;
   start = start_samp;
   width = round(mean(diff(start,1))*(1+overlap));
else
   warning('Couldnt determine the window locations -- using single window');
   start = 1;  width=N;
end
% treat start as start point only
if ( numel(start)==1 )
  if ( ~isempty(overlap) ) % non-1 start point
    start = round(start-1:width*(1-overlap):max(0,N-width))'+1;
  elseif ( ~isempty(step_samp) )
    start = round(start-1:step_samp:max(0,N-width))'+1;
  elseif ( ~isempty(nwindows) )
	 start = round(linspace(start,max(0,N-width),nwindows)')+1;
  end
end
return;
%-----------------------------------------------------
function testcases()

[s,w]=compWinLoc(100,[],.5,[],10); % overlap+width (welch,spectrogram)
[s,w]=compWinLoc(100,19,[],[],10); % nwin+width
[s,w]=compWinLoc(100,19,.5,[],[]); % nwin+overlap
[s,w]=compWinLoc(100,19,.5,[],[]); % nwin+overlap
[s,w]=compWinLoc(100,[],[],[],10,5); % nwin+overlap
