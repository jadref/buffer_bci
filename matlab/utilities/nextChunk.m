function [idx,chnkStride,nchnks]=nextChunk(idx,sz,arg1,arg2)
% compute the next chunk index expression
%
% [idx,chnkStride]=nextChunk(idx,sz,[exdims,maxel]) % Usually 1st call
% OR
% [idx]=nextChunk(idx,sz,chnkStride); % Usually inner loop calls
%
% Inputs:
%  idx       -- the current index cellarray ([])
%  sz        -- the size of the matrix we're stepping over
%  exdims    -- dimensions excluded from the chunking    ([])
%  maxel     -- the maximum number of elments per chunk  (2e6)
%  chnkStride -- as returned from (nextChunk) summary info for
%                how to step over the chunks ([])
% Output:
%  idx       -- new index experssion
%  chnkStride -- the number of elements to step along for each dimension
%               of the matrix. (Use in subsequent calls to speed up operation)
%
% Example Usage:
%   X = randn(10,10,10,10,10);
%   [idx,chnkStride]=nextChunk([],size(X),100);
%   while ( ~iempty(idx) )
%        process(X(idx{:})); % do something with this chunk of X
%        idx=nextChunk(idx,size(X),chnkStride);
%   end;
nchnks=[]; % don't report normally
if ( nargin < 3 || isempty(arg1) || isscalar(arg1) || nargin==4 ) 
   % first calling format
   if ( nargin < 3 ) exdims=[]; else exdims=arg1; end;
   if ( nargin < 4 || isempty(arg2) ) MAXEL = 2e6; else MAXEL = arg2; end;
   %   [splitDim,splitStride,chnkStride,nchnks]=chunkSz(sz,exdims,MAXEL);
   stride=sz; N=prod(sz);
   if ( N<MAXEL ) % only bother if something to do
     nchnks=1; chnkStride=stride;
   else
     incDims=true(numel(sz),1);incDims(exdims)=false; % dims we could split along
     stride(exdims)=1;
     stride=[1 cumprod(stride(1:end-1))]*max(1,prod(sz(exdims)));
     stride(exdims)=inf; % exclude the excluded dims
                         % split along last dim >1 smaller steps
     splitDim=find(stride<=MAXEL & sz>1,1,'last');
     if ( isempty(splitDim) ) splitDim=find(incDims,1,'first'); end;
     splitStride = max(1,min(floor(MAXEL/(stride(splitDim))),sz(splitDim))); % # steps to take
                                                                             % Compute the summary info
     chnkStride=sz;
     chnkStride(splitDim)=splitStride; chnkStride(splitDim+1:end)=1; 
     chnkStride(exdims)=sz(exdims);
     nchnks    =ceil(sz(splitDim)./splitStride)*prod(sz(splitDim+find(incDims(splitDim+1:end))));
     chnkStride=int32(chnkStride);
   end
elseif ( numel(arg1) == numel(sz) ) 
   chnkStride=arg1;
else
   error('Incorrect calling format');
end;

if ( isempty(idx) )
  idx=cell(numel(sz),1); for i=1:numel(sz); idx{i}=int32(1:chnkStride(i)); end; % build index expression
%elseif ( ~iscell(idx) || numel(idx) ~= numel(sz) ) 
%   error('Idx must be cell array with numel(sz) elements');
elseif ( all(chnkStride==sz) )
  idx={};
else % Need to increment an existing idx
   chnkdims=find(chnkStride<sz);  % dims we're chunking along
   fin=true;
   for i=1:numel(chnkdims);
      d=chnkdims(i);
      idx{d}=idx{d} + chnkStride(d);
      if ( idx{d}(1) <= sz(d) ) 
         % ensure multi-idx dims don't go too far
         if( numel(idx{d})>1 && idx{d}(end)>sz(d) ) idx{d}(idx{d}>sz(d))=[]; end
         fin=false; break;         % terminate
      else
         idx{d}=int32(1:chnkStride(d));   % reset the counter
      end
   end
   
   if ( fin ) idx={}; end; % return empty index to indicate all done
end
return;


%------------------------------------------------------------------------
function [splitDim,splitStride,chnkStride,nchnks]=chunkSz(sz,exdims,MAXEL)
% Split matrix of size sz along dim with stride set with <maxel elements
%
% [splitDim,splitStride,chnkStride,nchnks]=chunkSz(sz[,maxel,exdims])
% Inputs:
%  sz      -- size of matrix to be split
%  maxel   -- maximum number of elements per split matrix (2e6)
%  exdims  -- set of dims along which we cannot split ([])
% Outputs:
%  splitDim    -- 1st dimension to split along (N.B. unit stride on rest)
%  splitStride -- maximum number of elements along splitDim to take at a time
%  chnkStride  -- [numel(sz) x 1] set of strides for each dimension
if ( nargin < 2 ) exdims=[]; end;
if ( nargin < 3 || isempty(MAXEL) ) MAXEL=2e6; end;
stride=sz;
incDims=true(numel(sz),1);incDims(exdims)=false; % dims we could split along
stride(exdims)=1;
stride=[1 cumprod(stride(1:end-1))]*max(1,prod(sz(exdims)));
stride(exdims)=inf; % exclude the excluded dims
% split along last dim >1 smaller steps
splitDim=find(stride<=MAXEL & sz>1,1,'last');
if ( isempty(splitDim) ) splitDim=find(incDims,1,'first'); end;
splitStride = max(1,min(floor(MAXEL/(stride(splitDim))),sz(splitDim))); % # steps to take
% Compute the summary info
chnkStride=sz;
chnkStride(splitDim)=splitStride; chnkStride(splitDim+1:end)=1; 
chnkStride(exdims)=sz(exdims);
nchnks    =ceil(sz(splitDim)./splitStride)*prod(sz(splitDim+find(incDims(splitDim+1:end))));
chnkStride=int32(chnkStride);
return;

%------------------------------------------------------------------------
function testCase()
sz=[10 10 10];  X=randn(sz);
[idx,chnkStride,nchks]=nextChunk([],sz,[],10);
while (~isempty(idx))
   X(idx{:});serialize(idx)
   idx=nextChunk(idx,sz,chnkStride);
end

[idx,chnkStride]=nextChunk([],sz,3,10); % excluding dim 3
while (~isempty(idx))
   X(idx{:});serialize(idx)
   idx=nextChunk(idx,sz,chnkStride);
end
