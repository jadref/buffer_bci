function [loss]=conf2loss(conf,dim,losstype)
% Convert [2x2] binary confusion matrices to different loss metrics
%
% [loss]=conf2loss(conf,dim,losstype)
% Inputs:
%  conf -- [n-d] matrix confusion matrices, with [nClass x nClass] confusion
%          matrices in dimension dim.  Confmatrix order should be:
%             [predicted x true], i.e. true labels in cols, predicted in rows
%  dim  -- the dimension of conf which contains the confusion matrices
%          (1st non-singlenton)
%  losstype -- one of: ('cr')
%     bin,cr     class rate,    [1x1]/conf= #correct/#trials
%   tp,fp,tn,fn - true positive, false positive, true negative, false negative rate
%  perclass,pc   perclass loss, [2x1]/conf= #correct per class/#trials of class
%  balanced,bal  balanced loss, [1x1]/conf= mean(perclass)
% N.B. add 'own' to only report values for conf on its own sub-problem.
% Outputs:
%  loss -- [1(or 2) x n-d] matrix of loss values
if ( nargin < 3 || isempty(losstype) ) losstype='bin'; end;
if ( size(conf,1)==2 && size(conf,2)==2 ) 
  szConf=size(conf); szConf(end+1:3)=1; conf=reshape(conf,[szConf(1)*szConf(2) szConf(3:end)]); 
end;
if ( nargin < 2 ) dim=[]; end;
if ( isempty(dim) || isstr(dim) ) 
   if ( isstr(dim) ) losstype=dim; end;
   dim=find(size(conf)>1,1,'first'); if(isempty(dim))dim=1;end;
end
if ( dim < 0 ) dim=ndims(conf)+dim+1; end;
if ( rem(sqrt(size(conf,dim)),1)>eps ) error('conf dim should be square'); end;
if ( isempty(conf) ) loss=[]; return; end;

% reshape to [pre;conf;post] to make computation easier
szconf=size(conf);
nClass= sqrt(szconf(dim));
presz = max(1,prod(szconf([1:dim-1]))); possz=max(1,prod(szconf([dim+1:end])));
conf  = reshape(conf,[presz szconf(dim) possz]);   % linear confMx form
pcconf= reshape(conf,[presz nClass nClass possz]); % square confMx form
nPerCls=reshape(sum(pcconf,2),[presz nClass possz]);% number of examples in each class

% Compute the loss, N.B. max wth eps to prevent divide by 0 and hence production of NaNs
diagIdx=[1:nClass+1:szconf(dim)];
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
 case 'tp'; loss = conf(:,1,:)       ./max(sum(conf(:,1:nClass,:),2),eps);
 case 'fp'; loss = conf(:,nClass+1,:)./max(sum(conf(:,nClass+(1:nClass),:),2),eps);
 case 'tn'; loss = conf(:,2,:)       ./max(sum(conf(:,1:nClass,:),2),eps);
 case 'fn'; loss = conf(:,nClass+2,:)./max(sum(conf(:,nClass+(1:nClass),:),2),eps);
end
loss(isnan(loss))=0;
loss = reshape(loss,[szconf(1:dim-1) size(loss,2) szconf(dim+1:end)]);
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
dv=[ ones(1,33)       zeros(1,67);...
    zeros(1,33) ones(1,33) zeros(1,34);...
          zeros(1,66)       ones(1,34)]'; % known dv's 
conf=pred2conf(Yi,dv); 

conf2loss(conf,'bin')
