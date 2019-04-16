function filtstate=lkwarmup(A,B,X,dim)
% From: Likhterov & Kopeika, 2003. "Hardware-efficient technique for
%        minimizing startup transients in Direct Form II digital filters"
if(nargin<4) dim=1; end;
if( abs(sum(A))<eps )  % => ylim=0 -> dc-gain=0
  kdc = 0;
else
  kdc = sum(A) / sum(B);
end
si = fliplr(cumsum(fliplr(B - kdc * A)));
si(1) = [];
if( dim==1 )     filtstate=si(:)*X(1,:);%;mean(X(:,:),1);%
elseif( dim==2 ) filtstate=si(:)*X(:,1)';%mean(X(:,:),2)';%
end
return;

function testcase()
  X=ones(10000,1);
  A=[1,-2,1];
  B=[1,-1.98753,.98757];
  [fX,fs]=filter(B,A,X);
  is=lkwarmpu(A,B,X);
  [ifX,ifs]=filter(B,A,X,is);
