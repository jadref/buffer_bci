function [wX]=windowData(X,start,width,dim)
% Slice the data-set X into (overlapping) equally sized windows
% 
% [wX]=windowData(X,start,width,dim)
% Inputs:
%  X      -- n-d data matrix
%  start  -- [nWin x 1] start index for the windows
%            OR
%            [nWin x size(X,dim(2:end))] start index for each entry in dim(2:end)
%  width  -- [1 x 1] number of samples to put in the window
%  dim    -- dimension to window down (+ dimension to vary win-locs down)
% Ouputs
%  wX     -- the windowed X with a new dimension added (after dim):
%             [size(X,1:dim-1) width numel(start) size(X,dim+1:end)]
if ( nargin < 4 || isempty(dim) ) dim=find(size(X)>1,1); end;
if ( nargin < 3 ) error('Insufficient arguments'); end;

start = int32(start); width=int32(width); % convert to int32 for faster indexing
if( size(start,1)==1 && size(start,2)>1 && numel(dim)==1 ) start=start(:); end;
if( size(start,2)>1 && numel(dim)==1 )
  if ( ndims(X)>dim(1) ) 
    dim=[dim dim+1]; 
    warning(sprintf('Start is 2-d but you didnt tell me which dim to use, assumed %d',dim(2)));
  else
    error('Start is n-d but you havent told me which dims to use!');
  end
end

sizeX=size(X);
% check if we can get away with just a reshape....
if( start(1,1)==1 && start(end,1)==size(X,dim(1))-width+1 && ...
    all(all(diff(start,1,1) == width)) )
   wX = reshape(X,[sizeX(1:dim(1)-1) width  size(start,1) sizeX(dim(1)+1:end)]);
else
   % pre-allocate array to hold the result
   if ( islogical(X) )
      wX = false([sizeX(1:dim(1)-1) width size(start,1) sizeX(dim(1)+1:end)]);
   else
      wX = zeros([sizeX(1:dim(1)-1) width size(start,1) sizeX(dim(1)+1:end)],class(X));
   end
   % Build index expressions, 1 for extraction and 1 for insertion
   % First the common bits
   for i=1:dim(1)-1; Xidx{i} = 1:size(X,i); wXidx{i} = Xidx{i}; end; 
   for i=dim(1)+1:ndims(X); Xidx{i}= 1:size(X,i); wXidx{i+1} = Xidx{i}; end;
   % Now the different bits.
   wXidx{dim(1)}=1:width;
   
   % Now use these experssions to do the window extraction
   for i=1:size(start,1);
      idxi=0:width-1; idxi(idxi+start(i,1)<=0)=[]; idxi(start(i,1)+idxi>size(X,dim(1)))=[]; % zero pad ends
      if ( numel(dim)==1 || size(start,2)==1 ) 
         Xidx{dim(1)} =start(i,1)+idxi; 
         wXidx{dim(1)}=idxi+1;
         wXidx{dim(1)+1}=i;
         wX(wXidx{:})=X(Xidx{:}); % do the extraction
      else % alternative code for when spec per-dim2 start positions
         for j=1:size(X,dim(2));
            Xidx{dim(2)}=j;            
            if( dim(2)<dim(1) ) wXidx{dim(2)}=j; else wXidx{dim(2)+1}=j; end;
            Xidx{dim(1)}=start(i,j)+(0:width-1);
            wXidx{dim(1)+1}=i;
            wX(wXidx{:})=X(Xidx{:}); % do the extraction            
         end
      end
   end
end
return;
%---------------------------------------------------------------------------
function testCase;
nCh=2; nSamp=100; N=3;
X=randn(nCh,nSamp,N);

% Test the reshape case..
width=25; start=1:width:nSamp;
wX = windowData(X,start,width,2);

% Test the non-reshape case
width = 50; start=(1:floor(width/2):nSamp-width+1)';
wX = windowData(X,start,width,2);

% Test with per-dim starts
wX = windowData(X,repmat(start,1,N),width,[2 3]);
