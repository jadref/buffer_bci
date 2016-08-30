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
% Outputs:
%   x - [nd x 1] filtered data
%   s - [struct] updated filter state
if ( isempty(s) ) s=struct('N',0,'sx',zeros(size(x)),'sx2',zeros(size(x))); end;
% mu/std statistics recording
s.N  = alpha*s.N  + (1-alpha)*1;
s.sx = alpha*s.sx + (1-alpha)*x; 
s.sx2= alpha*s.sx2+ (1-alpha)*x.^2;
% current mean/variance
mu=s.sx./s.N;
std=sqrt(abs((s.sx2-s.sx.^2./s.N)./s.N));
std(std<eps)=1; % deal with 0-variance channels
if ( s.N>(1-alpha) ) x=(x-mu)./std; end;
return;

function testCase()
x=cumsum(randn(2,10000),2);
mu=zeros(size(x)); std=zeros(size(x)); fx=zeros(size(x)); 
s=[]; for i=1:size(x,2); [fx(:,i),s,mu(:,i),std(:,i)]=stdFilt(x(:,i),s,exp(log(.5)/100)); end;
clf;
for si=1:size(x,1); 
  subplot(size(x,1),1,si); plot([x(si,:);fx(si,:);mu(si,:);mu(si,:)+std(si,:)]');legend('x','filt(x)','mu','std'); 
end;
