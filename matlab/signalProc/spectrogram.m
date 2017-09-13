function [X,start_samp,freqs,winFn,opts,width_samp]=spectrogram(X,dim,varargin);
% compute the spectrogram of the input X using the STFW method
%
%  [X,start_samp,freqs,winFn,opts]=spectrogram(X,dim,varargin)
%
% Inputs:
%  X - [n-d] the data to spectrogram
%  dim - [int] the dimension of X along which time lies
% Options:
%  fs - [float] the sampling rate of X
%  windowType - [str] the type of temporal windowing function to use         ('hamming')
%  nwindows   - [int] the number of windows to use                               ([])
%  overlap    - [float] the fractional overlap of the time windows               (.5)
%  width_ms/width_samp - [float] window width in milli-seconds/samples           (500)
%  start_ms/start_samp - [float] window start positions in milli-seconds/samples ([])
%  step_ms/step_samp   - [float] time between window starts in milli-seconds/samples ([])
%  center     - [bool] center in time before computing the spectrum              (0)
%  detrend    - [bool] detrend before computing the spectrum                     (1)
%  feat       - [str] type of feature to compute, one-of:                      ('amp')
%                    'complex' - normal fourier coefficients
%                    'l2'      - squared length of the complex coefficient
%                    'abs','amp'- absolute length of the coefficients
%                    'angle'   - angle of the complex coefficient
%                    'real'    - real part
%                    'imag'    - imaginary part
%                    'db'      - decibles, ie. 10*log10(F(X).^2)
% Outputs:
%  X -- [ndims(X)+1] output spectrogram, with windows in dim+1, i.e. dim=freq, dim+1=time
%  start_samp -- [nWin x 1] window start locations in samples
%  freqs      -- [nFreq x 1] set of frequencies
%  winFn      -- [width x 1] window applied to the time-domain signal before FFT transformation
%  opts       -- [struct] options structure
opts=struct('fs',[],'log',0,...
            'feat','amp',...
            'center',0,'detrend',1,...
            'windowType','hamming',...
            'nwindows',[],'overlap',.5,'step_samp',[],'step_ms',[],... % spec windows as # and overlap
            'width_ms',500,'width_samp',[],... % spec as start+width
            'start_ms',[],'start_samp',[],...
            'verb',0);
opts=parseOpts(opts,varargin);

dim(dim<0)=dim(dim<0)+ndims(X)+1; % convert neg dim specs
nSamp=size(X,dim);

% convert win-specs from time to samples if necessary
fs=opts.fs;
if ( isempty(opts.width_samp) && ~isempty(opts.width_ms) ) 
  if ( isempty(fs) ) warning('Unknown sample rate, fs=1 assumed'); fs=1; end;
  ms2samp = fs/1000; opts.width_samp=floor(opts.width_ms*ms2samp); 
end;
if ( isempty(opts.start_samp) && ~isempty(opts.start_ms) ) 
  if ( isempty(fs) ) warning('Unknown sample rate, fs=1 assumed'); fs=1; end;  
  ms2samp = fs/1000; opts.start_samp=floor(opts.start_ms*ms2samp); 
end;
if ( isempty(opts.step_samp) && ~isempty(opts.step_ms) ) 
  if ( isempty(fs) ) warning('Unknown sample rate, fs=1 assumed'); fs=1; end;
  ms2samp = fs/1000; opts.step_samp=floor(opts.step_ms*ms2samp); 
end;
[start_samp width_samp]=compWinLoc(nSamp,opts.nwindows,opts.overlap,opts.start_samp,opts.width_samp,opts.step_samp);
opts.nwindows=numel(start_samp);opts.start_samp=start_samp;opts.width_samp=width_samp;
opts.overlap =(numel(start_samp).*width_samp)./nSamp; % amount of overlap in the windows

% do the actual spectrum computation
winFn=[]; 
if ( ~isempty(opts.windowType) && ~isequal(opts.windowType,1) ) 
  winFn = mkFilter(width_samp,opts.windowType);
end;
X     = windowData(X,start_samp,width_samp,dim);
% Compute the normalized spectrum on these windows individually [nCh x nFreq x nWin x N]
X     = fft_posfreq(X,[],dim,opts.feat,winFn,opts.detrend,opts.center,[0 0],[],opts.verb);
% correct for the power-increase due to the overlapping windows, and convert to power/sample
st =size(X,dim); if( ~isempty(winFn) ) st=sum(winFn); end;
X     = X.*sqrt(2)./st; % convert to per-sample value
if ( nargout > 2 ) freqs = fftBins(width_samp,[],fs,1); end;
return;
%--------------------------------------------------------------------------
function testCase()
X=cumsum(randn(10,100,100),2);
[Xspect,times,freqs]=spectrogram(X,2); % 12 win @ .5 overlap

spectrogram(X,2,'nwindows',8); % 8 win @ .5 overlap
spectrogram(X,2,'width_samp',100); % 100 samp wide @ .5 overlap
spectrogram(X,2,'start_samp',1:100:size(X,2));%start 100 samp @ .5 overlap
spectrogram(X,2,'start_samp',1:100:size(X,2),'width_samp',150);
spectrogram(X,2,'width_ms',500,'feat','complex'); % complex outputs

% check preserves the covariance structure - when just re-rep the data
[Xspect]=spectrogram(X,2,'windowType',1,'overlap',0,'feat','complex','detrend',0,'center',0);
mad(X*X',real(Xspect(:,:)*Xspect(:,:)'))
% when temporally over-sample the data
[Xspect]=spectrogram(X,2,'windowType',1,'nwindows',20,'overlap',.5,'feat','complex','detrend',0,'center',0);
mad(X*X',real(Xspect(:,:)*Xspect(:,:)'))
clf;mimage(X*X',real(Xspect(:,:)*Xspect(:,:)'),'diff',1,'clim',[],'colorbar',1);
% when include a hanning taper
[Xspect]=spectrogram(X,2,'overlap',.5,'windowType','hanning','feat','complex','detrend',0,'center',0);
% other tapers
[Xspect]=spectrogram(X,2,'overlap',.5, 'windowType','hamming','feat','complex','detrend',0,'center',0);
[Xspect]=spectrogram(X,2,'overlap',.5, 'windowType','bartlet','feat','complex','detrend',0,'center',0);
[Xspect]=spectrogram(X,2,'overlap',.37,'windowType','blackman','feat','complex','detrend',0,'center',0);
[Xspect]=spectrogram(X,2,'overlap',.46,'windowType','kaiser','feat','complex','detrend',0,'center',0);
mad(X*X',real(Xspect(:,:)*Xspect(:,:)'))



% compare spectrogram and windowed welch
X=cumsum(randn(10,2000,1));
S=spectrogram(X,2,'width_samp',1000,'step_samp',500);

% window and welch manually
[start_samp width_samp]=compWinLoc(size(X,2),[],[],[],1000,500);
w=windowData(X,start_samp,width_samp,2);wW=welchpsd(w,2,'width_samp',1000);
mad(S,wW)
clf;mimage(S,wW,'divide',1,'clim',[],'colorbar',1)

% welch the whole thing directly
W=welchpsd(X,2,'width_samp',1000,'step_samp',500);
mad(W,sum(S,3)./size(S,3))
clf;mimage(W,sum(S,3)./size(S,3),'divide',1,'clim',[],'colorbar',1)
