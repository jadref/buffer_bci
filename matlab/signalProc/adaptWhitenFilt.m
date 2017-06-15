function [X,state]=adaptWhitenFilt(X,state,alpha,verb,varargin);
% filter function implementing adaptive spatial whitening
if( nargin<2 ) state=[]; end;
if( nargin<3 ) alpha=[]; end; % default to single-trial whitener
if( nargin<4 || isempty(verb) ) verb=0; end;

if( isempty(state) ) state=struct('N',0,'sXX',0,'W',[]); end;
if( isempty(alpha) && isfield(state,'alpha') ) alpha=state.alpha; end;
if( isempty(alpha) ) alpha=0; end;

if( alpha>1 ) alpha=exp(log(.5)./alpha); end;

N=state.N; sXX=state.sXX;
if( verb>=0 && size(X,3)>10 ) fprintf('adaptWhitenFilt:'); end;
for ei=1:size(X,3); % auto-apply incrementally if given multiple epochs
  if( verb>=0 && size(X,3)>10 ) textprogressbar(ei,size(X,3)); end;
  Xei = X(:,:,ei);
  % compute average spatial covariance for this trial
  XXei= tprod(Xei,[1 -2 -3],[],[2 -2 -3])./size(Xei,2)./size(Xei,3); 
  % update the running estimate statistics
  N   = alpha.*N   + (1-alpha)*1;
  sXX = alpha.*sXX + (1-alpha)*XXei;

                                % updated estimate, with startup-protection
  XX  = sXX./N;
  % compute the whitener from the local adapative covariance estimate
  [U,s]=eig(double(XX)); s=diag(s); % N.B. force double to ensure precision with poor condition
  % select non-zero entries - cope with rank deficiency, numerical issues
  si = s>eps & ~isnan(s) & ~isinf(s) & abs(imag(s))<eps;
  if ( verb>1 ) fprintf('New eig:');fprintf('%g ',s(si));fprintf('\n'); end;
  W  = real(U(:,si))*diag(1./sqrt(s(si)))*real(U(:,si))'; % compute symetric whitener	 
  X(:,:,ei) = tprod(Xei,[-1 2 3 4],W,[-1 1]); % apply it to the data
end
if( verb>=0 && size(X,3)>10 ) fprintf('\n'); end;
% update the final return state
state.N=N; state.sXX=sXX; state.R=W; state.alpha=alpha;
return;
                                %----------------------------------
function testCase()
S=randn(10,1000,100);% sources
sf=randn(10,2);% per-electrode spatial filter
X =S+reshape(sf*S(1:size(sf,2),:),size(S)); % source+propogaged noise

                                % whiten-all-at-once
[Y,state]=adaptWhitenFilt(X);
[Y,state]=adaptWhitenFilt(X,[],10);
                                % whiten: incremental
[Yi(:,:,1),state]=adaptWhitenFilt(X(:,:,1),[],10);
for epi=2:size(X,3);
  [Yi(:,:,epi),state]=adaptWhitenFilt(X(:,:,epi),state);
end
mad(Y,Yi)
