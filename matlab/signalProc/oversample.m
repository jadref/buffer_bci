function [Y,xs]=oversample(Y,N,dim,intType)
% oversample with nearest neighbour or linear value interplotation
%  [Y]=oversample(Y,N,dim,intType)
%
% Inputs:
%  Y -- [n-d] orginal vector
%  N -- [int] desired output size
%  dim -- [int] dimension of Y to re-size (ndims(Y))
%  type -- [str] oversample type: oneof: 'nn'-nearest neighbour, 'lin'-linear ('nn')
% Outputs:
%  Y -- [size(Y) with size(Y,dim)=N] resized Y
if ( nargin < 4 || isempty(intType) ) intType='nn'; end;
if ( nargin < 3 || isempty(dim) ) dim=ndims(Y); if ( dim==2 && size(Y,dim)==1 ) dim=1; end; end;
if ( nargin < 2 || isempty(N) ) N=size(Y,dim); end;
szY=size(Y); nszY=szY; nszY(dim)=N;
%wdth = (size(Y,dim)-1)/N; xs   = wdth:wdth:size(Y,dim); xs=xs(:);% new sample locations
idx={}; for di=1:ndims(Y); idx{di}=1:size(Y,di); end;
switch ( lower(intType) )
 case {'nn','nearest'}; % Nearest Neighbour  
  xs=linspace(0.5,size(Y,dim)+.5-1e-6,N)'; % New sample locations
  idx{dim}=round(xs); Y=Y(idx{:});
 case {'lin','linear'};  % Linear interpolation
  xs=linspace(1,size(Y,dim),N)'; % New sample locations
  idx2=idx; 
  idx {dim}=max(floor(xs),1);          
  idx2{dim}=min(ceil(xs),size(Y,dim)); 
  Y=repop(Y(idx{:}),'*',shiftdim(ceil(xs)-xs,-dim+1))+...
    repop(Y(idx2{:}),'*',shiftdim(xs-floor(xs)+single(xs==floor(xs)),-dim+1));
 case 'zero'; % only the old sample value is non-zero
  oY=Y; Y=zeros(nszY); idx{dim}=round(idx{dim}*N./szY(dim));
  Y(idx{:})=oY;
 otherwise; error('Unknown resample type: %s',intType);
end
return;
%---------------------------------------------------------------
x=randn(1,100); clf;plot(x,'b-*'); hold on;
[y0,xs]=oversample(x,200,[],'zero');plot(xs,y0,'g.-');
[y1]=oversample(x,200,[],'nn');     plot(xs,y1,'r.-');
[yl]=oversample(x,200,[],'linear'); plot(xs,yl,'c.-');
