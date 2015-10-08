function [x2,idx]=subsample(x,N,dim,centbins,MAXEL)
% Simple function to sub-sample a time series using an bin-averaging technique
% [sx,idx]=subsample(x,N,dim)
% Note: we assume 
%  a) that input values are average over the *preceeding* 1 unit bin
%  b) output values are then the average over the preceeding bin width
%
% [x2,idx]=subsample(x,N[,dim,centbins,MAXEL])
% Inputs:
%  x    -- n-d matrix to sub-sample
%  N    -- output size along the dimension we want to sub-sample
%  dim  -- the dimension of x to subsample along
%  centbins -- report idx as the center of the new bin, rather than its end
%  MAXEL-- max number of elements to process at a time for memory usage
% Outputs:
%  x2   -- the subsampled x, [ size(X) with size(x2,dim)==N ]
%  idx  -- position of the new bin center in the input linear index. 
%          N.B. this is not necessarially an integer!
if ( nargin < 3 || isempty(dim) ) dim=find(size(x)>1,1,'first'); end;
if ( dim < 0 ) dim=ndims(x)+dim+1; end;
if ( nargin < 4 || isempty(centbins) ) centbins=0; end;
if ( nargin < 5 || isempty(MAXEL) ) MAXEL=2e6; end;

if ( isscalar(N) )
   wdth = (size(x,dim))/N;
   idx  = wdth:wdth:size(x,dim);
   %idx  = linspace(0,size(x,dim),N+1); idx(1)=[];
   %wdth = (size(x,dim))/N; % width each bin
else % explicit locations -- N.B. *must* be equal spaced!
   wdth=diff(N);
   if(any(abs(diff(wdth))>1e-3)) 
      warning('sample boundarys not equally spaced!');
   else
      wdth=wdth(1);
   end
   idx  = N; centbins=0;
end

szx = size(x);
x2 = zeros([szx(1:dim-1) numel(idx) szx(dim+1:end)],class(x)); % pre-alloc
[ckidx,allStrides]=nextChunk([],size(x),dim,MAXEL);
while ( ~isempty(ckidx) ) 
   
   x2idx=ckidx; x2idx{dim}=1:size(x2,dim); % assign index      
   [x2(x2idx{:})]=subsamp(x(ckidx{:}),idx,dim,wdth);
   
   ckidx=nextChunk(ckidx,size(x),allStrides);
end

if ( centbins ) idx=idx-wdth/2+.5; end;
return;

%---------------------------------------------------------------------------
% Inner fucntion to do the actual work
function [x2,idx]=subsamp(x,idx,dim,wdth)
szx = size(x); 
for i=1:numel(szx); subs{i}=1:szx(i); end; 
subs{dim}=ceil(idx); % make indices

% remove constant terms to stop rounding issues
mu   = mean(x,dim);
x    = repop(x,'-',mu);

% Compute the whole sample contributions, i.e. assume bins end on sample bounds
csx  = cumsum(x,dim); csx=csx(subs{:});
x2   = diff(csx,1,dim);
subs1= subs;subs1{dim}=1; x21=csx(subs1{:}); % fix first entry
clear csx; % save mem

% Take account of the sub-sample contributions at start/end each bin
if ( any(idx~=ceil(idx)) )
   df  = shiftdim((ceil(idx)-idx)',-dim+1);
   df  = repop(x(subs{:}),'.*',df);
   x2  = x2 - diff(df,1,dim);
   x21 = x21-(ceil(idx(1))-idx(1))*x(subs1{:}); % fix first entry
   clear df; % save mem
end

% Add the first entry to the re-sampled result
x2   = cat(dim,x21,x2);


% Now compute the averages
if( isa(x2,'single') ) wdth=single(wdth); end;
x2   = x2./wdth;

% undo the centering
x2   = repop(x2,'+',mu);
return

   
%---------------------------------------------------------------------------
function testCase()
X=randn(2,100,4);X=cumsum(X,2); X=single(X);
clf;plot(1:size(X,2),X(:,:,1)','LineWidth',3);hold on;
[T,idx]=subsample(X,10,2);plot(idx,T(:,:,1)',linecol);
[T,idx]=subsample(X,15,2);plot(idx,T(:,:,1)',linecol);
[T,idx]=subsample(X,20,2);plot(idx,T(:,:,1)',linecol);
[T,idx]=subsample(X,40,2);plot(idx,T(:,:,1)',linecol);
[T,idx]=subsample(X,50,2);plot(idx,T(:,:,1)',linecol);
[T,idx]=subsample(X,60,2);plot(idx,T(:,:,1)',linecol);
[T,idx]=subsample(X,80,2);plot(idx,T(:,:,1)',linecol);
[T,idx]=subsample(X,90,2);plot(idx,T(:,:,1)',linecol);
[T,idx]=subsample(X,99,2);plot(idx,T(:,:,1)',linecol);
[T,idx]=subsample(X,100,2);plot(idx,T(:,:,1)',linecol);

% Test with chunking
[T,idx]=subsample(X,10,2,[],200);plot(idx,T(:,:,1)',linecol);
[T,idx]=subsample(X,15,2,[],200);plot(idx,T(:,:,1)',linecol);
[T,idx]=subsample(X,20,2,[],200);plot(idx,T(:,:,1)',linecol);

% test with large offsets to cause rounding errors
X=randn(2,1000,4);X=cumsum(X,2); X=X+1e6; X=single(X);
clf;plot(1:size(X,2),X(:,:,1)','LineWidth',3);hold on;
[T,idx]=subsample(X,250,2);plot(idx,T(:,:,1)',linecol);
