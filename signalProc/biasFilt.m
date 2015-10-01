function [x,s]=biasFilt(x,s,alpha)
% bias removing filter (high-pass) removes slow drifts from inputs
%
%   [x,s]=biasFilt(x,s,alpha)
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
%   s - [struct] updated filter state
if ( isempty(s) ) s=struct('x',x,'n',1); end;
if(any(alpha>1)) alpha=exp(log(.5)./alpha); end; % convert to decay factor
if ( isstruct(s) ) % during warmup phase
   alphaN=1-1/s.n; s.n=s.n+1; % alpha adapts w.r.t. the number of examples processed
   s.x=alphaN(:).*s.x + (1-alphaN(:)).*x;
   fprintf('x=[%s]\ts=[%s]',sprintf('%g ',x),sprintf('%g ',s.x));
   x=x-s.x;
   fprintf(' => x_new=[%s]\n',sprintf('%g ',x));
   if ( alphaN > alpha ) s=s.x; fprintf('\n**end-warmup**\n'); end % just store the MA at the end of the warmup phase
else
   s=alpha(:).*s + (1-alpha(:)).*x; % exp-decay moving average
   fprintf('x=[%s]\ts=[%s]',sprintf('%g ',x),sprintf('%g ',s));
   x=x-s;
   fprintf(' => x_new=[%s]\n',sprintf('%g ',x));
end;
return;
function testCase()
x=cumsum(randn(2,200),2)+100;
x(:,1)=x(:,1)+50;

% simple test
s=[];for i=1:size(x,2); [fx(:,i),si]=biasFilt(x(:,i),s,exp(log(.5)/100)); s=si; end;
% feature specific smoothers
s=[];for i=1:size(x,2); [fx(:,i),si]=biasFilt(x(:,i),s,[exp(log(.5)/100);exp(log(.5)/1000)]); fs(:,i)=si; s=si; end;

clf;for si=1:size(x,1); subplot(size(x,1),1,si); plot([x(si,:);fx(si,:);fs(si,:)]');legend('x','filt(x)','bias');end;
