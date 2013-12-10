function K = compKernel(X,Z,kerType,varargin)
% compute a kernel matrix
%
%K = kernel(X,Z,kerType,[options,par1,par2,...])
%
%Inputs:
% X - [n-d] input objects
% Z - [n-d] input objects
% kerType: kernel type. this is either an actual kernel matrix, or String.
%      'linear'  - Linear           K(i,j) = X(i,:)*Z(j,:)
%      'poly'    - Polynomial       K(i,j) = (X(i,:)*Z(j,:)+par(2))^par(1)
%      'rbf'     - RBF              K(i,j) = exp(-|X(i,:)-Z(j,:)|^2/(2*par))
%                 N.B. par should approx l2 btw points in X, i.e. par ~= .1*var(X)
%      'par'     - par holds kernel K(i,j) = par(i,j)
%      'x'       - X holds kernel   K(i,j) = X(i,j)
%      @kerfn    - function_handle to function 'func' such that : 
%                      K(i,j)=func(X,Z,varargin)
%  varargin - additional hyper-parameters to use in the kernel computation
%Options:
% dim -- the dimension along which trials lie in X,Z              (1)
% 
% N.B. use nlinear, npoly, nrbf, etc. to compute the normalised kernel, 
%      i.e. which has all ones on the diagonal.
%
%   varargin: parameter(s) of the kernel.
%
%Outputs:   
% K: [size(X,dim) x size(X,dim)] the computed kernel matrix. 
%
% Version:  $Id$
% 
% Copyright 2006-     by Jason D.R. Farquhar (jdrf@zepler.org)

% Permission is granted for anyone to copy, use, or modify this
% software and accompanying documents for any uncommercial
% purposes, provided this copyright notice is retained, and note is
% made of any changes that have been made. This software and
% documents are distributed without any warranty, express or
% implied


if (nargin < 1) % check correct number of arguments
   error('Insufficient arguments'); return;
end
if ( nargin< 2 ) Z=[]; end;
if ( nargin< 3 ) kerType='linear'; end;
if ( isinteger(X) ) X=single(X); end % need floats for products!
% empty Z means use X
isgram=false;
if ( isempty(Z) ) Z=X; isgram=true; elseif ( isinteger(Z) ) Z=single(Z); end; 
dim = 1; % default dim is 1st
if ( nargin > 3 && isequal(varargin{1},'dim') ) dim = varargin{2}; varargin(1:2)=[]; end;
dim(dim<0)=dim(dim<0)+ndims(X)+1; 

if ( isstr(kerType) ) 
  switch lower(kerType)
   
   case {'linear','nlinear','lin','nlin'}; % linear
    if ( ~isempty(varargin) ) warning('Extra kernel parameters ignored!'); end;
    K = linKer(X,Z,dim);
   
   case {'poly','nploy'};     % polynomial
    if(numel(varargin)<2) varargin{2}=1;end;  
    K = (linKer(X,Z,dim)+varargin{2}).^varargin{1};
    if ( numel(varargin)>2 ) warning('Extra kernel parameters ignored!'); end;
   
   case {'rbf','nrbf','gaus','ngaus','gaussian','ngaussian'};%Radial basis function, a.k.a. gaussian
    sigma=1;if(numel(varargin)>0)sigma=varargin{1}; end;
    K = sqDist(X,Z,dim); % pairwise distance
    K = exp( - .5 * K / sigma ) ;
    % to avoid rounding errors
    if(isgram) K=.5*(K+permute(K,[numel(dim)+(1:numel(dim)) 1:numel(dim)])); end 
    if ( numel(varargin)>1 ) warning('Extra kernel parameters ignored!'); end;
   
   case 'par';            % Given in the input
    if ( all( size(varargin) == [size(X1,1) size(X2,1)] ) ) 
      K=varargin{1};
    else
      error('Kernel matrix does not match input dimensions');
    end
    if ( numel(varargin)>1 ) warning('Extra kernel parameters ignored!'); end;
   
   case 'x';            % Given in the input
      K=X;
      if ( ~isempty(varargin) ) warning('Extra kernel parameters ignored!'); end;
   
   otherwise;
    if ( exist(kerType)>1 )   % String which specifies function on the path
       K=feval(kerType,X,Z,varargin{:});
    else
      error(['Unrecognised kernel type : ' kerType]);
    end
  end

elseif ( isa(kerType,'function_handle') ) % function handle
  % use this handle
  K=feval(kerType,X,Z,varargin{:});
else
   error('Unknown kernel type');return
end

if ( isequal(kerType(1),'n') ) % normalise computed kernel 
   if ( ndims(K)==2 )
      if ( isgram ) % Need to compute K(X,X)_i,i and K(Z,Z)_j,j
         Nr = diag(K); Nc = Nr;
      else
         for i=1:size(X,1); Nr(i,1)=compKernel(X(i,:),[],kerType,varargin{:});end;
         for i=1:size(Z,1); Nc(i,1)=compKernel(Z(i,:),[],kerType,varargin{:});end;
      end
      K = repop(repop(K,'./',sqrt(Nr)),'./',sqrt(Nc)');
   else
      error('Not supported yet');
   end
end;
return;
