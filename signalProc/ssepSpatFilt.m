function [U,s,Xr,covXr,covX]=ssepSpatFilt(X,dim,ref,taus)
% Estimate a spatial filter for a given set of frequencies
%
% [U,s]=ssepSpatFilt(X,dim,ref)
%
% Inputs:
%  X   -- [ch x time x epochs...] the raw data
%  dim -- [2 x 1] the dimensions of X which contain resp. [space, time]   ([1 2])
%               the reference signal is applied along the time-dimension
%               the spatial filter is computed for the space-dimension
%               all other dimensions are averaged over
%  ref -- [size(X,dim(1)) x nRef] the set of reference signals to use
%         OR
%         [1 x nRef] a set of sinusodial periods to use
%  taus -- [nTau x 1] set of time-shifts reference signals to test ([0])
%
% Outputs:
%  U    -- [size(X,dim(1)) x nFilt ] set of spatial filters
%  s    -- [ nFilt x 1 ] eigenvalue for each spatial filter, sorted in *descending* order
%  Xr   -- [ch x ref*taus x epoch] inner product of X with the set of time-shifted reference signals
%  covXr-- [ch x ch x ref*taus] covariance matrix for the time-shifted reference signals
%  covX -- [ch x ch] covariance matrix for the whole data X
if ( nargin<2 || isempty(dim) ) dim=[1 2]; end;
if ( nargin<3 ) ref=[]; error('Insufficient arguments'); end;
if ( nargin<4 || isempty(taus) ) taus=0; end;
if ( size(ref,1)==1 ) % convert from period to sin/cos pairs
  periods=ref; 
  ref=zeros(size(X,dim(2)),numel(periods)*2);
  for ri=1:size(periods,2);
    ref(:,2*ri-1)= sin([0:size(X,dim(2))-1]*2*pi/periods(ri)); ref(:,2*ri-1)=ref(:,2*ri-1)./norm(ref(:,2*ri-1));
    ref(:,2*ri  )= cos([0:size(X,dim(2))-1]*2*pi/periods(ri)); ref(:,2*ri  )=ref(:,2*ri  )./norm(ref(:,2*ri  ));
  end
end

% compute the IP of data with ref-signal
if ( numel(taus)==1 && taus==0 )
  Xr = tprod(X,[1:dim(2)-1 -dim(2) dim(2)+1:ndims(X)],ref,[-dim(2) dim(2)+1:ndims(ref)-1 dim(2)]);
else
  for taui=1:numel(taus);
    reftau = zeros(size(ref)); reftau(taus(taui)+1:end,:)=ref(1:end-taus(taui),:);
    Xr(:,(0:size(ref,2)-1)*numel(taus)+taui)=tprod(X,[1:dim(2)-1 -dim(2) dim(2)+1:ndims(X)],reftau,[-2 2+1:ndims(ref)-1 2]); % [ch x ref*taus]
  end
end
szX=size(X);
% compute cov for each ref-signal
xidx1= -(1:ndims(X)); xidx1(dim(1))=1; xidx1(dim(2))=3; %OP over space, align over ref, IP over rest
xidx2= -(1:ndims(X)); xidx2(dim(1))=2; xidx2(dim(2))=3; 
covXr= tprod(Xr,xidx1,[],xidx2)./prod(szX([1:dim(1)-1 dim(1)+1:end])); %[ ch x ch x ref*taus]
% compute the whole data covariance -- for the noise to suppress
xidx1= -(1:ndims(X)); xidx1(dim(1))=1;  xidx2= -(1:ndims(X)); xidx2(dim(1))=2; % OP over space, IP over rest
covX = tprod(X,xidx1,[],xidx2)./prod(szX([1:dim(1)-1 dim(1)+1:end]));% [ch x ch]
% gen eigen value solver
[U,s]=eig(mean(covXr,3),covX);s=diag(s); [ans,si]=sort(abs(s),'descend'); s=s(si); U=U(:,si);
% pick which components to return
si=~(isnan(s) | isinf(s) | imag(s)~=0 | s<0);
s=s(si); U=U(:,si);
return;

function testCase()
N=100; T=100; 
% simple case with location but varying non-integer frequency
periods=[5.666 8.127];
ref = [mkSig(T,'sin',periods(1)) mkSig(T,'sin',periods(2))];
resp= ref;
sources = { ref(:,1) ref(:,2);   % 5-sample sin with background noise @ pos1
            {'coloredNoise' 1} {}}; % rest just noise
M=15; % N.B. > num electrodes noise sources to ensure non-invertable signal
y2mix=cat(3,[1 .1;5 5],[.1 1;5 5]);% src_loc x src_sig x label, inc freq 1 in class 1, inc freq 2 in class 2
Yl   =(randn(N,1)>0)+1;
mix  =y2mix(:,:,Yl);  % ch x source x N
[X,A,S,src_loc,elect_loc]=mksfToy(sources,mix,T,M);
W=pinv(A); % optimal spatial filt
[U,s,Xr,covXr,covX]=ssepSpatFilt(X,[1 2],periods); % no phase info
(U(:,1)'*W(:,1))./sqrt(W(:,1)'*W(:,1)*U(:,1)'*U(:,1)) % correlation between optimal and estimated filter
[U,s,Xr,covXr,covX]=ssepSpatFilt(X,[1 2],ref); % with phase info

% with varying amounts of training data
covXr = tprod(Xr,[1 3 4],[],[2 3 4]); % per-trial covariance
clear cor auc auc2;
for ntr=1:size(X,3); 
  [U,s]=eig(mean(sum(covXr(:,:,:,1:ntr),4),3)./ntr,covX);
  s=diag(s); [ans,si]=sort(real(s),'descend'); s=s(si); U=U(:,si); 
  cor(ntr)=(U(:,1)'*W(:,1))./sqrt(W(:,1)'*W(:,1)*U(:,1)'*U(:,1));
  UXr  = tprod(U(:,1),[-1],Xr,[-1 1 2]); % [ref x epoch]
  auc(:,ntr) =dv2auc(Yl*2-3,UXr,2); % auc per ref-signal and time-lag
  auc2(:,ntr)=dv2auc(Yl*2-3,sum(UXr(1:end/2,:).^2)-sum(UXr(end/2+1:end,:).^2),2); % simple sum-squares per-ref signal
end
clf;subplot(211);plot(abs(cor));ylim([.5 1]);title('spat-filt corr to opt');subplot(212);plot(auc');title('auc per ref and time-lag');



