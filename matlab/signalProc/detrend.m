function [X,dtm]=detrend(X,dim,order,wght,MAXEL)
% Linearly de-trend input, i.e. 0-mean and linear trends subtracted
%
% [X,dtm]=detrend(X,[dim,order,wght,MAXEL])
%
% Inputs:
%  X     -- n-d input matrix
%  dim   -- dimension of X to detrend along
%  order -- [int] order of detrending {1,2} (1)
%  wght  -- [size(X,dim),1] weighting matrix for the points in X(dim)
%  MAXEL -- max-size before we start chunking for memory savings
% Outputs:
%  X     -- detrended X
%  dtm   -- linear matrix used to detrend X
if ( nargin < 2 || isempty(dim) ) dim=find(size(X)>1,1,'first'); end;
if ( dim < 0 ) dim=ndims(X)+dim+1; end;
if ( nargin < 3 || isempty(order) ) order=1; end;
if ( nargin < 4 || isempty(wght) ) wght=1; end; wght=wght(:);
if ( nargin < 5 || isempty(MAXEL) ) MAXEL=2e6; end;

if ( order > 2 || order < 1) error('Only 1/2nd order currently'); end;
if ( size(X,dim)==1 ) dtm=[]; return; end;

% Compute a linear detrending matrix
xb  = [(1:size(X,dim))'-size(X,dim) ones(size(X,dim),1)]; % orthogonal target's to regress with
xbw = repop(xb,'.*',wght); % include weighting effect
dtm = inv([ xbw(:,1:end-1)'*xb(:,1:end-1) xbw(:,1:end-1)'*xb(:,end);
            xbw(:,end)'*xb(:,1:end-1)     xbw(:,end)'*xb(:,end)])*xbw';

szX=size(X);
[idx,chkStrides,nchks]=nextChunk([],szX,dim,MAXEL);
while ( ~isempty(idx) ) 
   Xch = X(idx{:});
   if ( order==2 )
      chidx={};for d=1:ndims(Xch); chidx{d}=1:size(Xch,d); end;
      Xch(chidx{1:dim-1},2:end,chidx{dim+1:end}) = diff(Xch,order-1,dim);
      Xch(chidx{1:dim-1},1    ,chidx{dim+1:end}) = Xch(chidx{1:dim-1},2,chidx{dim+1:end}); % BODGE
   end

   % comp scale and bias
   ab  = tprod(double(Xch),[1:dim-1 -dim dim+1:ndims(X)],dtm,[dim -dim],'n'); 
   % comp linear trend
   Xest= tprod(xb,[dim -dim],ab,[1:dim-1 -dim dim+1:ndims(X)],'n');
   Xch = Xch-Xest; % remove linear trend
   
   if( order==2 ) Xch=cumsum(Xch,dim); end
   X(idx{:})=Xch;
   
   idx=nextChunk(idx,szX,chkStrides);
end   

return;

%-----------------------------------------------------------------------------
function testCase()
f=cumsum(randn(1000,100)); dim=1;

clf; plot(f(:,1),'b'); hold on;

ff=detrend(f,1); % normal

ff=detrend(f,1,[],[1 zeros(1,size(f,1)-2) 1]); % weighted

ff=detrend(f,1,[],[1 ones(1,size(f,1)-2)*5e-2 1]); % weighted

ff=detrend(f,1,[],[],2000); % chunked

ff=detrend(f,1,[],mkFilter(size(f,1),[300 500])); % weighted

plot(ff(:,1),linecol());