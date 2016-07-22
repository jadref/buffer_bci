function [x,s]=gausOutlierFilt(x,s,zscore,maxn)
% send event when best accumulate prediction has zscore higher than threshold w.r.t. gaussian approx to dist of scores
%
%   [x,s]=gausOutlierFilt(x,s,zscore,maxn)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   zscore - [float] minimum z-score for best x to generate prediction
%   maxn   - [int] max number of predictions to accumulate before generating prediction
% Outputs:
%   x - [nd x 1] filtered data
%   s - [struct] updated filter state
if ( nargin<4 ) maxn=inf; end;
if ( isempty(s) ) s=struct('x',zeros(size(x,1),1),'n',0,'mu',0,'var',1); end;
% update internal state
s.x  =s.x  + x;
s.n  =s.n  + 1;
s.mu =s.mu + mean(x);
s.var=sqrt(s.var.^2 + mean(x.^2));

mx =max(s.x);
if( mx > s.mu + zscore*s.var || s.n>maxn )
  x     =s.x;
  % clear internal state
  s.x(:)=0;
  s.n   =0;
  s.mu  =0;
  s.var =1;
else
  x = []; % don't send
end
return;
function testCase()
x=randn(4,1000);
s=[]; for i=1:size(x,2); [fx{i},s]=gausOutlierFilt(x(:,i),s,3); end;
s=[]; for i=1:size(x,2); [fx{i},s]=gausOutlierFilt(x(:,i),s,100); end;
