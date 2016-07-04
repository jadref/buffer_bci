function [confMx]=dv2conf(Y,dv,dims,spMx,varargin)
% convert label predictions to confusion matrices
% Inputs:
%  Y    - [N x nClass] matrix of targets as an *indicator* matrix
%  dv   - n-d matrix of predicted values with N trial in dims(1) and nClass
%         in dims(2)
%  dims - [2 x 1] the dimension of dv along which the trials lie and then
%         the dimension of dv along which the different class precitions lie
%           [trDim spDim]
%         ([1st non-singlenton & next])
%  spMx - [size(dv,spD) x nClass] sub-problem decoding matrix, fixed for all trials
%         OR
%         [size(dv,spD) x size(dv,trD) x nClass] per-trial sub-problem decoding matrix
% Outputs:
%  conf - [size(dv) with size(dv,dims(1))=nClass*nClass & size(dv,dims(2))==1]
%      with dimension dims of dv replaced by a nClass*nClass elemet conf
%      vector where, in the binary case:
%      conf(1) = # true  positive    conf(3) = # false negative
%      conf(2) = # false positive    conf(4) = # true  negative 
%
%                                                      true-P true-N
% i.e. reshape(conf(:,i),nClass,nClass))=>     pred-P [  tp     fn  ] 
%                                              pred-N [  fp     tn  ]
%      for classifier i (assuming dims=[1 3])
if ( nargin < 3 || isempty(dims) ) 
   dims = find(size(dv)>1,1); if ( isempty(dims) ) dims=1; end; 
end;
if ( nargin<4 ) spMx=[]; end
if ( any(dims < 0) ) dims(dims<0) = ndims(dv)+dims(dims<0)+1; end;
if ( numel(dims)==1 ) if(size(Y,2)>1) dims(2)=dims+1;else dims(2)=0; end; end;
if ( size(Y,2)==size(dv,dims(1)) ) Y=Y'; end;
if ( size(Y,1)~=size(dv,dims(1)) || ...
     (dims(2)>0 && size(Y,2)~=size(dv,dims(2))) ) 
   error('decision values and targets must be the same number of trials');
end

[N nClass]=size(Y); 
if ( nClass==1 ) % binary is a special case
  confMx = dv2confbin(Y,dv,dims(1));
  return;
end

pred=dv;
if ( ~islogical(Y) ) % convert to logical predictions
  exInd= all(Y==0,dims(2)); % indices to ignore
  Y    = dv2pred(Y,dims(2),spMx,varargin{:});
  % ensure ignored hav 0 value
  Y(repmat(exInd,[ones(1,dims(2)-1) size(Y,dims(2)) ones(1,ndims(Y)-dims(2)-1)]))=0; 
end
if ( ~islogical(pred) ) % convert to logical predictions
  pred = dv2pred(dv,dims(2),spMx,varargin{:});
end
confMx = pred2conf(Y,pred,dims);
return

%-----------------------------------------------------------------------------
function testCase()
Y =ceil(rand(100,1)*2.9); % 1-3 labels
Yi=lab2ind(Y);
dv=[ ones(1,33) zeros(1,33) zeros(1,34);...
    zeros(1,33)  ones(1,33) zeros(1,34);...
    zeros(1,33) zeros(1,33) ones(1,34)]'; % known dv's 
conf=pred2conf(Yi,dv); 
conf=reshape(conf,size(Yi,2),[]);
conf(1,1),sum(Yi(:,1)>0 & dv(:,1)>0),conf(2,2),sum(Yi(:,2)>0 & dv(:,2)>0), conf(3,3),sum(Yi(:,3)>0 & dv(:,3)>0)

% with multiple sets of classification results
pred=dv2pred(cat(3,dv,dv,dv),2);
conf=pred2conf(Yi,pred)
