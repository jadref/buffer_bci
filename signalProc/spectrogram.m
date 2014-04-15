function [X,start_samp,freqs,opts]=spectrogram(X,dim,varargin);
% compute the spectrogram of the input X using the STFW method
%
%  [X,start_samp,freqs,opts]=spectrogram(X,dim,varargin)
%
% Inputs:
%  X - [n-d] the data to spectrogram
%  dim - [int] the dimension of X along which time lies
% Options:
%  fs - [float] the sampling rate of X
%  windowType - [str] the type of temporal windowing function to use ('hanning')
%  nwindows   - [int] the number of windows to use (12)
%  overlap    - [float] the fractional overlap of the time windows (.5)
%  width_ms/width_samp - [float] window width in milli-seconds/samples ([])
%  start_ms/start_samp - [float] window start positions in milli-seconds/samples ([])
%  center     - [bool] center in time before computing the spectrum
%  detrend    - [bool] detrend before computing the spectrum
% Outputs:
%  X -- [ndims(X)+1] output spectrogram, with windows in dim+1, i.e. dim=freq, dim+1=time
%  start_samp -- [nWin x 1] window start locations in samples
%  freqs      -- [nFreq x 1] set of frequencies
%  opts       -- [struct] options structure
opts=struct('fs',[],'log',0,...
            'center',0,'detrend',1,...
            'windowType','hanning',...
            'nwindows',12,'overlap',.5,... % spec windows as # and overlap
            'width_ms',[],'width_samp',[],... % spec as start+width
            'start_ms',[],'start_samp',[],...
            'verb',0);
opts=parseOpts(opts,varargin);
   
dim(dim<0)=dim(dim<0)+ndims(X)+1; % convert neg dim specs

% convert win-specs from time to samples if necessary
fs=opts.fs; if ( isempty(fs) ) fs=1; end;
if ( isempty(opts.width_samp) ) 
   ms2samp = fs/1000; opts.width_samp=floor(opts.width_ms*ms2samp); 
end;
if ( isempty(opts.start_samp) ) 
   ms2samp = fs/1000; opts.start_samp=floor(opts.start_ms*ms2samp); 
end;
[start_samp width_samp]=compWinLoc(size(X,dim),opts.nwindows,opts.overlap,opts.start_samp,opts.width_samp);
opts.nwindows=numel(start_samp);opts.start_samp=start_samp;opts.width_samp=width_samp;

% do the actual spectrum computation
winFn=[]; 
if ( ~isempty(opts.windowType) ) 
  winFn = mkFilter(width_samp,opts.windowType); nF=sum(winFn);
else
  winFn=[]; nF=width_samp;
end;
X     = windowData(X,start_samp,width_samp,dim);
X     = fft_posfreq(X,[],dim,'abs',winFn,opts.detrend,opts.center,0,[],opts.verb);  % nCh x nFreq x nWin x N
X     = X./nF; % map to average power per sample
if ( opts.log ) X(X(:)==0)=eps; X=20*log10(X); end;
if ( nargout > 2 ) freqs = fftBins(width_samp,[],fs,1); end;
return;
%--------------------------------------------------------------------------
function testCase()
