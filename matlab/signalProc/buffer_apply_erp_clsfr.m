function [f,fraw,p,X,isbadtr,isbadch]=buffer_apply_erp_clsfr(X,clsfr,verb)
% apply a previously trained classifier to the input data
% 
%  f=buffer_apply_erp_clsfr(X,clsfr,verb)
%
% Inputs:
%  X - [ch x time x epoch ] dataset 
%  clsfr - [struct] classifier structure
%  verb  - [int] verbosity level (0)
% Output:
%  f    - [size(X,epoch) x nCls] the classifier's raw decision value
%  fraw - [size(X,dim) x nSp] set of pre-binary sub-problem decision values
%  p     - [size(X,epoch) x nCls] the classifier's assessment of the probablility of each class
%  X     - [n-d] the pre-processed data
if( nargin<3 || isempty(verb))  verb=0; end;
[f, fraw, p, X, isbadtr, isbadch]=apply_erp_clsfr(X,clsfr,verb);
if ( verb>0 ) fprintf('Classifier prediction:  %g %g\n', f,p); end;
return;
%------------------
function testCase();
X=oz.X;
fs=256; oz.di(2).info.fs;
width_samp=fs*250/1000;
wX=windowData(X,1:width_samp/2:size(X,2)-width_samp,width_samp,2); % cut into overlapping 250ms windows
