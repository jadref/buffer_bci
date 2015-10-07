function [W,opts,winFn]=welchpsd(X,dim,varargin);
% compute the power-spectral-density of the input X using welch's method
%
% [W,opts]=welchpsd(X,dim,varargin)
%
% Inputs:
%  X          -- [n-d] the data vector to compute the PSD
%  dim        -- [int] the dimension of X to compute the PSD along (i.e. time dimension) (1st non-singelton dim)
% Options: (N.B. just as passed to windowData)
%  windowType -- type of time windowing to use ('hanning')
%  nwindows   -- number of windows to use      
%  overlap    -- fractional overlap of windows (.5)
%  width_{ms,samp} -- window width in millisec or samples
%  width_hz        -- specify desired frequency resolution and compute required window width ([])
%  start_{ms,samp} -- window start locations in millisec or samples
%  end_{ms,samp}   -- windows end location in millisec or samples
%  fs         -- sampling rate of the data (only needed is spec with _ms) ([])
%  verb       -- verbosity level (0)
%  center     -- [bool] center the data before fft'ing? (1)
%  detrend    -- [bool] remove linear trends before fft'ing (0)
%  aveType    -- 'str' one of:                              ('amp')
%                'amp' - ave amplitude, 'power' - ave power, 'db' - ave db
%  outType    -- 'str' type of output to produce.  one of:
%                'amp' - ave amp, 'power' - ave power, 'db' - ave db
%  MAXEL      -- max number of elements to run at a time in chunking code
% Output
%  W          -- [size(X)] the power spectrum of the input data
%  opts       -- the options structure used for this call
%  winFn      -- [size(X,dim) x 1] the temporal window used
opts=struct('fs',[],'aveType',[],'outType',[],...
            'center',0,'detrend',1,...
            'windowType','hanning',...
            'nwindows',[],'overlap',.5,... % spec windows as # and overlap
            'width_ms',500,'width_samp',[],... % spec as start+width
            'width_hz',[],...
            'start_ms',[],'start_samp',[],...
            'end_ms',[],'end_samp',[],...            
            'verb',0,'MAXEL',2e6);
opts=parseOpts(opts,varargin);
MAXEL=opts.MAXEL;
if ( isempty(opts.aveType) ) 
   if ( ~isempty(opts.outType) ) opts.aveType=opts.outType; 
   else  opts.aveType='amp';opts.outType=opts.aveType;
   end;
end;

if ( nargin<2 || isempty(dim) ) % use 1st non-singlenton dimension
  dim = find(size(X)>1);
end
dim(dim<0)=dim(dim<0)+ndims(X)+1; % convert neg dim specs

% extract window size from given window function
if(~ischar(opts.windowType) && isempty(opts.width_samp) ) opts.width_samp=numel(opts.windowType); end; 

% convert win-specs from time to samples if necessary
ms2samp=[]; if (~isempty(opts.fs)) ms2samp=opts.fs./1000; end;
if ( isempty(opts.width_samp) )
  if ( ~isempty(opts.width_ms) )   opts.width_samp = min(size(X,dim(1)),floor(opts.width_ms*ms2samp)); 
  elseif( ~isempty(opts.width_hz)) opts.width_samp = min(size(X,dim(1)),floor(1000./opts.width_hz*ms2samp));
  else  error('No window width specified');
  end;
end
if ( isempty(opts.start_samp) )    opts.start_samp = floor(opts.start_ms*ms2samp); end;
if ( ~isempty(opts.end_samp) || ~isempty(opts.end_ms) )     
  end_samp=opts.end_samp; if ( isempty(end_samp) ) end_samp = floor(opts.end_ms*ms2samp); end;
  if ( isempty(opts.nwindows) ) opts.nwindows= ceil((end_samp-opts.start_samp(1))/opts.width_samp); end;
end;
[start width]=compWinLoc(size(X,dim),opts.nwindows,opts.overlap,opts.start_samp,opts.width_samp);
opts.nwindows=numel(start);opts.start_samp=start;opts.width_samp=width;

% do the actual welch PSD estimate computation
sz = size(X);
winFn = shiftdim(mkFilter(width,opts.windowType),-dim+1); % window to use
W = zeros([sz(1:dim-1) ceil((width-1)/2)+1 sz(dim+1:end)],class(X));

% chunking computation -- to save memory
[idx,allStrides,nchnks]=nextChunk([],sz,dim,MAXEL);
ci=0; if ( opts.verb >= 0 && nchnks>1 ) fprintf('Welch PSD:'); end;
while ( ~isempty(idx) )

   % do this chunk
   Widx = idx; Widx{dim}=1:size(W,dim);
   W(Widx{:}) = welch(X(idx{:}),winFn,dim,start,width,opts.center,opts.detrend,opts.aveType);
   
   % get next chunk
   idx=nextChunk(idx,size(X),allStrides); ci=ci+1;
   if ( opts.verb >=0 ) ci=ci+1; textprogressbar(ci,nchnks);  end
end
if ( opts.verb>=0 && nchnks>1) fprintf('done\n'); end;
return;

%-------------------------------------------------------------------------------
function [W]=welch(X,taper,dim,start,width,centerp,detrendp,outType)
% Inner loop code to do the actual welch computation
if ( isempty(outType) ) outType='amp'; end;
sz=size(X);
W = zeros([sz(1:dim-1) ceil((width-1)/2)+1 sz(dim+1:end)],class(X));
idx={}; for di=1:ndims(X); idx{di}=1:size(X,di); wIdx{di}=1:size(W,di); end;
for wi=1:numel(start);
   idx{dim} = start(wi)+(0:width-1);      % get the samples we need
   wX       = X(idx{:});
   if (centerp) wX=repop(wX,'-',mean(wX,dim)); end; % center
   if (detrendp)wX=detrend(wX,dim);            end; % detrend
   wX       = repop(wX,'.*',taper);        % window
   wX       = fft(wX,[],dim);              % fourier
   wX       = wX(wIdx{:});                 % positive freq only
   wX       = 2*(real(wX).^2 + imag(wX).^2); % map to power
   switch(lower(outType));
    case 'db';     wX(wX==0)=eps; W = W + 10*log10(wX); % map to db
    case 'power';  W = W + wX;                          % map to power
    case 'amp';    W = W + sqrt(wX);                    % map to amplitudes
    otherwise;     warning('Unrecognised welch output type: %s',outType);
   end
 end
% total sample weighting, taking account of overlap of weighting functions
W=W./(numel(start)*sum(taper));
return;

%--------------------------------------------------------------------------
function testCase()
W=welchpsd(X,2);
mimage(shiftdim(W,1))
