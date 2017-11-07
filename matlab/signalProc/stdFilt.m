function [x,s,mu,std]=stdFilt(x,s,alpha)
% standardising (0-mean, unit-stddev) moving average filter
%
%   [x,s,mu,std]=stdFilt(x,s,alpha)
%
%   x(t) = (x(t)-mu(x))./std(x)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   alpha - [1 x 1] OR [nd x 1] exponiential decay factor for the moving average for 
%                   all [1x1] or each [ndx1] input feature
%           fx(t) = (\sum_0^inf x(t-i)*alpha^i)/(\sum_0^inf alpha^i)
%           fx(t) = (1-alpha) x(t) + alpha fx(t)
%         OR
%           [ndx2] 2 decay factors.  
%                    alpha(1) = decay for mu/std estimation
%                    alpha(2) = decay for averaging raw inputs (high-pass)
% Outputs:
%   x - [nd x 1] filtered data
%   s - [struct] updated filter state
if ( isempty(s) ) s=struct('N',zeros(size(alpha)),'sx',zeros(size(x)),'sx2',zeros(size(x)),'x',zeros(size(x))); end;
if ( any(alpha>1) ) alpha=exp(log(.5)./alpha); end; % convert to decay factor
s.N  = alpha.*s.N  + (1-alpha).*1;
if ( size(alpha,2)>1 ) 
  s.x= alpha(:,2).*s.x + (1-alpha(:,2)).*x; 
  x  = s.x./s.N(:,2); 
end;
% moving average summary statistics for mu/std 
s.sx = alpha(:,1).*s.sx + (1-alpha(:,1)).*x; 
s.sx2= alpha(:,1).*s.sx2+ (1-alpha(:,1)).*x.^2;
% current mean/variance
mu=s.sx./s.N(:,1);
std=sqrt(abs((s.sx2-s.sx.^2./s.N(:,1))./s.N(:,1)));
std(std<eps)=1; % deal with 0-variance channels
% standardize features for which we have enough weighting
goodIdx=s.N(:,1)>(1-alpha(:,1));
if( size(alpha,1)>1 ) % per-feature 
   if( any(goodIdx) ) 
      x(goodIdx)=(x(goodIdx)-mu(goodIdx))./std(goodIdx);
   end
elseif( any(goodIdx) ) % global half-life
   x = (x-mu)./std;
end
return;
function testCase()
x=cumsum(randn(2,10000),2);
mu=zeros(size(x)); std=zeros(size(x)); fx=zeros(size(x)); 

% simple stdandardizing filter
s=[]; for i=1:size(x,2); [fx(:,i),s,mu(:,i),std(:,i)]=stdFilt(x(:,i),s,exp(log(.5)/100)); end;
s=[]; for i=1:size(x,2); [fx(:,i),s,mu(:,i),std(:,i)]=stdFilt(x(:,i),s,100); end;

% high-pass and stdandardise
s=[]; for i=1:size(x,2); [fx(:,i),s,mu(:,i),std(:,i)]=stdFilt(x(:,i),s,[exp(log(.5)/100) exp(log(.5)/10)]); end;

% test with different smoothers for different features
s=[]; for i=1:size(x,2); [fx(:,i),s,mu(:,i),std(:,i)]=stdFilt(x(:,i),s,[exp(log(.5)/100) exp(log(.5)/10);exp(log(.5)/400);1]); end;

clf;
for si=1:size(x,1); 
  subplot(size(x,1),1,si); plot([x(si,:);fx(si,:)*10;mu(si,:);mu(si,:)+std(si,:)]');legend('x','filt(x)*10','mu','std'); 
end;

