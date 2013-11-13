function Cscale=CscaleEst(X,dim,CscaleThresh,varargin)
% estimate the scaling for the regularisation parameters (10% data variance)
%
% Cscale=CscaleEst(X,dim,CscaleThresh)
%
% Inputs:
%  X   - [n-d] data to estimate scaling for, examples in dimension dim
%  dim - [int] dimension(s) which contain examples (ndims(X))
%  Cscalethresh - threshold in std-deviations used for outlier rejection in 
%                 variance/radius estimation (4)
if ( nargin < 2 || isempty(dim) ) dim=ndims(X); end;
if ( nargin < 3 || isempty(CscaleThresh) ) CscaleThresh=4; end;
Cscale=.1*dataVarEst(X,dim,CscaleThresh,varargin{:});
return;