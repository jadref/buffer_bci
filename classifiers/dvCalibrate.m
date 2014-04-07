function [Ab,f,dvAb]=dvCalibrate(Y,dv,cr,wght,maxIter,tol,verb)
% calibrate decision values to return valid probabilities
%
% [Ab,f,dvAb]=dvCalibrate(Y,dv,cr,wght,maxIter,tol,verb)
%
% Fit a standard logistic signmoid to the input dv and Y such that 
% the returned probabilities are valid in a max liklihood sense.
% Based on the method in:
%  J. Platt, “Probabilistic outputs for support vector machines and
%  comparisons to regularized likelihood methods,” in Advances in large
%  margin classifiers, 2000, pp. 61–74.
%
% Inputs:
%  Y - [N x nSp] set of binary labels
%  dv- [N x nSp] set of binary predictions
%  cr- [1 x nSp] OR [2 x nCls] set of classification rates for each problem
%  wght - [2 x nSp] class weighting (neg,pos) for each sub-problem
%         OR
%         [N x nSp] example weighting for each example
%  maxIter - max iterations
%  tol  - convergence tolerance
%  verb - verbosity level
% Outputs
%  Ab- [2 x nSp] set of gain,offset pairs for each sub-problem
%  f - [1 x nSp] average predicted probability for each class
%  dvAb - [N x nSp] transformed input
if ( nargin < 4 || isempty(wght) ) wght=1; end;
if ( nargin < 5 || isempty(maxIter) ) maxIter=500; end;
if ( nargin < 6 || isempty(tol) ) tol=1e-5; end;
if ( nargin < 7 || isempty(verb) ) verb=0; end;
% if ( any(cr(:) < .5) || any(cr(:) > 1) ) 
%    warning('impossible classification rate, .5 < cr < 1'); 
%    Ab=[ones(1,size(Y,2)); zeros(1,size(Y,2))];
%    return;
% end;

if ( size(wght,1)==2 ) % convert to per-example weighting
  cwght=wght;
  wght=zeros(size(Y)); wght(Y<0)=cwght(1); wght(Y>0)=cwght(2);
end

% adjust the target to regularise the fit and prevent overfitting
oY=Y;
for spi=1:size(Y,2); 
  np=sum(Y(:,spi)>0); nn=sum(Y(:,spi)<0);
  Y(Y(:,spi)>0,spi) =  (np+1)./(np+2); 
  Y(Y(:,spi)<0,spi) = -(nn+1)./(nn+2);
end

Ab=zeros(2,size(Y,2)); %Ab(2,:)=-mean([mean(dv(Y<0,:),1);mean(dv(Y>0,:),1)],1);%b=zeros(1,size(Y,2)); 
oAb=ones(size(Ab)); f=ones(1,size(Y,2));
% Gradient descent to find the parameters
% N.B. we use dv' = dv*exp(A), so A has range -inf->+inf
for iter=1:maxIter
   of=f;
   dvb  = repop(dv,'+',Ab(2,:)); 
   dvAb = repop(dvb,'.*',exp(Ab(1,:))); %dvAb=repop(dvA,'+',Ab(2,:));
   [f,df]=lossFn(Y,dvAb,wght);
   dAb=[sum(dv.*df,1); sum(df,1)]; % gradient
   
   if ( verb>0 )
      fprintf('%d) A=[%s]\tf=[%s]\tdf=[%s]\n',iter,sprintf('%0.5f ',Ab(:,1:min(end,3))),sprintf('%0.5f ',f),sprintf('%0.5f ',dAb(:,1:min(end,3))));
   end
   % stabilise step size, but limiting rate of step growth, use Arjia step-size computation
   for i=1:size(Ab,2); % stabilize each sub-problem independently
      if( dAb(:,i)'*(Ab(:,i)-oAb(:,i))>0 ) % lower bound
         dAb(:,i)=.5*norm(Ab(:,i)-oAb(:,i))./norm(dAb(:,i))*dAb(:,i);
      elseif( norm(dAb)>2.*norm(Ab-oAb) )  % upper bound
         dAb(:,i)=2.*norm(Ab(:,i)-oAb(:,i))./norm(dAb(:,i))*dAb(:,i); 
      end
   end
   oAb=Ab;  Ab     = Ab - dAb;
   if ( abs(norm(oAb(:)-Ab(:)))<tol || norm(dAb(1,:))<tol || norm(f(:)-of(:))<tol*1e-2 ) break; end;
end
% return as a raw multplier, i.e. not log
Ab(1,:)=exp(Ab(1,:)); Ab(2,:)=Ab(2,:).*Ab(1,:);
return;

function [f,df]=lossFn(Y,dv,wght)
if ( nargin<3 ) wght=1; end;
g     = max(1./(1+exp(-(Y.*dv))),eps);   % Y.*P(Y|x,w,b,fp)
g(Y==0)=1; % remove excluded points, by effectively treating as perfectly correct
wghtY = wght.*Y;
N     = sum(wghtY~=0);
f     = -sum((wght.*log(g)))./N; % max-likelihood loss
df    = repop(-wghtY.*(1-g),'./',N);
return;

%-----------------------------------------------------------------
function testCase()
Y=sign(randn(100,1)+0.0); % include constant to give unbalanced data, N.B. +1 = 4:1 unbalance
dv=(Y+randn(size(Y))*2e-0)*2+5; % include a re-scaling and an offset
[Ab,f,dvAb]=dvCalibrate(Y,dv,[],sum(Y~=0)./[sum(Y<0) sum(Y>0)]./2,[],[],2);
% check the per-class loss
conf2loss(dv2conf(Y,dvAb),'pc')


if ( exist('res','var') ) 
  dv=res.tstf(:,res.opt.Ci); Y=res.Y; 
  [Ab,f]=dvCalibrate(Y,dv,[],[],[],[],2)  
end;

% compute and plot a histogram of the prob correct
clf;
bins=sort(dv(Y~=0),'ascend'); bins=bins(round(linspace(1,numel(bins),30)));% equal #points per bin
ps  =zeros(numel(bins)-1,1);
for i=1:numel(ps);
  idx   = dv>bins(i) & dv<=bins(i+1) & Y~=0;
  N(i)  = sum(idx);
  ps(i) = sum(Y(idx)>0)./N(i);
end
plot(bins(2:end),ps);xlabel('dv');ylabel('Pr(Y=1|dv)')
hold on;
plot(bins(2:end)*Ab(1)+Ab(2),ps,'r');
%plot(bins,1./(1+exp(-(bins*Ab(1)+Ab(1)*Ab(2)+Ab(2)))),'r');
xs=get(gca,'xlim');xs=linspace(xs(1),xs(2),50);plot(xs,1./(1+exp(-xs)),'g'); 
legend('Emp / UnCal','Cal','logistic','Location','NorthWest');

% test with excluded points
Y=sign(randn(100,1));  Y(1:10,:)=0;
dv=Y+randn(size(Y))*2e-0;
[Ab,f]=dvCalibrate(Y,dv,[],[],[],[],2); % mark as excluded
[Ab0,f0]=dvCalibrate(Y(Y~=0),dv(dv~=0),[],[],[],[],2); % remove excluded points

% cal set at once
Y=sign(randn(100,3));
dv=Y+randn(size(Y))*1e-2;
[Ab,f]=dvCalibrate(Y,dv,[],[],[],[],2)

