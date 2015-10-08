function [n]=coloredNoise(sz,spect,dim)
% Function go generate noise with the indicated spectrum.
% Inputs
%  sz    -- the size of the noise matrix wanted.
%  spect -- the spectrum wanted, should be a [M x 1] vector
%  dim   -- the dimension of sz along which the spectrum is measured
% Ouputs
%  n     -- the output noise
%
% Example:
%  n = coloredNoise(1000,1./[1:100]);
if ( nargin < 3 || isempty(dim) ) dim=find(sz>1,1);if(isempty(dim))dim=1;end;end; % 1st non singlenton

if ( numel(sz) < 2 )    sz   =[sz 1]; end;
if ( numel(spect)==1 ) spect=spect*ones(1,ceil(sz(dim)/2)); end;
if ( size(spect,1)==1 ) spect=spect'; end;
if ( numel(spect)~=ceil(sz(dim)/2) ) 
   spect=oversample(spect,ceil(sz(dim)/2),'linear'); 
end;

n  = randn(sz);  % white noise
Fn = fft(n,[],dim);
ss = shiftdim([spect;zeros(mod(sz(dim)+1,2),1);spect(end:-1:2)],-dim+1);
Fn = repop(Fn,'.*',ss);
n  = ifft(Fn,[],dim);
return

function [yi]=oversample(y,N,intType)
% Simple oversampling function with either nearest neighbour or linear
% value interplotation
if ( size(y,1)==1 ) y=y'; end;
xs=linspace(0.5,numel(y)+.5-1e-6,N)'; % New sample locations
switch ( lower(intType) ) 
   case 'nn'; yi=y(round(xs)); % Nearest Neighbour
   case 'linear';  % Linear interpolation
   yi=y(max(floor(xs),1)).*(ceil(xs)-(xs))+...
      y(min(ceil(xs),numel(y))).*((xs)-floor(xs));
   otherwise; error('Unknown resample type: %s',intType);
end


%-------------------------------------------------------------------
function testcase()
n=coloredNoise(1000,1); 
n=coloredNoise(1000,1./[1:100]); 
n=coloredNoise(1000,1./[1:500].*[zeros(1,100) ones(1,300) zeros(1,100)]);
n=coloredNoise(1001,1); 
n=coloredNoise(1001,1./[1:100]); 
n=coloredNoise(1001,1./[1:500].*[zeros(1,100) ones(1,300) zeros(1,100)]);

plot(abs(fft(n)));