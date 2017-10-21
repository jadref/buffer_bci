function [X,state,XXt]=adaptWhitenFilt(X,state,varargin);
% filter function implementing adaptive spatial whitening
%
% Options:
%   dim     - [int] dimensions to work along
%   center  - [bool]
%   detrend - [bool]
%   covFilt - [float] <1 = coefficient for the exp-weighted move average, >1 = half-life for the per-sample smoothing filter 
%                OR
%             {func args} = function to call to do the smoothing filter
%              SEE: biasFilt for example function format
%   ch_names -- {nCh x 1 str} channel names
%   ch_pos   -- [3 x nCh] positions of the channels
% TODO:
%   [X] make consistent with the other spatial-filtering function to specify the covariance filter in the same way...
%   [] Add method use robust covariance estimator, e.g. lediot-wolf
if( nargin<2 ) state=[]; end;
if( ~isempty(state) && isstruct(state) ) % ignore other arguments if state is given
  opts =state;
else
  opts=struct('center',0,'detrend',0,'covFilt','','filtstate','','verb',1,...
              'dim',[1 2 3],'ch_names','','ch_pos',[],'fs',[]);
  [opts]=parseOpts(opts,varargin);
end
dim=opts.dim;
szX=size(X); szX(end+1:max(dim))=1;
if( numel(dim)<3 ) nEp=1; else nEp=szX(dim(3)); end;

                                % set-up the covariance filtering function
covFilt=opts.covFilt; filtstate=opts.filtstate; 
if( ~isempty(covFilt) )
  if( ~iscell(covFilt) ) covFilt={covFilt}; end;
  if( isnumeric(covFilt{1}) ) % covFilt{1} is alpha for move-ave
    if(covFilt{1}>=1) covFilt{1}=exp(log(.5)./covFilt{1}); end; % convert half-life to alpha
    if(isempty(filtstate) )    filtstate=struct('N',0,'sxx',0);    end;
  end
end

% N.B. index expressions with int32 or bool types are **much** faster (particularly on Octave)
% make a index expression to extract the current epoch.
xidx  ={}; for di=1:numel(szX); xidx{di}=int32(1:szX(di)); end;

                % tprod-arguments for computing the channel-covariance matrix
tpIdx  = -(1:ndims(X)); tpIdx(dim(1)) =1; 
tpIdx2 = -(1:ndims(X)); tpIdx2(dim(1))=2; 

if( opts.verb>=0 && nEp>10 ) fprintf('adaptWhitenFilt:'); end;
for epi=1:nEp; % auto-apply incrementally if given multiple epochs
  if( opts.verb>=0 && nEp>10 ) textprogressbar(epi,nEp); end;
                                % extract the data for this epoch
  if( numel(dim)>2 ) % per-epoch mode
    xidx{dim(3)}=epi;
    Xei   = X(xidx{:});
  else % global mode
    Xei   = X;
  end;

  % pre-process the data
  if ( opts.center )       Xei = repop(Xei,'-',mean(Xei,dim(2))); end;
  if ( opts.detrend )      Xei = detrend(Xei,dim(2)); end;

                          % compute average spatial covariance for this trial
  XXt  = tprod(Xei,tpIdx,[],tpIdx2)./size(Xei,2)./size(Xei,3); % cov of the artifact signal: [nArt x nArt]

                           % smooth the covariance filter estimates if wanted
  if( ~isempty(covFilt) )
    if( isnumeric(covFilt{1}) ) % move-ave
      alpha           = covFilt{1}; % specified in samples
      alpha           = alpha.^size(Xei,dim(2)); % specified in data-packets
      filtstate.N     = alpha.*filtstate.N     + (1-alpha).*1;       % update weight
      filtstate.sxx   = alpha.*filtstate.sxx   + (1-alpha).*XXt;   % update move-ave                                
      XXt             = filtstate.sxx./filtstate.N;   % move-ave with warmup-protection
    else
      [XXt,filtstate]  =feval(covFilt{1},XXt,filtstate,covFilt{2:end});
    end
  end    

  % compute the whitener from the local adapative covariance estimate
  [U,s]=eig(double(XXt)); s=diag(s); % N.B. force double to ensure precision with poor condition
  % select non-zero entries - cope with rank deficiency, numerical issues
  si = s>eps & ~isnan(s) & ~isinf(s) & abs(imag(s))<eps;
  if ( opts.verb>1 ) fprintf('New eig:');fprintf('%g ',s(si));fprintf('\n'); end;
  sf = real(U(:,si))*diag(1./sqrt(s(si)))*real(U(:,si))'; % compute symetric whitener	 
                                % apply the filter to the data
  if( nEp>1 ) % per-epoch mode, update in-place
    X(xidx{:}) = tprod(sf,[-dim(1) dim(1)],Xei,[1:dim(1)-1 -dim(1) dim(1)+1:ndims(X)]);    
  else % global regression mode
    X = tprod(sf,[-dim(1) dim(1)],X,[1:dim(1)-1 -dim(1) dim(1)+1:ndims(X)]);
  end
end
if( opts.verb>=0 && size(X,3)>10 ) fprintf('\n'); end;
% update the final return state
state=opts;
state.R=sf;
state.dim=dim;
state.covFilt=covFilt;
state.filtstate=filtstate;
return;
                                %----------------------------------
function testCase()
S=randn(10,1000,100);% sources
sf=randn(10,2);% per-electrode spatial filter
X =S+reshape(sf*S(1:size(sf,2),:),size(S)); % source+propogaged noise

                                % whiten-all-at-once
[sf0,XX0,Y0]=whiten(X,1);
[Y,state,XX]=adaptWhitenFilt(X,[],'dim',[1 2]);
[Y,state]=adaptWhitenFilt(X,[],'covFilt',10);
                                % whiten: incremental
[Yi(:,:,1),state]=adaptWhitenFilt(X(:,:,1),[],'covFilt',10);
for epi=2:size(X,3);
  [Yi(:,:,epi),state]=adaptWhitenFilt(X(:,:,epi),state);
end
mad(Y,Yi)
