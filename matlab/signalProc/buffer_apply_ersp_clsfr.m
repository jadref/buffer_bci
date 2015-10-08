function [f,fraw,p,X]=buffer_apply_ersp_clsfr(X,clsfr,verb)
% apply a previously trained classifier to the input data
% 
%  f=buffer_apply_erp_clsfr(X,clsfr,varargin)
%
% Inputs:
%   X -- [ch x time x epoch] data
%        OR
%        [struct epoch x 1] where the struct contains a buf field of buffer data
%        OR
%        {[float ch x time] epoch x 1} cell array of data
%  clsfr - [struct] classifier structure
%  verb  - [int] verbosity level (0)
% Output:
%  f    - [size(X,epoch) x nCls] the classifier's raw decision value
%  fraw - [size(X,dim) x nSp] set of pre-binary sub-problem decision values
%  p     - [size(X,epoch) x nCls] the classifier's assessment of the probablility of each class
%  X     - [n-d] the pre-processed data
if( nargin<3 || isempty(verb))  verb=0; end;
% extract the data - from field begining with trainingData
if ( iscell(X) ) 
  if ( isnumeric(X{1}) ) 
    X=cat(3,X{:});
  else
    error('Unrecognised data format!');
  end
elseif ( isstruct(X) )
  X=cat(3,X.buf);
end 
[f, fraw, p, X]=apply_ersp_clsfr(X,clsfr,verb);
if ( verb>0 ) fprintf('Classifier prediction:  %g %g\n', f,p); end;
return;
%------------------
function testCase();
X=oz.X;
fs=256; oz.di(2).info.fs;
width_samp=fs*250/1000;
wX=windowData(X,1:width_samp/2:size(X,2)-width_samp,width_samp,2); % cut into overlapping 250ms windows
