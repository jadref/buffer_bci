function [X,odims]=msum(X,dims)
% multi-dimension sum
%
% [X,odims]=msum(X,dims)
if ( nargin < 2 || isempty(dims) ) 
   dims=find(size(X)>1,1,'first'); if( isempty(dims) ) dims=1;end;
end
dims(dims<0)=dims(dims<0)+ndims(X)+1;

sz=size(X); nd=ndims(X); 
outsz=sz; outsz(dims)=1; % size output should be

% find dims we can cat together, for efficiency
dims=sort(dims,'ascend'); dims(dims>ndims(X))=[];
nsz=sz(1:dims(1)); odims=dims; dims=odims(1);
for di=2:numel(odims); 
   if ( odims(di)==odims(di-1)+1 ) % consequetive, so squeeze out
      nsz(end)=nsz(end)*sz(odims(di));
   else % non-consequ, setup correctly
      nsz = [ nsz sz(odims(di-1)+1:odims(di)) ]; dims=[dims; numel(nsz)];
   end
end
nsz=[nsz sz(odims(end)+1:end)];
X = reshape(X,[nsz 1]);

% loop over non-consequ dims doing the sums
for di=1:numel(dims); X = sum(X,dims(di)); end

% reshape the output back to the right size
X = reshape(X,outsz);
return;
%----------------------------------------------------------------------------
function testCase()
X=randn(10,9,8);
sX=msum(X,[-1])
sX=msum(X,[1 -1])
sX=msum(X,[1 2])