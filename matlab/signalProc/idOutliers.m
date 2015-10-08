function [badInd,feat,threshs,stdfeat,mufeat]=idOutliers(X,dim,thresh,feat,maxIter,verb)
% identify outlining elements in a matrix using robust variance/mean computation 
%
% [badInd,feat,threshs,stdfeat,mufeat]=idOutliers(X,dim,thresh,feat,maxIter,verb)
%
% Inputs:
%  X      -- [n-d] data to identify outling elements of
%  dim    -- dimension(s) along which to look for outlying elements
%  thresh -- [2x1] threshold in data-std-deviations std-deviations to test to remove
%            1st element is threshold above (3), 2nd is threshold below (-inf)
%  idx    -- [Nx1] or [size(X,dim) bool] sub-set of indicies along dim to consider
%  maxIter-- [int] number of times round the remove+re-compute var loop (6)
%  feat   -- [str] which feature type to use {'mu','var'}  ('var')
%  summary-- additional descriptive info

if(nargin<2 || isempty(dim) )    dim=1;      end;
if(nargin<3 || isempty(thresh) ) thresh=3.5; end;
if(nargin<4 || isempty(feat)   ) feat='var'; end;
if(nargin<5 || isempty(maxIter)) maxIter=3;  end;
if(nargin<6 || isempty(verb) )   verb=0;     end;

szX=size(X);

% compute stds over this dim
rdims = setdiff(1:ndims(X),dim);
[stds mus]=mvar(X,rdims);
stds  = sqrt(abs(stds));
if ( prod(szX(rdims))==1 ) stds=mus; end; % deal with vector inputs

if ( strcmp(feat,'var') )   feat=stds;  % outlying variance
elseif (strcmp(feat,'mu') ) feat=mus;   % outlying mean
elseif ( isnumeric(feat) && isequal(size(feat),szX(dim)) )
   feat=feat;                           % outlying given feature value
else error('Unrecognised feature type: %s',feat);
end

badInd=false(size(feat)); 
threshs=[];
for iter=1:maxIter;
   % compute variance of std over this dim for the good points
   mufeat(iter)  = median(feat(~badInd)); 
   stdfeat(iter) = std(feat(~badInd));
   % plot(feat);hold on;plot([0;numel(feat)],[1;1]*[mufeat mufeat+stdfeat mufeat-stdfeat mufeat+thresh*stdfeat]);
   % remove anything too far from the mean std,std
   threshs(1,iter)=mufeat(iter)+thresh(1)*stdfeat(iter);
   badIndi = (feat > threshs(1,iter));
   if( numel(thresh)>1 ) % lower test
      threshs(2,iter)=mufeat(iter)-thresh(2)*stdfeat(iter);
      badIndi = badIndi | (feat < threshs(2,iter));
   end   
   if ( sum(badIndi|badInd) == sum(badInd) ) break; end; % no new pts added
   %if(verb>0)fprintf('%d) %d removed =  %d',iter,sum(badIndi-badInd),sum(badInd)); end;
   badInd = badInd | badIndi;
end
return;
%------------------------------------------------------------
function testCase()
X=randn(1000,1);
oI=randn(size(X))>1; X(oI)=X(oI)*5;
bad=idOutliers(X);
