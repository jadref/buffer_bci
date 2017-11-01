function [x,s]=relFilt(x,s,alpha,accdim,verb)
% relative filter 
%
%   [x,s,mu,std]=stdFilt(x,s,alpha,accdim,verb)
%
%    x(t) = x(t)./mu(x)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   alpha - [1 x 1] OR [nd x 1] exponiential decay factor for the moving average for 
%                   all [1x1] or each [ndx1] input feature
%           fx(t) = (\sum_0^inf x(t-i)*alpha^i)/(\sum_0^inf alpha^i)
%           fx(t) = (1-alpha) x(t) + alpha fx(t)
%   accdim -- [int 1x1] accumulate over this dimension of x
% Outputs:
%   x - [nd x 1] filtered data,  x(t) = x(t) - fx(t)
%   s - [struct] updated filter state
if ( nargin<5 || isempty(verb) ) verb=0; end;
if ( nargin<4 ) accdim=[]; end;
if ( isempty(s) ) s=struct('sx',0,'N',0,'x',0,'i',0); end;
if ( any(alpha>1) ) alpha=exp(log(.5)./alpha); end; % convert to decay factor

s.N = alpha.*s.N + (1-alpha).*1; % weight accumulated so far for each alpha, for warmup
sx  = x.^2;
if ( ~isempty(accdim) ) % accumulate away the indicated dim(s)
   for di=1:numel(accdim); sx=sum(sx,accdim(di))./size(x,accdim(di)); end;
end
s.sx=alpha(:,1).*s.sx + (1-alpha(:,1)).*sx; % weighted sum of x
if ( verb>0 ) fprintf('x=[%s]\ts=[%s]',sprintf('%g ',x),sprintf('%g ',s.sx./s.N)); end;

if ( size(alpha,2)>1 ) % moving average filter the raw inputs
  if ( any(alpha(:,2)<0) ) % moving buffer average
    if ( isscalar(s.x) ) s.x = zeros(numel(x),-min(alpha(:,2))); s.i=0; end;
    s.x(:,mod(s.i,size(s.x,2))+1) = x(:); % insert in ring buffer
    s.i = s.i+1;
    nf=size(s.x,2); if (s.i<nf) nf=s.i; end % num valid entries in window
    x   = reshape(sum(s.x,2)./nf,size(x)); % ave of this window  
  else % exp-weight MA
    s.x= alpha(:,2).*s.x + (1-alpha(:,2)).*x; % udpate running average
    x  = s.x./s.N(:,2); % smoothed output estimate 
  end
end;

% relative baseline
if( isempty(accdim) ) x=      x  ./  sqrt(s.sx./s.N(:,1)); 
else                  x=repop(x,'./',sqrt(s.sx./s.N(:,1))); 
end
if ( verb>0 ) fprintf(' => x_new=[%s]\n',sprintf('%g ',x)); end;
return;
function testCase()
x=cumsum(randn(2,1000),2);

% simple test
s=[];fs=[];fx=[];for i=1:size(x,2); [fx(:,i),si]=relFilt(x(:,i),s,100); fs(:,i)=si.sx/si.N; s=si; end;
% feature specific smoothers
s=[];fs=[];fx=[];for i=1:size(x,2); [fx(:,i),si]=relFilt(x(:,i),s,[exp(log(.5)/100);exp(log(.5)/1000)]); fs(:,i)=si.sx/si.N; s=si; end;


clf;for si=1:size(x,1); subplot(size(x,1),1,si); plot([x(si,:);fx(si,:);fs(si,:)]');legend('x','filt(x)','rel');end;

% double processing, output smoother + rel-adapt
s=[];fs=[];ss=[];fx=[];for i=1:size(x,2); [fx(:,i),si]=relFilt(x(:,i),s,[100 20]); fs(:,i)=si.sx/si.N(:,1); ss(:,i)=si.x./si.N(:,2); s=si; end;
clf;for si=1:size(x,1); subplot(size(x,1),1,si); plot([x(si,:);fx(si,:);fs(si,:);ss(si,:)]');legend('x','filt(x)','rel','smthx');end;



% with accumulation over one dim of x
x2d=reshape(x,[2,4,size(x,2)/4]);
s=[];fs=[];fx=[];for i=1:size(x2d,3); [fx(:,:,i),si]=relFilt(x2d(:,:,i),s,100,2); fs(:,i)=si.sx/si.N; s=si; end;
