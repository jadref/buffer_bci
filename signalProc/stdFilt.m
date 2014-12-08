function [x,s,mu,std]=stdFilt(x,s,alpha)
% standardising moving average filter
%
%   [x,s,mu,std]=stdFilt(x,s,alpha)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   alpha - [float] exponiential decay factor for the moving average
%           [2x1] 2 decay factors.  
%                    alpha(1) = decay for mu/std estimation
%                    alpha(2) = decay for averaging raw inputs (high-pass)
% Outputs:
%   x - [nd x 1] filtered data
%   s - [struct] updated filter state
if ( isempty(s) ) s=struct('N',0,'sx',zeros(size(x)),'sx2',zeros(size(x)),'x',zeros(size(x))); end;
if ( numel(alpha)>1 ) 
  s.x= alpha(2)*s.x + (1-alpha(2))*x; x=s.x; 
end;
% moving average summary statistics for mu/std 
s.N  = alpha(1)*s.N  + (1-alpha(1))*1;
s.sx = alpha(1)*s.sx + (1-alpha(1))*x; 
s.sx2= alpha(1)*s.sx2+ (1-alpha(1))*x.^2;
% current mean/variance
mu=s.sx./s.N;
std=sqrt(abs((s.sx2-s.sx.^2./s.N)./s.N));
std(std<eps)=1; % deal with 0-variance channels
if ( s.N(1)>(1-alpha(1)) ) x=(x-mu)./std; end;
return;
%-------------------------------------------------------------
function testCase()
x=cumsum(randn(2,10000),2);
mu=zeros(size(x)); std=zeros(size(x)); fx=zeros(size(x)); 
s=[]; for i=1:size(x,2); [fx(:,i),s,mu(:,i),std(:,i)]=stdFilt(x(:,i),s,exp(log(.5)/100)); end;

% high-pass and stdandardise
s=[]; for i=1:size(x,2); [fx(:,i),s,mu(:,i),std(:,i)]=stdFilt(x(:,i),s,[exp(log(.5)/100) exp(log(.5)/10)]); end;

clf;
for si=1:size(x,1); 
  subplot(size(x,1),1,si); plot([x(si,:);fx(si,:)*10;mu(si,:);mu(si,:)+std(si,:)]');legend('x','filt(x)*10','mu','std'); 
end;
