function [confMx]=pred2conf(Y,dv,dims)
% convert label predictions to confusion matrices
% Inputs:
%  Y    - [N x nClass] matrix of target labels
%  dv   - n-d matrix of predicted values with N trial in dims(1) and nClass
%         in dims(2)
%  dims - [2 x 1] the dimension of dv along which the trials lie and then
%         the dimension of dv along which the different class precitions lie
%           [trDim spDim]
%         ([1st non-singlenton & next])
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
if ( any(dims < 0) ) dims(dims<0) = ndims(dv)+dims(dims<0)+1; end;
if ( numel(dims)==1 ) if(size(Y,2)>1) dims(2)=dims+1;else dims(2)=0; end; end;
if ( size(Y,2)==size(dv,dims(1)) ) Y=Y'; end;
if ( size(Y,1)~=size(dv,dims(1)) || ...
     (dims(2)>0 && size(Y,2)~=size(dv,dims(2))) ) 
   error('decision values and targets must be the same number of trials');
end

[N nClass]=size(Y); 
if ( nClass==1 ) nClass=2; Y(:,2)=-Y(:,1); end; % Binary is a special case
szdv=size(dv);
szConf=szdv;szConf(dims(1))=nClass*nClass;if(dims(2)>0)szConf(dims(2))=1;end;
sztY  =szdv; sztY(dims(1))=1;
confMx=zeros(szConf,'single');

pred  =dv>0; % binarize+logicalise the dv's

% make some index expressions to get the right parts of dv&conf
idx={};for d=1:ndims(dv); idx{d}=1:szdv(d); end; if(dims(2)>0) idx{dims(2)}=1; end;
for trueLab=1:nClass;   % Loop over true labels
   tY = Y(:,trueLab)>0;   
   tY = repmat(shiftdim(tY,-dims(1)+1),sztY); % Argh! should be able to use repop for this!
   idx{dims(1)}  = (trueLab-1)*nClass+(1:nClass);
   % Only if is positive prediction and label match does it count in confMx
   confMx(idx{:})= sum(pred & tY,dims(1)); 
end
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


% argh! check for silly input size dependent bug
Y=[      1    -1    -1    -1;
    -1    -1     1    -1;
    -1    -1    -1     1;
    -1     1    -1    -1]
dv=[     1    -1    -1    -1;
     1    -1    -1    -1;
     1    -1    -1    -1;
    -1     1    -1    -1];
reshape(pred2conf(Y,dv),[4 4])

Y2=[     1    -1    -1    -1;
     1    -1    -1    -1;
    -1    -1     1    -1;
    -1    -1     1    -1;
    -1    -1    -1     1;
    -1    -1    -1     1;
    -1     1    -1    -1;
    -1     1    -1    -1]
dv2=[     1    -1    -1    -1;
     1    -1    -1    -1;
     1    -1    -1    -1;
     1    -1    -1    -1;
     1    -1    -1    -1;
     1    -1    -1    -1;
    -1     1    -1    -1;
    -1     1    -1    -1];
reshape(pred2conf(Y2,dv2),[4 4])


