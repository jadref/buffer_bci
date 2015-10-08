function X=mkSig(T,sigType,varargin)
% make different types of toy signal
%
% X=mkSig(T,sigType[,param1,param2,...])
%
% Inputs:
%  T -- [1x1] number of samples to generate
%  sigType -- (string) type of signal to generate.  one of:
%           'none',
%           'rand'         ()
%           'randn'        ()
%           'coloredNoise' (noiseSpectrum) 
%           'saw'          (period)
%           'square'       (period)
%           'triangle'     (period)
%           'sin'          (period phase periodJitter phaseJitter) % phase in radians
%           'repeated'     (1_cycle_signal cycleLen interpType)
%           'amsig'        (amplitudeModulator sigType param1,param2,...)
%           'gaussian'     (mean std-dev meanJitter stdJitter)
%           'exp'          (decayConst)
%           'sum'          (sig1 sig2)
%           'prod'         (sig1 sig2)
%           'unitPow'      (sig1) % make sig1 have unit power
%           'randSig'      (Pr sig) % sig occurs with probability Pr
%           function handle -- called as: feval(sigType,T,parm1,parm2,...)
% Output:
%  X -- [Tx1] signal of the requested type
%
% Example: 
%    X = mkSig(100,'coloredNoise',[10 10 8 6 4 2]); % 1/f noise signal
%    X = mkSig(100,'sin',25); % period 25 sinusoid
%  %1/f noise with weak embedded sinusoid
%   X = mkSig(1000,'coloredNoise',[1:20].^-1)*1 + mkSig(1000,'sin',25)*.1;
%  %exp-decay (half-life=10) sinusoid with period 8
%   X = mkSig(100,'prod',{'exp' log(2)./10},{'sin' 8});
if ( nargin<2 ) sigType='none'; end;
if ( isnumeric(sigType) ) 
   X = sigType;
   if ( numel(X)==1 ) X(end+1:T,1)=X;
   elseif ( numel(X)~= T ) warning('Zero-padded the signal'); X(end+1:T)=0; 
   end;
   return;
end;
if ( iscell(sigType) && numel(sigType)==1 ) sigType=sigType{1}; end;
if ( iscell(sigType) && numel(sigType)>1 && isempty(varargin) )  varargin=sigType(2:end); sigType=sigType{1}; end;

switch sigType;
 case 'none';        X = zeros(T,1);
 case 'rand';        X = rand(T,1);
 case 'randn';       X = randn(T,1);
 case 'coloredNoise';X = coloredNoise(T,varargin{:});
 case 'saw';         X = repeated(T,oversample([-1 0 1]',varargin{1},[],'linear'));
 case 'triangle';    X = repeated(T,oversample([-1 1 -1]',varargin{1},[],'linear'));
 case 'square';      X = repeated(T,oversample([-1 1]',varargin{1},[],'nn'));
 case 'repeated';    X = repeated(T,oversample(varargin{:}));
 case 'sin';         X = noisySin(T,varargin{:}); % N.B. pow=(Amp.^2)/2
 case 'cos';         X = noisyCos(T,varargin{:}); % N.B. pow=(Amp.^2)/2
 case {'gaussian','gaus'};    X = noisyGaus(T,varargin{:});
 case 'exp';         X = exp(-(0:T-1)*varargin{1})';
 case 'amsig';       X = oversample(varargin{1},T,[],'linear').*mkSig(T,varargin{2:end});
 case 'sum';         X = mkSig(T,varargin{1}{:}) + mkSig(T,varargin{2}{:});
 case 'prod';        X = mkSig(T,varargin{1}{:}) .* mkSig(T,varargin{2}{:});
 case 'stretch';     X = oversample(varargin{1},T,[],'lin'); X=X(:); % ensure out is colvec
 case 'unitPow';     X = mkSig(T,varargin{:}); pow=(X'*X)./T; if(pow>0)X=X./sqrt(pow); end; % unitPower signal
 case 'randSig';     X = randSig(T,varargin{:}); % randomly occuring signal
 otherwise; 
  % assume its a function name to call
  if ( exist(sigType) || isa(sigType,'function_handle') ) 
     X = feval(sigType,T,varargin{:})
  else
     error('Unrecognised signal type: %s',sigType);
  end
end
return;

%------------------------------------------
function [X]=noisyCos(T,period,phase,periodStd,phaseStd)
% Noisy sinusoid function with gaussian noise about the def period / phase
if ( nargin<3 ) phase=0; end;
if ( nargin<4 ) periodStd=0; end;
if ( nargin<5 ) phaseStd=0; end;
X = noisySin(T,period,phase+pi/2,periodStd,phaseStd);

%------------------------------------------
function [X]=noisySin(T,period,phase,periodStd,phaseStd)
% Noisy sinusoid function with gaussian noise about the def period / phase
if ( nargin<3 ) phase=0; end;
if ( nargin<4 ) periodStd=0; end;
if ( nargin<5 ) phaseStd=0; end;
% don't mess the rand number state unless needed
if ( any(periodStd~=0) ) 
  if ( numel(periodStd)==1 ) period=period+periodStd(1)*randn(1,1); 
  elseif ( numel(periodStd)==2 ) period=period+periodStd(1)*randn(T,1); % cont vary phase
  elseif ( numel(periodStd)==T ) period=period+periodStd;
  end;
end;
if ( any(phaseStd~=0) )
  if ( numel(phaseStd)==1 )     phase=phase+phaseStd(1)*randn(1,1); 
  elseif ( numel(phaseStd)==2 ) phase=phase+phaseStd(1)*randn(T,1); % cont vary phase
  elseif ( numel(phaseStd)==T ) phase=phase+phaseStd;
  end;
end
X = sin(cumsum([0;ones(T-1,1)]*2*pi./period)+phase);

%------------------------------------------
function [X]=noisyGaus(T,mu,sigma,muJitter,sigmaJitter)
% Noisy sinusoid function with gaussian noise about the def period / phase
if ( nargin<2 ) mu=(T-1)/2; end;
if ( nargin<3 ) sigma=T/5; end;
if ( nargin<4 ) muJitter=0; end;
if ( nargin<5 ) sigmaJitter=0; end;
if ( muJitter~=0 )   mu   =mu+muJitter*randn(1); end
if ( sigmaJitter~=0) sigma=sigma+sigmaJitter*randn(1); end;
X = exp(-.5*(([0:T-1]'-mu)./sigma).^2);

%------------------------------------------
function [X]=repeated(T,cycle)
% repeat the input 1 period to the desired length
X = cycle(mod(0:T-1,end)+1);

%----------------------------------------------------------------------------
function [x]=randSig(T,Pr,varargin)
% noisy signal, occurs with probability Pr
if ( rand(1,1)<Pr )
  x = mkSig(T,varargin{:});
else
  x = zeros(T,1);
end
return;


%----------------------------------------------------------------------------
function testCase();
plot(mkSig(101,'sin',5,0,0,0))
plot(mkSig(101,'saw',5,0,0,0))
plot(mkSig(101,'square',5,0,0,0))
plot(mkSig(101,'coloredNoise',5))
plot(mkSig(101,'gaussian',50,5,0,0))
