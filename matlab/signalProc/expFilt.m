function [x,s]=expFilt(x,s,alpha)
% Windowed average filter
%
%   [fx,s,mu,std]=expFilt(x,s,alpha)
% 
%    fx(t) = (1-alpha)*x(t) + alpha * fx(t-1) 
% 
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   alpha - [float] exp-moving average factor
%            alpha = exp(log(.5)./(half-life))
%            % N.B. 0=no-smoothing, 1=infinite-smoothing            
% Outputs:
%   x - [nd x 1] filtered data
%   s - [struct] updated filter state
if ( isempty(s) ) s=struct('sx',zeros(size(x)),'N',0); end;
if(any(alpha>1)) alpha=exp(log(.5)./alpha); end; % convert to decay factor
s.N =alpha(:).*s.N  + (1-alpha(:)).*1; % weight accumulated so far, for warmup
s.sx=alpha(:).*s.sx + (1-alpha(:)).*x;
x=s.sx;
return;
function testCase()
x=cumsum(randn(1,1000));
s=[]; for i=1:numel(x); [fx(i),s]=expFilt(x(:,i),s,exp(log(.2)/10)); end;
s=[]; for i=1:numel(x); [fx(i),s]=expFilt(x(:,i),s,exp(log(.2)/500)); end;
clf;plot([x;fx]');legend('x','fx');
