function [x,s]=gausOutlierFilt(x,s,w,zscore,priorvar,maxn)
% send event when best accumulate prediction has zscore higher than threshold w.r.t. gaussian approx to dist of scores
%
%   [x,s]=gausOutlierFilt(x,s,zscore,maxn)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   w - [nd x nC] sub-problem decoding matrix, mapping from raw data to output classes    ([])
%   zscore - [float] minimum z-score for best x to generate prediction                    (2)
%   maxn   - [int] max number of predictions to accumulate before generating prediction   (inf)
% Outputs:
%   x - [nd x 1] filtered data
%   s - [struct] updated filter state
if ( nargin<3 ) w=1; end;
if ( nargin<4 ) zscore=2; end;
if ( nargin<5 || isempty(priorvar) ) priorvar=1; end;
if ( nargin<6 ) maxn=inf; end;
if ( isempty(s) ) s=struct('x',0,'n',0,'mu',0,'var',priorvar); end;
% update internal state
if ( ~isempty(w) ) x=x*w; end; % apply the decoding matrix
s.x  =s.x  + x;
s.n  =s.n  + 1;
mux  =mean(x);
s.mu =s.mu + mux;
s.var=sqrt(s.var.^2 + mean((x-mux).^2));

[mx,mxi] =max(s.x); % best
mx2=max(s.x([1:mxi-1 mxi+1:end])); % next-best
if( (mx > s.mu + zscore(1)*s.var && mx> mx2 + zscore(min(end,2))*s.var) || ...
   s.n>maxn )
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
for i=1:size(x,2);[fx{i},s]=gausOutlierFilt(x(:,i),s,[],zscore);if(~isempty(fx{i}))[ans,mi]=max(fx{i});tx(mi,i)=1;end;end;
clf;mcplot([x;tx]','linewidth',2);


% test erpSequence decoding with epoch sequence
ox=randn(1,1000); % binary classifier
%cb=sign(randn(4,1000)); % random 4-class decoding matrix
cb=repmat(eye(4),[1 1 size(ox,2)/4]); % sequential 4-class decoding matrix
x=ox;
x=x + cb(1,:)*.3; % weak signal for sequence 1
zscore=1.75;
s=[];fx=zeros(size(cb,1),size(x,2));tx=zeros(size(fx));
for i=1:size(x,2);[tmp,s]=gausOutlierFilt(x(:,i),s,cb(:,i),zscore);if(~isempty(tmp))fx(:,i)=tmp;[ans,mi]=max(tmp);tx(mi,i)=1;end;end;
clf;mcplot([x;tx]','linewidth',2); % plot the decisions
clf;imagesc(fx(:,sum(tx)>0)) % plot the accum info at decision
