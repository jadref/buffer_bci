function [foldIdxs]=balanceYs(Ys,foldIdxs,dim,balfrac,perm)
% given and input set of indicator functions balance them for equal +/-1s
%
% [foldIdxs]=balanceYs(Ys,foldIdxs,dim,balfrac,perm)
%
% Inputs:
%  Ys      -- [n-d x L] set of +/-1,0 labels with L sub-problems in the last dim
%  foldIdxs-- [n-d x L x nFold] set of -1/0/+1 fold membership indicators (all Ys is training set)
%  dim     -- [int] sub-prod dim in Ys and foldIdxs, N.B. fold dim=subProbDim+1  (ndims(Ys))
%  balfrac -- is the fraction of +1s vs -1s, ie. balfrac = numel(Y>0)/numel(Y<0)
%         if balfrac<0 then only balance if *more* unbalanced than indicated,i.e.
%         numel(Y>0)/numel(Y<0) > balfrac && balfrac<1
%         numel(Y>0)/numel(Y<0) < balfrac && balfrac>1
%  perm    -- [bool] permute the order before selection (1)
%  balTst  -- [bool] balance the test set (0) **Not Implemented**
% Outputs:
%  foldIdxs-- [n-d x L x nFold] set of -1,0,+1 indicator functions with bal numbers of +/-1 entries 

% Code to balance the classes in the given input label set
if ( nargin < 2 || numel(foldIdxs)==1 ) foldIdxs=[]; end;
if ( nargin < 3 || isempty(dim) ) dim=ndims(Ys); end;
if ( nargin < 4 || isempty(balfrac) ) balfrac=1; end;
if ( nargin < 5 || isempty(perm) ) perm=1; end;
lb=1; ub=1; % are we upper/lower bound -- default to both
if ( balfrac<0 ) balfrac=-balfrac; lb=balfrac>=1; ub=balfrac<=1; end;
spD=dim; szY=size(Ys); szY(end+1:spD)=1; 
if ( isempty(foldIdxs) ) % default foldIdx if not given
   foldIdxs=-ones([szY 1]); 
   szfoldIdxs=size(foldIdxs); szfoldIdxs(end+1:numel(szY)+1)=1;
else % use given foldIdx, & try to ensure foldIdxs has the right size
   szfoldIdxs=size(foldIdxs); 
   if ( ndims(foldIdxs)<=numel(szY) )
      if ( size(foldIdxs,ndims(foldIdxs))~=szY(end)|| ndims(foldIdxs) < spD+1 ) 
         szfoldIdxs=[szfoldIdxs(1:end-1) ones(1,numel(szY)-ndims(foldIdxs)+1) szfoldIdxs(end)];
         foldIdxs  =reshape(foldIdxs,szfoldIdxs); % [ n-d x nSp x nFold ]
      else
         warning('assuming foldIdxs is [n-d x nSp x 1-fold] foldguide!');
      end
   end
end
nSp =szY(spD); nFold=szfoldIdxs(spD+1);
if ( prod(szfoldIdxs(1:end-1)) < prod(szY(1:spD)) ) % make foldIdxs into a per-subProblem per-fold format
   foldIdxs=repmat(foldIdxs,[szY(1:spD)./szfoldIdxs(1:end-1),1]); 
   szfoldIdxs=size(foldIdxs); szfoldIdxs(end+1:numel(szY)+1)=1;
end;
if ( spD>2 )
   Ys=reshape(Ys,[prod(szY(1:end-1)) szY(end)]); 
   foldIdxs=reshape(foldIdxs,[prod(szfoldIdxs(1:end-2)) szfoldIdxs(end-1:end)]);
end;
if ( nSp==2 && all(Ys(:,1)==-Ys(:,2)) ) nSp=1; end
for foldi=1:nFold; % loop over folds
np=shiftdim(sum(Ys>0 & foldIdxs(:,:,foldi)<0,1)); nn=shiftdim(sum(Ys<0 & foldIdxs(:,:,foldi)<0,1));
for spi=1:nSp; % loop over subProblems
   ri=[]; delIdxs=[];
   if ( ub & (np(spi) < nn(spi)*balfrac) )     % to many minus's
      if( perm ) ri=randperm(nn(spi)); else ri=1:nn(spi); end;
      ri=ri(1:floor(nn(spi)-np(spi)/balfrac)); 
      delIdxs=find(Ys(:,spi)<0 & foldIdxs(:,min(spi,end),foldi)<0);
   elseif ( lb & (np(spi) > nn(spi)*balfrac) ) % too many plus's
      if( perm ) ri=randperm(np(spi)); else ri=1:np(spi); end;
      ri=ri(1:floor(np(spi)-nn(spi)*balfrac));
      delIdxs=find(Ys(:,spi)>0 & foldIdxs(:,min(spi,end),foldi)<0);
   end
   foldIdxs(delIdxs(ri),spi,foldi)=0; % del extras from the set of valid points
end
end % folds
if ( nSp==1 && size(Ys,ndims(Ys))==2 ) foldIdxs(delIdxs(ri),2)=0; end; % make inv problem same
if ( numel(szY)>2 ) Ys=reshape(Ys,szY); foldIdxs=reshape(foldIdxs,[szY nFold]); end;
return;
%---------------------------------------------------------------------------
function []=testCase();
Ys=sign(randn(1000,1));
balI=balanceYs(Ys); [sum(Ys>0 &balI<0)./sum(Ys<0 &balI<0)]

% multi-subprob
Ys=sign(randn(1000,5)); [sum(Ys>0)./sum(Ys<0)]
foldIdxs=balanceYs(Ys,[],[],1); [sum(Ys>0 &foldIdxs<0)./sum(Ys<0 &foldIdxs<0)]
foldIdxs=balanceYs(Ys,[],[],.5); [sum(Ys>0 & foldIdxs<0 )./sum(Ys<0 & foldIdxs<0 )]
foldIdxs=balanceYs(Ys,[],[],2); [sum(Ys>0)./sum(Ys<0)]
% one sided balance
foldIdxs=balanceYs(Ys,[],[],-1); [sum(Ys>0 & foldIdxs<0)./sum(Ys<0 & foldIdxs<0)]
foldIdxs=balanceYs(Ys,[],[],-.5); [sum(Ys>0 & foldIdxs<0)./sum(Ys<0 & foldIdxs<0)]
foldIdxs=balanceYs(Ys,[],[],-2); [sum(Ys>0 & foldIdxs<0)./sum(Ys<0 & foldIdxs<0)]
% matrix balance
Ys=sign(randn(100,10,5)+.5);
foldIdxs=balanceYs(Ys); [msum(Ys>0 &foldIdxs<0,[1 2])./msum(Ys<0 &foldIdxs<0,[1 2])]
% foldGuide balance
foldIdxs=gennFold(Ys,10); 
sfoldIdxs=balanceYs(Ys,foldIdxs,.5); [sum(Ys>0 & sfoldIdxs(:,:,1)<0 )./sum(Ys<0 & sfoldIdxs(:,:,1)<0 ) sum(Ys>0 & sfoldIdxs(:,:,2)<0 )./sum(Ys<0 & sfoldIdxs(:,:,2)<0 )]

