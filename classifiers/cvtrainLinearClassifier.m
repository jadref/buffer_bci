function [classifier,res,Y]=cvtrainLinearClassifier(X,Y,Cs,fIdxs,varargin)
% train a regularised linear classifier with reg-parameter tuning by cross validation
% 
% [classifier,res]=trainLinearClassifier(X,Y,Cs,fIdxs,varargin)
%
% N.B. use applyLinearClassifier to apply the learned model to new data.
%
% Inputs:
%  X - [n-d float] the data to classify/train on
%  Y - [size(X,dim) x 1] set of 1:nSp per trial labels
%      OR
%      [size(X,dim) x nSp] set of -1/0/+1 per-subproblem labels, where 0 indicates an ignored point
%  Cs      - [1 x nCs] set of penalties to test                            ([10^(-3:3) 0])
%  fIdxs   - [size(Y,1) x nFold] logical matrix indicating which trials
%            to use in each fold, 
%               -1 = training trials, 0 = excluded trials,  1 = testing trials
%            OR
%            [1 x 1] number of folds to use (only for Y=trial labels).     (10)
%            or
%            [size(Y) x nFold x nCls] logical matrix indicating trials for each sub-prob per fold
%  spMx   - [nSp x nCls] mapping from clases into sub-problems to train.    (mkspMx(1:nCls,'1vR'))
%              N.B. see mkspMx for how to make a sub-problem matrix
% Options:
%  dim    - [int] the dimension(s) of X which contain the trials            (ndims(X))
%  objFn  - [str] which objetive function to optimise,                      ('klr_cg')
%  Cscale - [float] scaling parameter for the penalties                     (.1*var(X))
%             N.B. usually auto computed from the data, set to 1 to force input Cs  
%  balYs  - [bool] balance the labels of sets                               (0)
%  binsp  - [bool] do we break multi-class problems into sets of binary problems (1)
%  spType - [str] sub-problem decomposition to use for multi-class. one-of '1v1' '1vR' ('1v1')
%  spKey  - [Nx1] set of all possible label values                          ([])
%  spMx   - [nSp x nClass] encoding/decoding matrix to map from class labels to/from binary 
%           subProblems                                                     ([])
%  cv2    - [bool] use double nested cross-validation to produce performance estimates? (0)
%           Note: use the cv2trainFn option 'nInner' to set the number of inner folds
% Outputs:
%  classifier -- [struct] containing all the information about the linear classifier
%           |.w      -- [size(X) x nSp] weighting over X (for each subProblem)
%           |.b      -- [nSp x 1] bias term
%           |.dim    -- [ind] dimensions of X which contain the trails
%           |.spMx   -- [nSp x nClass] mapping between sub-problems and input classes
%           |.spKey  -- [nClass] label for each class in the spMx, thus:
%                        spKey(spMx(1,:)>0) gives positive class labels for subproblem 1
%           |.spDesc -- {nSp} set of strings describing the sub-problem, e.g. 'lh v rh'
%           |.binsp  -- [bool] flag if this is treated as a set of independent binary sub-problems
%  res   -- [struct] results structure as returned by cvtrainFn
%
% See also: cvtrainFn, cv2trainFn, lr_cg, klr_cg, l2svm_cg, rls_cg
opts=struct('objFn','lr_cg','dim',-1,'spType','1vR','spKey',[],'spMx',[],'zeroLab',0,...
            'balYs',0,'verb',0,'Cscale',[],'compKernel',0,'binsp',1,'rawdv',0,'cv2',0);
[opts,varargin]=parseOpts(opts,varargin);
if( nargin < 3 ) Cs=[]; end;
if( nargin < 4 || isempty(fIdxs) ) fIdxs=10; end;

dim=opts.dim; if ( isempty(dim) ) dim=ndims(X); end; % default to 
dim(dim<0)=dim(dim<0)+ndims(X)+1; % convert negative to positive indicies

