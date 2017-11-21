function [x,s]=medianFilt(x,s,alpha,scl)
% robust-bias removing filter (high-pass) based on running median estimation
%
%   [x,s,mu,std]=rbiasFilt(x,s,alpha,scl)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   alpha - [1 x 1] OR [nd x 1] exponiential decay factor for the median estimation for 
%                   all [1x1] or each [ndx1] input feature
%         OR
%           [ndx2] 2 decay factors.  
%                    alpha(1) = decay for mu/std estimation
%                    alpha(2) = decay for averaging raw inputs (high-pass)
%   scl - [float] rescaling parameter for the median update.  N.B. max change in median/step = scl
% Outputs:
%   x - [nd x 1] filtered data,  x(t) = x(t) - fx(t)
%   s - [struct] updated filter state
if ( nargin<4 || isempty(scl) ) scl=1; end;
if ( nargin<5 || isempty(verb) ) verb=0; end;
if ( isempty(s) ) s=struct('sx',zeros(size(x)),'N',0,'x',0,'warmup',1,'i',0); end;
if ( any(alpha>1) ) alpha=exp(log(.5)./alpha); end; % convert to decay factor
s.N = alpha.*s.N + (1-alpha).*1; % weight accumulated so far for each alpha, for warmup
if ( any(s.N(:,1) < .5) || s.warmup ) % still in warmup, use mean estimator
   s.sx= alpha(:,1).*s.sx + (1-alpha(:,1)).*x;
   b   = s.sx./s.N(:,1);
   if ( all(s.N(:,1)>.5) ) % switch out of warmup mode
      s.warmup=0;
      s.sx    =s.sx./s.N(:,1);
   end
else  % switch to median estimator
   s.sx= s.sx + (1-alpha(:,1))*(min(scl,max(x-s.sx,-scl))); % step is limited to scl
   b   = s.sx;
end
if ( verb>0 ) fprintf('x=[%s]\ts=[%s]',sprintf('%g ',x),sprintf('%g ',b)); end;

if ( size(alpha,2)>1 ) % moving average filter the raw inputs
  if ( any(alpha(:,2)<0) ) %sliding window average
    if ( isscalar(s.x) ) s.x = zeros(numel(x),-min(alpha(:,2))); s.i=0; end;
    s.x(:,mod(s.i,size(s.x,2))+1) = x(:); % insert in ring buffer
    s.i = s.i+1; %update cursor location
    nf=size(s.x,2); if (s.i<nf) nf=s.i; end % num valid entries in window
    x   = reshape(sum(s.x,2)./nf,size(x)); % ave of this window  
  else % exp-weight MA
    s.x= alpha(:,2).*s.x + (1-alpha(:,2)).*x; % udpate running average
    x  = s.x./s.N(:,2); % smoothed output estimate 
  end
end;


x=x-b; % bias adapt 
if ( verb>0 ) fprintf(' => x_new=[%s]\n',sprintf('%g ',x)); end;
return;
function testCase()
x=cumsum(randn(2,1000),2);ox=x;

% simple test
s=[];fs=[];for i=1:size(x,2); [fx(:,i),si]=rbiasFilt(x(:,i),s,20,20); fs(:,i)=si.sx; s=si; end;
s=[];fs=[];for i=1:size(x,2); [fx(:,i),si]=biasFilt(x(:,i),s,20); fs(:,i)=si.sx./si.N; s=si; end;

% add in outliers and see how it does
x=ox+ (rand(size(x))>.8)*100;

clf;for si=1:size(x,1); subplot(size(x,1),1,si); plot([x(si,:);fx(si,:);fs(si,:)]');legend('x','filt(x)','bias');end;

