function [f,fraw,p,Xpp]=buffer_apply_clsfr(X,clsfr,verb)
% apply a previously trained classifier to the input data
% 
%  f=buffer_apply_clsfr(X,clsfr,varargin)
%  
% Note: automatically detect and use ERP/ERsP pipeline as needed
%
% Inputs:
%   X -- [ch x time x epoch] data
%        OR
%        [struct epoch x 1] where the struct contains a buf field of buffer data
%        OR
%        {[float ch x time] epoch x 1} cell array of data
%  clsfr - [struct] classifier(s) structure
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
for ci=1:numel(clsfr);
  if ( (isfield(clsfr(ci),'type') && any(strcmp(lower(clsfr(ci).type),{'erp','evoked'}))) || ...
       ~isempty(clsfr(ci).filt) && isempty(clsfr(ci).windowFn) ) % ERP
    [f{ci}, fraw{ci}, p{ci}, Xpp{ci}]=apply_erp_clsfr(X,clsfr(ci),verb);
  elseif ( (isfield(clsfr(ci),'type') && any(strcmp(lower(clsfr(ci).type),{'ersp','induced'}))) || ...
           isempty(clsfr(ci).filt) && ~isempty(clsfr(ci).welchAveType) ) % ERsP
    [f{ci}, fraw{ci}, p{ci}, Xpp{ci}]=apply_ersp_clsfr(X,clsfr(ci),verb);
  end  
end
if ( numel(clsfr)==1 ) %BODGE: for single classifier return non-cell for legacy reasons
  f=f{1}; fraw=fraw{1}; p=p{1}; Xpp=Xpp{1};
end
if ( verb>0 ) fprintf('Classifier prediction:  %g %g\n', f,p); end;
return;
%------------------
function testCase();
X=oz.X;
fs=256; oz.di(2).info.fs;
width_samp=fs*250/1000;
wX=windowData(X,1:width_samp/2:size(X,2)-width_samp,width_samp,2); % cut into overlapping 250ms windows