if( ndims(Y)==2 && size(Y,1)==1 && size(Y,2)>1 ) Y=Y'; end; % col vector only
% build a multi-class decoding matrix
spKey=opts.spKey; spMx =opts.spMx;
if ( ~isempty(spKey) && ~isempty(spMx) && isnumeric(spMx) ) % sub-prob decomp already done, so trust it
  if ( ~all(Y(:)==-1 | Y(:)==0 | Y(:)==1) ) 
    error('spKey/spMx given but Y isnt an set of binary sub-problems');
  end

% already a valid binary problem indicator matrix
elseif ( isnumeric(Y) &&  all(Y(:)==-1 | Y(:)==0 | Y(:)==1) && ~(size(Y,2)==1 && opts.zeroLab && any(Y(:)==0)) ) 
  if ( size(Y,2)==1 ) spKey=[1 -1]; spMx =[1 -1];   % binary problem
  else                spKey=[1:size(Y,2)]; spMx=spKey; end;
elseif ( opts.binsp ) % decompose into set of binary problems
  if ( isempty(spMx) ) spMx=opts.spType; end;
  [Y,spKey,spMx]=lab2ind(Y,spKey,spMx,opts.zeroLab); % convert to binary sub-problems
end
spDesc=[];
if ( ~isempty(spMx) && ~isempty(spKey) )
  spDesc=mkspDesc(spMx,spKey);
end
  
% build a folding -- which is label aware, and aware of the sub-prob encoding type
if ( numel(fIdxs)==1 ) fIdxs=gennFold(Y,fIdxs,'dim',numel(dim)+1); end;
if ( opts.balYs ) [fIdxs] = balanceYs(Y,fIdxs); end % balance the folding if wanted

oX=X; odim=dim; szX=size(X); szY=size(Y); szF=size(fIdxs);
if ( numel(dim)>1 ) % make n-d problem into 1-d problem
  X=reshape(X,[prod(szX(1:min(dim)-1)) prod(szX(dim))]);
  Y=reshape(Y,[prod(szY(1:numel(dim))) szY(numel(dim)+1:end) 1]);
  % scale up fIdxs to Y size if necess
  if ( any(szF(1:numel(dim))==1) && any(szF(1:numel(dim))~=szY(1:numel(dim))) )
     fIdxs=repmat(fIdxs,[szY(1:numel(dim))./szF(1:numel(dim)) ones(1,ndims(fIdxs)-numel(dim))]);
     szF=size(fIdxs); % new size
  end
  fIdxs=reshape(fIdxs,[prod(szY(1:numel(dim))) szF(numel(dim)+1:end) 1]);
  dim=2; % now trial dim is 2nd dimension
end

% estimate good range hyper-params
% N.B. ONLY run after the flatten to 2-d inputs!
Cscale=opts.Cscale;
if ( isempty(Cscale) || isequal(Cscale,'l2') )  Cscale=CscaleEst(X,2,[],0);
elseif ( isequal(Cscale,'l1') )                 Cscale=sqrt(CscaleEst(X,2,[],0));
end
if ( isempty(Cs) ) Cs=[5.^(3:-1:-3)]; end;

% compute the kernel if needed for kernel methods
if ( opts.compKernel ) 
   % compute kernel
   if ( opts.verb>0 ) fprintf('CompKernel..');  end;
   X = compKernel(X,[],'linear','dim',dim);
   if ( opts.verb>0 ) fprintf('..done\n'); end;
   % call cvtrain to do the actual work
   % N.B. note we use dim 2 because of the kernel transformation
   if ( opts.cv2 ) 
     res=cv2trainFn(opts.objFn,X,Y,Cscale*Cs,fIdxs,'dim',2,'verb',opts.verb,'binsp',opts.binsp,varargin{:}); 
   else
     res=cvtrainFn(opts.objFn,X,Y,Cscale*Cs,fIdxs,'dim',dim,'verb',opts.verb,'binsp',opts.binsp,varargin{:}); 
   end   
else
   % call cvtrain to do the actual work
   if ( opts.cv2 ) 
     res=cv2trainFn(opts.objFn,X,Y,Cscale*Cs,fIdxs,'dim',dim,'verb',opts.verb,'binsp',opts.binsp,varargin{:}); 
   else
     res=cvtrainFn(opts.objFn,X,Y,Cscale*Cs,fIdxs,'dim',dim,'verb',opts.verb,'binsp',opts.binsp,varargin{:}); 
   end
