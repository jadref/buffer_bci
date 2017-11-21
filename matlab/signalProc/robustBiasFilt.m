function [x,s]=rbiasFilt(x,s,alpha,stdthresh)
% robust-bias removing filter (high-pass) based on outlier detection & limiting
%
%   [x,s,mu,std]=rbiasFilt(x,s,alpha,stdthresh)
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
%   stdthresh - [float] threshold for outlier detection in std-deviations.  (2)
% Outputs:
%   x - [nd x 1] filtered data,  x(t) = x(t) - fx(t)
%   s - [struct] updated filter state
if ( nargin<4 || isempty(stdthresh) ) stdthresh=2; end;
if ( nargin<4 || isempty(verb) ) verb=0; end;
if ( isempty(s) ) s=struct('sx',zeros(size(x)),'sx2',zeros(size(x)),'N',0,'x',0,'i',0); end;
if ( any(alpha>1) ) alpha(alpha>0)=exp(log(.5)./alpha(alpha>0)); end; % convert to decay factor

% update the stats
s.N  = alpha.*s.N        + (1-alpha).*1;

                                % outlier detection & thresholding
% outlier criteria
mu   = s.sx./s.N(:,1);
std=sqrt(abs((s.sx2-s.sx.^2./s.N(:,1))./s.N(:,1)));
std(std<eps)=1;
                             % threshold, features for which have enough info
goodIdx=s.N(:,1)>(1-alpha(:,1)); % TODO: better specification of this threshold?
if( any(goodIdx) ) % if enough data to trust the std-values
  if( numel(goodIdx)>1 ) % per feature learning rates
    x(goodIdx)    = min(max(x(goodIdx),mu(goodIdx)-std(goodIdx)*stdthresh),...
                        mu(goodIdx)+std(goodIdx)*stdthresh);
  else % single for all
    x    = min(max(x,mu-std*stdthresh),mu+std*stdthresh);
  end
end

% update stats with outlier-thresholded information
s.sx = alpha(:,1).*s.sx  + (1-alpha(:,1)).*x; % weighted sum of x
s.sx2= alpha(:,1).*s.sx2 + (1-alpha(:,1)).*x.*x;

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
return;

x=cumsum(randn(2,1000),2);

                                % insert some outliers
ox=x; out=rand(size(x))>.994; x(out) = x(out) + 100; 


% simple test
s=[];fs=[];for i=1:size(x,2); [fx(:,i),si]=rbiasFilt(x(:,i),s,100); fs(:,i)=si.sx/si.N; s=si; end;
% feature specific smoothers
s=[];fs=[];for i=1:size(x,2); [fx(:,i),si]=rbiasFilt(x(:,i),s,[exp(log(.5)/100);exp(log(.5)/1000)]); fs(:,i)=si.sx/si.N; s=si; end;

% double processing, output smoother + bias-adapt
s=[];fx=[];fs=[];ss=[];for i=1:size(x,2); [fx(:,i),si]=rbiasFilt(x(:,i),s,[100 20]); fs(:,i)=si.sx/si.N(:,1); ss(:,i)=si.x./si.N(:,2); s=si; end;

clf;for si=1:size(x,1); subplot(size(x,1),1,si); plot([x(si,:);fx(si,:);fs(si,:)]','linewidth',2);legend('x','filt(x)','bias');end;

