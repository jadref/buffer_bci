function [x,s]=stdFilt(x,s,alpha,scale)
% standardize the variance of the features
%
%   [x,s]=stdFilt(x,s,alpha)
%
%   f(x) = x*scale./std(x)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   scale - [1 x 1] magnitude of 1 std-dev in the output
%   alpha - [1 x 1] decay factor (1)
% Outputs:
%   x - [nd x 1] filtered data
%   s - [struct] updated filter state
if ( nargin<3 || isempty(alpha) ) alpha=1; end;
if ( nargin<4 || isempty(scale) ) scale=1; end;
if ( isempty(s) ) s=struct('N',zeros(size(alpha)),'scale',.5,'alpha',alpha,'sx',zeros(size(x)),'sx2',zeros(size(x)),'x',zeros(size(x))); end;
if ( any(alpha>1) ) alpha=exp(log(.5)./alpha); end; % convert to decay factor
s.N  = s.alpha.*s.N  + 1;
% moving average summary statistics for mu/std 
s.sx = s.alpha.*s.sx + x; 
s.sx2= s.alpha.*s.sx2+ x.^2;
% current mean/variance
mu=s.sx./s.N(:,1);
s.var=max(0,(s.sx2-s.sx.^2./s.N))./s.N; % running variance estimate 
s.var(s.var<eps)=1; % deal with 0-variance channels
x = x.*s.scale./sqrt(mean(s.var));
return;
function testCase()
x=cumsum(randn(2,10000),2);
mu=zeros(size(x)); std=zeros(size(x)); fx=zeros(size(x)); 

% simple stdandardizing filter
s=[]; for i=1:size(x,2); [fx(:,i),s]=gainFilt(x(:,i),s); end;
s=[]; for i=1:size(x,2); [fx(:,i),s]=gainFilt(x(:,i),s,exp(log(.5)/100)); end;
s=[]; for i=1:size(x,2); [fx(:,i),s]=gainFilt(x(:,i),s,100); end;

clf;plot([repop(x,'./',std(x')');fx]')

% high-pass and stdandardise
s=[]; for i=1:size(x,2); [fx(:,i),s,mu(:,i),std(:,i)]=gainFilt(x(:,i),s,[exp(log(.5)/100) exp(log(.5)/10)]); end;

% test with different smoothers for different features
s=[]; for i=1:size(x,2); [fx(:,i),s,mu(:,i),std(:,i)]=gainFilt(x(:,i),s,[exp(log(.5)/100) exp(log(.5)/10);exp(log(.5)/400);1]); end;

clf;
for si=1:size(x,1); 
  subplot(size(x,1),1,si); plot([x(si,:);fx(si,:)*10;mu(si,:);mu(si,:)+std(si,:)]');legend('x','filt(x)*10','mu','std'); 
end;

