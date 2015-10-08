function [epsilion]=binomial_confidence(N,delta,p,corr)
% Compute confidence bound for binomial variates, e.g. classification performance
%
% [epsilion]=binomial_confidence(N,delta,p,corr)
% N     - number samples
% delta - probability true value within given bound, ie.confidence level (.05)
% p     - value to estimate bound about (.5)
% corr  - (bool) correction for small sample size (true)
%
% Based on the central limit approximation as outlined on the wikipedia page:
%    http://en.wikipedia.org/wiki/Binomial_proportion_confidence_interval
if ( nargin < 2 ) delta=.05; end;
if ( nargin < 3 ) p=.5; end;
if ( nargin < 4 ) corr=1; end
if ( any(N*p < 5) || any(N*(1-p)< 5) ) warning('Normal approx may be invalid'); end;
% find the z-score for this confidence bound
h=.01;xs=[0:h:10]; normcdf=.5+cumsum(exp(-.5*(xs).^2).*h./sqrt(2*pi));normcdf=normcdf+min(0,(1-normcdf(end)));
z_delta = xs(find(normcdf>1-delta/2,1));
% compute the bound
if( corr ) p=(p*N+2)/(N+4); N=N+4; end; % use the Agresti-Coull correction, "add 2 hits and 2 misses"
epsilion= z_delta*sqrt(p.*(1-p)./N);
