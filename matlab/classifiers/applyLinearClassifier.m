function [f,fraw]=applyLinearClassifier(X,classifier)
% apply a linear classifier to some data
% 
%   [f,fraw] = applyLinearClassifier(X,classifier)
%
% Inputs:
%   X -- [n-d] data matrix.  
%     N.B. *must* have trials in same dimensions as classifier.dim, but these can be unit sized
%  classifier -- [struct] a structure containing the classifier information
% Outputs:
%  f  -- [size(X,dim) x nCls] set of decision values for each trial for each classifier
%  fraw -[size(X,dim) x nSp] set of pre-binary sub-problem decision values

if ( isfield(classifier,'dim') ) dim=classifier.dim; else dim=ndims(X)+1; end;
Xidx=-(1:ndims(X)); Xidx(dim)=1:numel(dim);
Widx=-(1:ndims(classifier.W)); 
if( dim==ndims(X) ) Widx(dim)=numel(dim)+1; 
else Widx(dim)=0; Widx(max(ndims(X)+1,ndims(classifier.W)))=numel(dim)+1;
end
fraw = tprod(X,Xidx,classifier.W,Widx,'n');      % apply the weight vector
fraw = repop(fraw,'+',classifier.b);                % include the bias

%fprintf('binDVs: %s\n',sprintf('%.2f\t',fraw));

% apply the multi-class decoding procedure if wanted
f=fraw;
if( isfield(classifier,'spMx') && ~isempty(classifier.spMx) && ~isequal(classifier.spMx,[1 -1]) && ...
    ~(isfield(classifier,'rawdv') && isequal(classifier.rawdv,1)) ) 
   f = tprod(f,[1 -2],classifier.spMx,[-ndims(f) 2],'n');
   f = f./mean(sum(classifier.spMx~=0));
end

%-----------------------------------------------------------------------------
function testCase()

% binary
[X,Y]=mkMultiClassTst([-1 0; 1 0; .2 .5],[400 400 50],[.3 .3; .3 .3; .2 .2],[],[-1 1 1]);[dim,N]=size(X);
[classifier,res]=cvtrainLinearClassifier(X,Y,[],10);

f2=applyLinearClassifier(X,classifier)


% 3-class
[X,Y]=mkMultiClassTst([-1 0; 1 0; .2 .5],[400 400 50],[.3 .3; .3 .3; .2 .2],[],[1 2 3]);[dim,N]=size(X);
[classifier,res]=cvtrainLinearClassifier(X,Y,[],10);

f2=applyLinearClassifier(X,classifier)
[ans,c]=max(f2,[],2);

