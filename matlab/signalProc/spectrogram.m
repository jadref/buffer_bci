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
%  feat       - [str] type of feature to compute, one-of:                      ('abs')
%                    'complex' - normal fourier coefficients
%                    'l2'      - squared length of the complex coefficient
%                    'abs'     - absolute length of the coefficients
%                    'angle'   - angle of the complex coefficient
%                    'real'    - real part
%                    'imag'    - imaginary part
%                    'db'      - decibles, ie. 10*log10(F(X).^2)
% Outputs:
%  X -- [ndims(X)+1] output spectrogram, with windows in dim+1, i.e. dim=freq, dim+1=time
%  start_samp -- [nWin x 1] window start locations in samples
%  freqs      -- [nFreq x 1] set of frequencies
%  opts       -- [struct] options structure
opts=struct('fs',[],'log',0,...
            'feat','amp',...
            'center',0,'detrend',1,...
            'windowType','hanning',...
            'nwindows',12,'overlap',.5,... % spec windows as # and overlap
            'width_ms',[],'width_samp',[],... % spec as start+width
            'start_ms',[],'start_samp',[],...
            'verb',0);
opts=parseOpts(opts,varargin);

if ( ~isempty(dim) ) dim(dim<0)=dim(dim<0)+ndims(X)+1; % convert neg dim specs
else                 dim=find(size(X)>1); % first non-singlenton dim
end;

% convert win-specs from time to samples if necessary
fs=opts.fs;
if ( isempty(opts.width_samp) ) 
  if ( isempty(fs) ) warning('Unknown sample rate, fs=1 assumed'); fs=1; end;
  ms2samp = fs/1000; opts.width_samp=floor(opts.width_ms*ms2samp); 
end;
if ( isempty(opts.start_samp) ) 
  if ( isempty(fs) ) warning('Unknown sample rate, fs=1 assumed'); fs=1; end;  
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
X     = fft_posfreq(X,[],dim,opts.feat,winFn,opts.detrend,opts.center,0,[],opts.verb);  % nCh x nFreq x nWin x N
X     = X./nF; % map to average power per sample
if ( nargout > 2 ) freqs = fftBins(width_samp,[],fs,1); end;
return;
%--------------------------------------------------------------------------
function testCase()
s=spectrogram(X,2); % 12 win @ .5 overlap

spectrogram(X,2,'nwindows',8); % 8 win @ .5 overlap
spectrogram(X,2,'width_samp',100); % 100 samp wide @ .5 overlap
spectrogram(X,2,'start_samp',1:100:size(X,2));%start 100 samp @ .5 overlap
spectrogram(X,2,'start_samp',1:100:size(X,2),'width_samp',150);
spectrogram(X,2,'width_ms',500,'feat','complex'); % complex outputs
