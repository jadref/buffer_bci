function [x,s]=biasFilt(x,s,alpha)
% bias removing filter (high-pass) removes slow drifts from inputs, with optional high-pass results
%
%   [x,s,mu,std]=biasFilt(x,s,alpha)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   alpha - [1 x 1] OR [nd x 1] exponiential decay factor for the moving average for 
%                   all [1x1] or each [ndx1] input feature
%           fx(t) = (\sum_0^inf x(t-i)*alpha^i)/(\sum_0^inf alpha^i)
%           fx(t) = (1-alpha) x(t) + alpha fx(t)
%         OR
%           [ndx2] 2 decay factors.  
%                    alpha(1) = decay for mu/std estimation
%                    alpha(2) = decay for averaging raw inputs (high-pass)
% Outputs:
%   x - [nd x 1] filtered data,  x(t) = x(t) - fx(t)
%   s - [struct] updated filter state
%
% Examples:
%     [x,s]=biasFilt(x,s,100);      % bias-adapt with 100 calls half-life move ave bias est
%     [x,s]=biasFilt(x,s,[100 20]); % bias-adapt with 100 calls half-life move ave bias est, and 20-call half-life smoothing of the result
%     [x,s]=biasFilt(x,s,[100 -20]); % bias-adapt with 100 calls half-life move ave bias est, and average last 20-calls for output
  
if ( nargin<4 || isempty(verb) ) verb=0; end;
if ( isempty(s) ) s=struct('sx',zeros(size(x)),'N',0,'x',0,'i',0); end;
if ( any(alpha>1) ) alpha(alpha>0)=exp(log(.5)./alpha(alpha>0)); end; % convert to decay factor

s.N = alpha.*s.N + (1-alpha).*1; % weight accumulated so far for each alpha, for warmup
s.sx=alpha(:,1).*s.sx + (1-alpha(:,1)).*x; % weighted sum of x
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

x=x-s.sx./s.N(:,1); % bias adapt
if ( verb>0 ) fprintf(' => x_new=[%s]\n',sprintf('%g ',x)); end;
return;
%-----------------------------------------------------------------------------
function testCase()
x=cumsum(randn(2,1000),2);

% simple test
s=[];fs=[];for i=1:size(x,2); [fx(:,i),si]=biasFilt(x(:,i),s,100); fs(:,i)=si.sx/si.N; s=si; end;
% feature specific smoothers
s=[];fs=[];for i=1:size(x,2); [fx(:,i),si]=biasFilt(x(:,i),s,[exp(log(.5)/100);exp(log(.5)/1000)]); fs(:,i)=si.sx/si.N; s=si; end;

clf;for si=1:size(x,1); subplot(size(x,1),1,si); plot([x(si,:);fx(si,:);fs(si,:)]','linewidth',2);legend('x','filt(x)','bias');end;

% double processing, output smoother + bias-adapt
s=[];fs=[];ss=[];for i=1:size(x,2); [fx(:,i),si]=biasFilt(x(:,i),s,[100 20]); fs(:,i)=si.sx/si.N(:,1); ss(:,i)=si.x./si.N(:,2); s=si; end;
% double processing, output moving-window + bias-adapt
s=[];fs=[];ss=[];for i=1:size(x,2); [fx(:,i),si]=biasFilt(x(:,i),s,[100 -20]); fs(:,i)=si.sx/si.N(:,1); ss(:,i)=sum(si.x,2)./size(si.x,2); s=si; end;
clf;for si=1:size(x,1); subplot(size(x,1),1,si); plot([x(si,:);fx(si,:);fs(si,:);ss(si,:)]','linewidth',2);legend('x','filt(x)','bias','smthx');end;

