function [loss]=conf2loss(conf,dim,losstype)
% Convert confusion matrices to different loss metrics
%
% [loss]=conf2loss(conf,dim,losstype)
% Inputs:
%  conf -- [n-d] matrix confusion matrices, with [nClass x nClass] confusion
%          matrices in dimension dim.  Confmatrix order should be:
%             [predicted x true], i.e. true labels in cols, predicted in rows
%  dim  -- the dimension of conf which contains the confusion matrices
%          (1st non-singlenton)
%  losstype -- one of:                                                   ('cr')
%     bin,cr        class rate,    [1x1]/conf= #correct/#trials
%     tp,fp,tn,fn   true positive, false positive, true negative, false negative rate
%     perclass,pc   perclass loss, [2x1]/conf= #correct per class/#trials of class
%     balanced,bal  balanced loss, [1x1]/conf= mean(perclass)
%     kappa         Cohen's kappa coefficient
% N.B. add 'own' to only report values for conf on its own sub-problem.
% Outputs:
%  loss -- [1(or 2) x n-d] matrix of loss values
if ( nargin < 3 || isempty(losstype) ) losstype='bin'; end;
if ( size(conf,1)==2 && size(conf,2)==2 ) 
  szConf=size(conf); szConf(end+1:3)=1; conf=reshape(conf,[szConf(1)*szConf(2) szConf(3:end)]); 
end;
if ( nargin < 2 ) dim=[]; end;
if ( isempty(dim) || ischar(dim) ) 
   if ( ischar(dim) ) losstype=dim; end;
   dim=find(size(conf)>1,1,'first'); if(isempty(dim))dim=1;end;
end
if ( any(dim < 0) ) dim(dim<0)=ndims(conf)+dim(dim<0)+1; end;
if ( (numel(dim)==1 && rem(sqrt(size(conf,dim)),1)>eps) || ...
	  (numel(dim)>1 && size(conf,dim(1))~=size(conf,dim(2))) ) error('conf dim should be square'); end;
if ( isempty(conf) ) loss=[]; return; end;

% reshape to [pre;conf;post] to make computation easier
szconf=size(conf);
nClass=szconf(dim(1)); if(numel(dim)==1) nClass=sqrt(nClass); end;
presz = max(1,prod(szconf([1:dim(1)-1]))); possz=max(1,prod(szconf([dim(end)+1:end])));
conf  = reshape(conf,[presz prod(szconf(dim)) possz]);   % linear confMx form
pcconf= reshape(conf,[presz nClass nClass possz]);       % square confMx form
nPerCls=reshape(sum(pcconf,2),[presz nClass possz]);     % number of examples in each class

% Compute the loss, N.B. max wth eps to prevent divide by 0 and hence production of NaNs
diagIdx=[1:nClass+1:(nClass*nClass)];
switch losstype;
 case {'bin','ownbin','cr','owncr'};
  loss=sum(conf(:,diagIdx,:),2)./max(sum(conf,2),eps);
 case {'perclass','pc','ownperclass','ownpc'}; 
  loss=conf(:,diagIdx,:)./max(nPerCls,eps);
 case {'balanced','bal','ownbal','ownbalanced'}; % divide by num classes with examples
  loss=sum(conf(:,diagIdx,:)./max(nPerCls,eps),2)./max(eps,sum(nPerCls>0,2));
 case {'recall','ownrecall'};      
  loss=conf(:,1,:)./max(nPerCls(:,1,:),eps);
 case {'precision','ownprecision'};      
  loss=conf(:,1,:)./max(reshape(sum(pcconf(:,1,:,:),3),[presz 1 possz]),eps);
 case {'1love','own1love'};
  loss=conf(:,1,:)./max(sum(conf(:,[1:nClass nClass+1:nClass:nClass^2],:),2),eps);
 case {'tp','tpr'}; loss = conf(:,1,:)       ./max(sum(conf(:,1:nClass,:),2),eps);
 case {'fp','fpr'}; loss = conf(:,nClass+1,:)./max(sum(conf(:,nClass+(1:nClass),:),2),eps);
 case {'tn';'tnr'}; loss = conf(:,2,:)       ./max(sum(conf(:,1:nClass,:),2),eps);
 case {'fn','fnr'}; loss = conf(:,nClass+2,:)./max(sum(conf(:,nClass+(1:nClass),:),2),eps);
 case 'kappa'; % Cohen's kappa coefficient
  Pra = sum(conf(:,diagIdx,:),2)./max(sum(conf,2),eps); % prob agreement
  Pre = sum(pcconf,2); 
  Pre=reshape(sum(Pre.*reshape(sum(pcconf,3),size(Pre)),3),size(Pra)) ./ max(sum(conf,2).^2,eps);
  loss= (Pra - Pre) ./ (1-Pre);
end
loss(isnan(loss))=0;
loss = reshape(loss,[szconf(1:dim(1)-1) size(loss,2) szconf(dim(end)+1:end) 1]);
% N.B. this part hasn't be re-tested since conversion to new format
if ( isequal(losstype(1:min(3,end)),'own') ) % only diag + left over entries!
   for i=1:size(loss,2); oloss(:,i,:)=loss(:,i,i,:);   end   
   for i=size(loss,2):size(loss,3); oloss(:,i,:)=loss(:,size(loss,2),i,:); end;
   loss=reshape(oloss,[size(oloss,1),size(oloss,2),csz(4:end)]);
end
return;
%----------------------------------------------------------------------------
function testCase()
Y=ceil(rand(100,1)*2.9); % 1-3 labels
Yi=lab2ind(Y);
pC=[ones(33,1); 2*ones(33,1); 3*ones(34,1)]; % predicted label
dv=lab2ind(pC);
conf=pred2conf(Yi,dv); 


conf2loss(conf,1,'bin')

conf2loss(randn(3,3),[1 2])

conf2loss(conf,1,'kappa'),pred2kappa(Y,pC)

% bin, mulitple features
Y=sign(randn(100,1));
dv=randn(100,3);
conf=dv2conf(Y,dv)
conf2loss(conf,1,'bin')
conf2loss(conf,1,'kappa'),for i=1:size(dv,2); pred2kappa(Y,sign(dv(:,i))), end
