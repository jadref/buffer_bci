function [x,s]=biasFilt(x,s,alpha,verb)
% bias removing filter (high-pass) removes slow drifts from inputs, with optional pre-high-pass
%
%   [x,s]=biasFilt(x,s,alpha,verb)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   alpha - [1 x 1] OR [nd x 1] exponiential decay factor for the moving average for 
%                   all [1x1] or each [ndx1] input feature
%           fx(t) = (\sum_0^inf x(t-i)*alpha^i)/(\sum_0^inf alpha^i)
%           fx(t) = (1-alpha) x(t) + alpha fx(t)
%           OR
%           [1 x 2] or [nd x 2] 2-decay factors, one for bias, one for pre-high-pass
%               alpha(1) = decay for the bias estimation
%               alpha(2) = decay factor for averaging the inputs (high-pass)
% Note:
%   alpha = exp(log(.5)./(half-life))
%  for any geometric series: s(n)=\sum_1:n a*1 + r*s(n-1)= a + a*r + ... + a*r^{n-1} = a*(1-r^n)/(1-r)
%   -> here: r=alpha, a=(1-alpha) so :
%         total weight after n-steps = (1-alpha)*(1-alpha^n)/(1-alpha) = 1-alpha^n
%  
% Outputs:
%   x - [nd x 1] filtered data,  x(t) = x(t) - fx(t)
%   s - [struct] updated filter state, s.N = total weight, s.sx = smoothed estimate of x
if ( nargin<4 || isempty(verb) ) verb=0; end;
if ( isempty(s) ) s=struct('sx',zeros(size(x)),'N',0); end;
if(any(alpha>1)) alpha=exp(log(.5)./alpha); end; % convert to decay factor
if ( size(alpha,2)>1 ) % moving average filter the raw inputs
  s.x= alpha(:,2).*s.x + (1-alpha(:,2)).*x; x=s.x; 
end;
s.N =alpha(:,1).*s.N  + (1-alpha(:,1)).*1; % weight accumulated so far, for warmup
s.sx=alpha(:,1).*s.sx + (1-alpha(:,1)).*x; % weighted sum of x
if ( verb>0 ) fprintf('x=[%s]\ts=[%s]',sprintf('%g ',x),sprintf('%g ',s.sx./s.N)); end;
x=x-s.sx./s.N;
if ( verb>0 ) fprintf(' => x_new=[%s]\n',sprintf('%g ',x)); end;
return;
function testCase()
x=cumsum(randn(2,200),2)+100;
x(:,1)=x(:,1)+50;

% simple test
s=[];for i=1:size(x,2); [fx(:,i),si]=biasFilt(x(:,i),s,exp(log(.5)/100)); s=si; fs(:,i)=si.sx; end;
% feature specific smoothers
s=[];for i=1:size(x,2); [fx(:,i),si]=biasFilt(x(:,i),s,[exp(log(.5)/100);exp(log(.5)/1000)]); fs(:,i)=si; s=si; end;

clf;
si=1; idx=1:size(x,2);
for si=1:size(x,1); 
		subplot(size(x,1),1,si); 
		plot([x(si,idx);fx(si,idx);fs(si,idx)]');legend('x','filt(x)','bias');
end;
