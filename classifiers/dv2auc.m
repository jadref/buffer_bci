function [res,sidx]=dv2auc(Y,dv,dim,sidx,dvnoise,verb)
% Compute the AUC values
%
% [auc,sidx]=dv2auc(labels,pred,[dim,sidx,dvnoise,verb])
%
% Warning: this only works for *real uniquely-valued* dv's *and* when Y has 2 classes!
% 
% Inputs:
%  labels  - [N x 1] the vector of target labels, *must* be +1/-1 or 0
%  pred    - [n-d with size(dim)==N] array of decision values for comparsion
%  dim     - the dimension along dv to compute the scores, (1) 
%  sidx    - indices to sort the predicted values.  (Use this to save 
%            computation when calling auc repeatedly with the same pred
%            but different labels, e.g. for multi-class)
%  dvnoise - [bool] add noise to the dv's to ensure dv's are unique (0)
%  verb    - [1x1] verbosity level                                  (1)
% Outputs:
%  auc - the area under the roc curve, [ size(dv) ] except size(auc,dim)=1
%  sidx- indices to sort the dv values, 
%        N.B. dv(sidx) gives the thresholds for ptn/ptp
MAXEL=2e6;
if ( nargin < 5 || isempty(dvnoise) ) dvnoise=0; end;
if ( nargin < 6 || isempty(verb) ) verb=1; end;
if ( nargin < 3 || isempty(dim) ) dim=find(size(dv)>1,1); end;
if ( dim < 0 ) dim = ndims(dv)+dim+1; end;
if ( nargin < 4 || isempty(sidx) )
   if ( numel(dv) <= MAXEL ) % Small enough to do in 1 pass
     if ( dvnoise ) dv=dv+dv*(rand(size(dv))-.5)*1e-5*max(1,dv); end;
     [sdv,sidx]=sort(dv,dim,'ascend'); sidx = int32(sidx); clear sdv;
   else % chunk instead      
      dvsz=size(dv); nd=ndims(dv);
      if ( verb>0 ) fprintf('AUC:'); ci=0; end;
      if ( nargout > 1 ) sidx=int32(dv); end; % pre-alloc too hold result
      [idx,chkStrides,nchnks]=nextChunk([],dvsz,dim,MAXEL);
      while ( ~isempty(idx) ) 
        dvidx=dv(idx{:});
        if ( dvnoise ) dvidx=dvidx+dvidx*(rand(size(dvidx))-.5)*1e-5*max(1,dvidx); end;
         if ( nargout > 1 ) 
            [resi,sidxi]=dv2auc(Y,dvidx,dim);
            sidx(idx{:})=sidxi; 
         else
           resi=dv2auc(Y,dvidx,dim);
         end
         clear dvidx;
         idx{dim}=1; res(idx{:})=resi; % store the result
         idx{dim}=1:dvsz(dim);
         idx=nextChunk(idx,dvsz,chkStrides); % get next chunk
         if( verb>0 ) ci=ci+1; textprogressbar(ci,nchnks); end;
      end
      if( verb>0 ) fprintf('\n'); end;
      return; % return the result we've computed
   end
end
if ( ndims(Y)>2 || min(size(Y))~=1 || ~all(Y(:)==-1 | Y(:)==0 | Y(:)==1) ) 
   error('Y must be a vector of +/-1 target labels');   
end
Y   = int8(Y);      % only the sign matters
np  = sum(Y>0); if ( np==0 ) np=eps; end;
nn  = sum(Y<0); if ( nn==0 ) nn=eps; end;
sY  = reshape(Y(sidx),size(sidx));  % true labels sorted in dv order
ptn = single(cumsum(sY<0,dim)); 
nddv= ndims(dv); if ( nddv==1 && size(dv,2)==1 ) nddv=1; end; % correct num dv dims for [Nx1] case
res = tprod(ptn,[1:dim-1 -dim dim+1:nddv],single(sY>0),[1:dim-1 -dim dim+1:nddv],'n')./(np*nn);
return;

%----------------------------------------------------------------------
function testCase()
Y=sign(randn(100,1));
dv=randn(100,100);
a =dv2auc(Y,dv,1)
b =dv2auc(Y,dv,2)
