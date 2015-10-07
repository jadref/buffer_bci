function [x,s]=biasFilt(x,s,alpha,verb)
% bias removing filter (high-pass) removes slow drifts from inputs
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
%           N.B. alpha = exp(log(.5)./(half-life))
% Outputs:
%   x - [nd x 1] filtered data,  x(t) = x(t) - fx(t)
%   s - [struct] updated filter state, s.N = total weight, s.sx = smoothed estimate of x
if ( nargin<4 || isempty(verb) ) verb=0; end;
if ( isempty(s) ) s=struct('sx',zeros(size(x)),'N',0); end;
if(any(alpha>1)) alpha=exp(log(.5)./alpha); end; % convert to decay factor
s.N =alpha(:).*s.N  + (1-alpha(:)).*1; % weight accumulated so far, for warmup
s.sx=alpha(:).*s.sx + (1-alpha(:)).*x;
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
