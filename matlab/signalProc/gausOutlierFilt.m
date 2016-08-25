function [x,s]=gausOutlierFilt(x,s,zscore,maxn)
% send event when best accumulate prediction has zscore higher than threshold w.r.t. gaussian approx to dist of scores
%
%   [x,s]=gausOutlierFilt(x,s,zscore,maxn)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   zscore - [float] minimum z-score for best x to generate prediction                    (2)
%   maxn   - [int] max number of predictions to accumulate before generating prediction   (inf)
% Outputs:
%   x - [nd x 1] filtered data
%   s - [struct] updated filter state
if ( nargin<3 ) zscore=2; end;
if ( nargin<4 ) maxn=inf; end;
if ( isempty(s) ) s=struct('x',zeros(size(x,1),1),'n',0,'mu',0,'var',1); end;
% update internal state
s.x  =s.x  + x;
s.n  =s.n  + 1;
mux  =mean(x);
s.mu =s.mu + mux;
s.var=sqrt(s.var.^2 + mean((x-mux).^2));

mx =max(s.x);
if( mx > s.mu + zscore*s.var || s.n>maxn )
  %if ( s.n>maxn ) fprintf('gausOutlierFilt: maxn pred'); else fprintf('gausOutlierFilt: outlier pred'); end;
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
ox=randn(4,1000); 
x =ox;
x =ox+0;  % constant offset 
x(1,:)=x(1,:)+.2; % weak signal in clsfr 1
zscore=2;
s=[];tx=zeros(size(x));
for i=1:size(x,2);[fx{i},s]=gausOutlierFilt(x(:,i),s,zscore);if(~isempty(fx{i}))[ans,mi]=max(fx{i});tx(mi,i)=1;end;end;
clf;mcplot([x;tx]');
