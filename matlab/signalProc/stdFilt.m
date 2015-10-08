function [x,s,mu,std]=stdFilt(x,s,alpha)
% standardising moving average filter
%
%   [x,s,mu,std]=stdFilt(x,s,alpha)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   alpha - [1 x 1] OR [nd x 1] exponiential decay factor for the moving average for 
%                   all [1x1] or each [ndx1] input feature
%           fx(t) = (\sum_0^inf x(t-i)*alpha^i)/(\sum_0^inf alpha^i)
%           fx(t) = (1-alpha) x(t) + alpha fx(t)
%           N.B. alpha = exp(log(.5)./(half-life))
%         OR
%           [ndx2] 2 decay factors.  
%                    alpha(1) = decay for mu/std estimation
%                    alpha(2) = decay for averaging raw inputs (high-pass)
% Outputs:
%   x - [nd x 1] filtered data
%   s - [struct] updated filter state.  N=total weight, sx=MA est x, sx2=MA ext x^2
if ( isempty(s) ) s=struct('N',zeros(size(x)),'sx',zeros(size(x)),'sx2',zeros(size(x)),'x',zeros(size(x))); end;
if(any(alpha>1)) alpha=exp(log(.5)./alpha); end; % convert to decay factor
if ( size(alpha,2)>1 ) % moving average filter the raw inputs
  s.x= alpha(:,2).*s.x + (1-alpha(:,2)).*x; x=s.x; 
end;
% moving average summary statistics for mu/std 
s.N  = alpha(:,1).*s.N  + (1-alpha(:,1)).*1;
s.sx = alpha(:,1).*s.sx + (1-alpha(:,1)).*x; 
s.sx2= alpha(:,1).*s.sx2+ (1-alpha(:,1)).*x.^2;
% current mean/variance
mu=s.sx./s.N;
std=sqrt(abs((s.sx2-s.sx.^2./s.N)./s.N));
std(std<eps)=1; % deal with 0-variance channels
% center always
x =x-mu;
% standardize features for which we have enough weighting, i.e. >1 sample
goodIdx=s.N>1-alpha(:,1)+eps;
if( any(goodIdx) ) x(goodIdx)=x(goodIdx)./std(goodIdx); end
return;
function testCase()
x=cumsum(randn(2,10000),2)+50;
x(:,1)=x(:,1)+50; % initial error to check warmup
mu=zeros(size(x)); std=zeros(size(x)); fx=zeros(size(x)); 
s=[]; fx=[]; mu=[]; std=[];
for i=1:size(x,2); [fx(:,i),s,mu(:,i),std(:,i)]=stdFilt(x(:,i),s,exp(log(.5)/100)); end;

% high-pass and stdandardise
s=[]; fx=[]; mu=[]; std=[];
for i=1:size(x,2); [fx(:,i),s,mu(:,i),std(:,i)]=stdFilt(x(:,i),s,[exp(log(.5)/100) exp(log(.5)/10)]); end;

% test with different smoothers for different features
s=[]; fx=[]; mu=[]; std=[];
for i=1:size(x,2); [fx(:,i),s,mu(:,i),std(:,i)]=stdFilt(x(:,i),s,[exp(log(.5)/100) exp(log(.5)/10);exp(log(.5)/400) 1]); end;

clf;
idx=1:1000;si=1;
for si=1:size(x,1); 
  subplot(size(x,1),1,si); 
  plot([x(si,idx);fx(si,idx)*10;mu(si,idx);mu(si,idx)+std(si,idx)]','lineWidth',1);legend('x','filt(x)*10','mu','std'); 
end;

