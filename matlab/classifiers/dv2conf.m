function [confMx]=dv2conf(Y,dv,dim)
% compute the confusion matrix between set of true -1/0/+1 labels and predictions
%
%  [confMx]=dv2conf(Y,dv,dim)
% 
% Inputs:
%  Y    - [N x 1] or n-d matrix of target values with N trials in dim
%  dv   - n-d matrix of predicted values with N trial in dim
%  dim  - the dimension of dv (and Y) along which the trials lie
% Outputs:
%  conf - [size(dv) x size(Y)] matrix of per class losses. [dv x subProb]
%      with dimension dim of dv replaced by a 4 elemet conf vector where:
%      conf(1) = # true  positive    conf(3) = # false positive
%      conf(2) = # false negative    conf(4) = # true  negative 
%
%                                              true-P true-N
% i.e. reshape(conf(:,i,j),2,2))=>     pred-P [  tp     fp  ] 
%                                      pred-N [  fn     tn  ]
%      for classifier i on subProb j (assuming dim=1)
% N.B. bin = 1 - sum(conf([1 4],:,:))./sum(conf);
%      pc  = 1 - conf([1 4],:,:)./[sum(conf(1:2,:,:)) sum(conf(3:4,:,:))]
if ( nargin < 3 ) dim = 1; end;
if ( dim < 0 ) dim = ndims(dv)+dim+1; end;
if ( ndims(Y)==2 && min(size(Y))==1 && dim>1 ) Y=shiftdim(Y(:),-dim+1); end;
if ( ndims(Y)==2 && ndims(dv)==2 && size(dv,dim)~=size(Y,dim) ) dv=dv'; end;
if ( size(Y,dim)~=size(dv,dim) ) 
   error('decision values and targets must be the same number of trials');
end
if ( islogical(Y) ) warning('Logical Y input: should be +1/0/-1 sign set'); end;
if ( islogical(dv)) 
  warning('Logical dv input: should be +1/0/-1 sign set: converted using 2*dv-1');
  dv=2*dv-1;
end

% squash into max 3D only, [pre dim pos]
sizeY=size(Y);
Y =reshape(Y, [max(1,prod(sizeY(1:dim-1)))  sizeY(dim)  prod(sizeY(dim+1:end))]);
sizedv=size(dv);
dv=reshape(dv,[max(1,prod(sizedv(1:dim-1))) sizedv(dim) prod(sizedv(dim+1:end))]);
for i=1:size(Y,3); % loop over different sub-probs (Y's)
   for prey=1:size(Y,1);      
      for j=1:size(dv,3); % loop over classifiers (dv's)
         for predv=1:size(dv,1);
            conf=[sum(dv(predv,:,j)>=0 & Y(prey,:,i)==1) sum(dv(predv,:,j)>=0 & Y(prey,:,i)==-1);
                  sum(dv(predv,:,j)<0  & Y(prey,:,i)==1) sum(dv(predv,:,j)<0  & Y(prey,:,i)==-1)];
            confMx(predv,:,j,prey,i)=conf(:);
         end
      end
   end
end
% Give the result the required shape
confMx = reshape(confMx,[sizedv(1:dim-1) 4 sizedv(dim+1:end) ...
                    sizeY(1:dim-1) sizeY(dim+1:end)]);
%-----------------------------------------------------------------------------
function testCase()
Y=ceil(rand(100,1)*9.9); % 1-10 labels
Yi=lab2ind(Y);
dv=ones(100,10); % known dv's 
conf=dv2subProbConf(Yi,dv',2);
diag(shiftdim(sum(conf([1 4],:,:))./sum(conf)))',sum(dv.*Yi>0)./sum(Yi~=0)
[diag(shiftdim(conf(1,:,:)./sum(conf(1:2,:,:)))) diag(shiftdim(conf(4,:,:)./sum(conf(3:4,:,:))))]',[sum(dv>0&Yi>0)./sum(Yi>0);sum(dv<0&Yi<0)./sum(Yi<0)]

for i=1:10; subProb{i}={i [1:i-1 i+1:10]}; end;
Yi=lab2ind(Y,subProb); conf=dv2subProbLoss(Yi,dv);
diag(shiftdim(sum(conf([1 4],:,:))./sum(conf)))',sum(dv.*Yi>0)./sum(Yi~=0)

% include some unwanted points
Yi=lab2ind(Y,{{1 2} {2 3} {3 1}}); 
[bin eeoc auc]=dv2loss(Yi,dv(:,1:size(Yi,2))); sum(dv>0)./sum(Yi~=0)