end


% Extract the classifier weight vector(s)
% best hyper-parameter for all sub-probs, N.B. use the same C for all sub-probs to ensure multi-class is OK
if ( isfield(res,'opt') && isfield(res.opt,'soln') ) % optimal calibrated solution trained on all data
  for isp=1:numel(res.opt.soln); % get soln for each subproblem
    soln  = res.opt.soln{isp};
    W(:,isp) = soln(1:end-1); b(isp)=soln(end);
  end
else
  if ( opts.binsp ) 
    [opttstbin,optCi]=max(mean(res.tstbin,2)+mean(res.tstauc,2),[],3); 
  else
    [opttstbin,optCi]=max(mean(res.tstbin,2),[],3); 
  end
  for isp=1:size(Y,2); % get soln for each subproblem
    if ( isfield(res.soln) )
      soln  = res.soln{isp,optCi(isp)}; 
    elseif ( isfield(res.fold,'soln') ) % only per-fold solutions available. pick the first
      soln  = res.fold.soln{isp,optCi(isp)}; 
    end
    W(:,isp) = soln(1:end-1); b(isp)=soln(end);      
  end
end
if ( ~opts.compKernel ) % input space classifier, just extract
   W=reshape(W,[szX(1:min(odim)-1) size(W,2)]);
else % kernel method. extract the weights
   if ( numel(odim)>1 ) W=reshape(W,[szX(odim) size(W,2)]); end;
   Xidx=1:ndims(X); Xidx(odim)=-odim; % convert from dual(alpha) to primal (W)
   W   = tprod(oX,Xidx,W,[-odim ndims(X)+1]);
end

% put all the parameters into 1 structure
if ( iscell(spKey) ) spKey={spKey}; end; % BODGE: need double nest cell-arrays when making structs
classifier = struct('W',W,'b',b,'dim',dim,'spMx',spMx,'spKey',spKey,'spDesc',{spDesc},'binsp',opts.binsp,'rawdv',opts.rawdv);
return;
%-----------------------------------------------------------------------------
function testCase()

[X,Y]=mkMultiClassTst([-1 0 0 0; 1 0 0 0; .2 .5 0 0],[400 400 50],[.3 .3 0 0; .3 .3 0 0; .2 .2 0 0],[],[-1 1 1]);
[classifier,res]=cvtrainLinearClassifier(X,Y,[],10);
plotLinDecisFn(X,Y,classifier.W,classifier.b)
% 2d features
X=reshape(X,[2 2 size(X,2)]);
[classifier,res]=cvtrainLinearClassifier(X,Y,[],10);
[classifier,res]=cvtrainLinearClassifier(X,Y,[],10,'objFn','lr_cg','compKernel',0); % non-kernel method
% 2d epochs
szX=size(X); X=reshape(X,[szX(1:end-1) szX(end)/2 2]); Y=reshape(Y,size(Y,1)/2,2);
[classifier,res]=cvtrainLinearClassifier(X,Y,[],10,'dim',[-2 -1]);
[classifier,res]=cvtrainLinearClassifier(X,Y,[],10,'objFn','lr_cg','compKernel',0,'dim',[-2 -1]);

f=applyLinearClassifier(X,classifier);



[ans,optCi]=max(res.tstbin,[],3);  % check the results are identical
clf;plot([res.f(:,1,optCi),f2(:)]);

% multi-class test
[X,Y]=mkMultiClassTst([-1 0; 1 0; .2 .5],[400 400 50],[.3 .3; .3 .3; .2 .2],[],[1 2 3]);[dim,N]=size(X);
[classifier,res]=cvtrainLinearClassifier(X,Y,[],10,'spType','1vR');
[classifier,res]=cvtrainLinearClassifier(X,Y,[],10,'spType','1v1');
fldD = n2d(res.fold.di,'fold'); spD = n2d(res.fold.di,'subProb');
cvmcPerf(Y,res.fold.f,[1 spD fldD],res.fold.di(fldD).info.fIdxs,classifier.spMx,classifier.spKey)
