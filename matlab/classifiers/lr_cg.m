function [wb,f,J,obj,tstep]=lr_cg(X,Y,R,varargin);
% Regularised linear Logistic Regression Classifier
%
% [wb,f,J,obj]=lr_cg(X,Y,C,varargin)
% Regularised Logistic Regression Classifier using a pre-conditioned
% conjugate gradient solver on the primal objective function
%
% Assuming: Pr(x,y+) = exp(x*w+b) and Pr(x,y-) = exp(-(x*w+b))
%           Pr(x|y) = exp(x*w+b)/(exp(x*w+b)+exp(-(x*w+b)))
%
% J = w' R w + w' mu + sum_i sum_y Pr(y_i=y) log( Pr(x_i|y) )
%
% if Pr(y_i=y) is 0/1 variable
%   = w' R w + w' mu + sum_i log(Pr(x_i|y_i))
%   = w' R w + w' mu + sum_i log(exp(y_i*(x*w+b))/(exp(x*w+b)+exp(-(x*w+b))))
%   = w' R w + w' mu + sum_i log (1 + exp( - y_i ( w'*X_i + b ) ) )^-1 ) 
%
% Inputs:
%  X       - [d1xd2x..xN] data matrix with examples in the *last* dimension
%  Y       - [Nx1] matrix of -1/0/+1 labels, (N.B. 0 label pts are implicitly ignored)
%            OR
%            [Nx2] matrix of weighting that this is the true class
%  R       - quadratic regularisation matrix                                   (0)
%     [1x1]       -- simple regularisation constant             R(w)=w'*R*w
%     [d1xd2x...xd1xd2x...] -- full matrix                      R(w)=w'*R*w
%     [d1xd2x...] -- simple weighting of each component matrix, R(w)=w'*diag(R)*w
%     [d1 x d1]   -- 2D input, each col has same full regMx     R(w)=trace(W'*R*W)=sum_c W(:,c)'*R*W(:,c)
%     [d2 x d2]   -- 2D input, each row has same full regMX     R(w)=trace(W*R*W')=sum_r W(r,:) *R*W(r,:)'
%     N.B. if R is scalar then it corrospends to roughly max allowed length of the weight vector
%          good default is: .1*var(data)
% Outputs:
%  wb      - {size(X,1:end-1) 1} matrix of the feature weights and the bias {W;b}
%  f       - [Nx1] vector of decision values
%  J       - the final objective value
%  obj     - [J Ew Ed]
%
% Options:
%  dim     - [int] dimension of X which contains the trials               (ndims(X))
%  rdim    - [1x1] dimensions along which the regularisor applies.        ([])
%  mu      - [d1xd2x...] vector containing linear term                    ([])
%  wb      - [(N+1)x1] initial guess at the weights parameters, [W;b]     ([])
%  maxEval - [int] max number for function evaluations                    (N*5)
%  maxIter - [int] max number of CG steps to do                           (inf)
%  maxLineSrch - [int] max number of line search iterations to perform    (50)
%  objTol0 - [float] relative objective gradient tolerance                (1e-4)
%  objTol  - [float] absolute objective gradient tolerance                (1e-5)
%  tol0    - [float] relative gradient tolerance, w.r.t. initial value    (0)
%  lstol0  - [float] line-search relative gradient tolerance, w.r.t. initial value   (1e-2)
%  tol     - [float] absolute gradient tolerance                          (0)
%  verb    - [int] verbosity                                              (0)
%  step    - initial step size guess                                      (1)
%  wght    - point weights [Nx1] vector of label accuracy probabilities   ([])
%            [2x1] for per class weightings (neg class,pos class)
%            [1x1] relative weight of the positive class
% Copyright 2006-     by Jason D.R. Farquhar (jdrf@zepler.org)

% Permission is granted for anyone to copy, use, or modify this
% software and accompanying documents for any uncommercial
% purposes, provided this copyright notice is retained, and note is
% made of any changes that have been made. This software and
% documents are distributed without any warranty, express or
% implied
if ( nargin < 3 ) R(1)=0; end;
if( numel(varargin)==1 && isstruct(varargin{1}) ) % shortcut eval option procesing
  opts=varargin{1};
else
  opts=struct('wb',[],'alphab',[],'dim',[],'rdim',[],'mu',0,'Jconst',0,...
              'maxIter',inf,'maxEval',[],'tol',0,'tol0',0,'lstol0',1e-5,'objTol',1e-5,'objTol0',1e-4,...
              'verb',0,'step',0,'wght',[],'X',[],'maxLineSrch',50,...
              'maxStep',3,'minStep',5e-2,'marate',.95,...
				  'bPC',[],'wPC',[],'PCmethod','zero',...
				  'incThresh',.66,'optBias',0,'maxTr',inf,...
              'getOpts',0);
  [opts,varargin]=parseOpts(opts,varargin{:});
  if ( opts.getOpts ) wb=opts; return; end;
end
if ( isempty(opts.maxEval) ) opts.maxEval=5*sum(Y(:)~=0); end
% Ensure all inputs have a consistent precision
if(islogical(Y))Y=single(Y); end;
if(isa(X,'double') && ~isa(Y,'double') ) Y=double(Y); end;
if(isa(X,'single')) eps=1e-7; else eps=1e-16; end;
opts.tol=max(opts.tol,eps); % gradient magnitude tolerence

if ( ~isempty(opts.dim) && opts.dim<ndims(X) ) % permute X to make dim the last dimension
   persistent warned
   if (isempty(warned) ) 
      warning('X has trials in other than the last dimension, permuting to make it so..');
      warned=true;
   end
  X=permute(X,[1:opts.dim-1 opts.dim+1:ndims(X) opts.dim]);
  if ( ~isempty(opts.rdim) && opts.rdim>opts.dim ) opts.rdim=opts.rdim-1; end; % shift other dim info
end
szX=size(X); nd=numel(szX); N=szX(end); nf=prod(szX(1:end-1));
if(size(Y,1)==1) Y=Y'; end; % ensure Y is col vector
Y(isnan(Y))=0; % convert NaN's to 0 so are ignored

% reshape X to be 2d for simplicity
rdim=opts.rdim;
X=reshape(X,[nf N]);
if ( numel(R)==1 )
  szRw=[nf 1]; RType=1; % scalar
elseif ( size(R,2)==1 && numel(R)==nf ) % weighting vector
  szRw=[nf 1]; RType=2;
elseif ( size(R,2)==1 && numel(R)==nf*nf ) % full matrix
  R=reshape(R,[nf nf]); szRw=[nf 1]; RType=1;
elseif ( isempty(rdim) && size(R,1)==szX(1) ) %nD inputs R should replicate over leading dimensions
  szRw=[szX(1) prod(szX(2:end-1))]; RType=3;
elseif ( ~isempty(rdim) && size(R,1)==prod(szX(rdim)) && min(rdim)==1 ) 
  szRw=[prod(szX(rdim)) prod(szX(max(rdim)+1:end-1))];  RType=3;
elseif ( isempty(rdim) && size(R,1)==szX(end-1) )  %nD inputs R should replicate over trailing dimensions
  szRw=[prod(szX(1:end-2)) szX(end-1)]; RType=4;
elseif ( ~isempty(rdim) && size(R,1)==prod(szX(rdim)) && max(rdim)==nd-1 )
  szRw=[prod(szX(1:min(rdim))) prod(szX(rdim))];      RType=4;
elseif ( ~isempty(rdim) && size(R,1)==prod(szX(rdim)) ) % nD inputs R replicate over middle dims
  szRw=szX(1:end-1); R=reshape(R,[szX(rdim) szX(rdim)]); RType=5;
  rdimIdx=1:nd-1; rdimIdx(rdim)=-rdim;
else
  error('Huh, dont know how to use this regularisor');
end
mu=opts.mu; if ( numel(mu)>1 ) mu=reshape(mu,[nf 1]); else mu=0; end;

% check for degenerate inputs
if ( (size(Y,2)==1 && (all(Y(:)>=0) || all(Y(:)<=0))) ||...
	  (size(Y,2)==2 && any(all(Y==0,1))) )
  warning('Degnerate inputs, 1 class problem');
end

% N.B. this form of loss weighting has no true probabilistic interpertation!
wght=opts.wght;
if ( ~isempty(opts.wght) ) % point weighting -- only needed in wghtY
   if ( numel(wght)==1 ) % weight ratio between classes
     wght=zeros(size(Y));
     wght(Y<0)=1./sum(Y<0)*opts.wght; wght(Y>0)=(1./sum(Y>0))*opts.wght;
     wght = wght*sum(abs(Y))./sum(abs(wght)); % ensure total weighting is unchanged
   elseif ( numel(opts.wght)==2 ) % per class weights
     wght=zeros(size(Y));
     wght(Y<0)=opts.wght(1); wght(Y>0)=opts.wght(2);
   elseif ( numel(opts.wght)==N )
   else
     error('Weight must be 2 or N elements long');
   end
end
Yi=Y;
if(max(size(Yi))==numel(Yi)) % convert to indicator
  Yi=cat(2,Yi(:)>0,Yi(:)<0); 
  if( isa(X,'single') ) Yi=single(Yi); else Yi=double(Yi); end; % ensure is right data type
end 
if ( ~isempty(wght) )        Yi=repop(Yi,'*',wght); end % apply example weighting

% check if it's more efficient to sub-set the data, because of lots of ignored points
oX=X; oY=Y;
incInd=any(Yi~=0,2);
if ( sum(incInd)./size(Yi,1) < opts.incThresh ) % if enough ignored to be worth it
   if ( sum(incInd)==0 ) error('Empty training set!'); end;
   X=X(:,incInd); Yi=Yi(incInd,:);
end
% pre-compute stuff needed for gradient computation
Y1=Yi(:,1); sY=sum(Yi,2);

% generate an initial seed solution if needed
wb=opts.wb;   % N.B. set the initial solution
if ( isempty(wb) && ~isempty(opts.alphab) ) wb=opts.alphab; end;
if ( isempty(wb) )    
  w=zeros(nf,1);b=0;
  % prototype classifier seed
  alpha=Yi(:,1)./sum(Yi(:,1))/2-Yi(:,2)./sum(Yi(:,2))/2;
  w = X*alpha;
  switch ( RType ) % diff types regularisor
   case 1; Rw=R*w;
   case 2; Rw=R(:).*w;
   case 3; Rw=R*reshape(w,szRw); % leading dims
   case 4; Rw=reshape(w,szRw)*R; % trailing dims
   case 5; Rw=tprod(w,rdimIdx,R,[-(1:numel(szRw)) 1:numel(szRw)]); % middle dims
  end
  wRw   = w'*Rw(:);
  wX    = w'*oX; wX=wX(incInd); % only included points in seed
  % re-scale to sensible range, i.e. 0-mean, unit-std-dev
  b     = -mean(wX); sd=max(1,sqrt(wX*wX'/numel(wX)-b*b));
  w     = w/sd; b=b/sd;
  wX=wX/sd; wRw = wRw/sd;
  % find least squares optimal scaling and bias
  % N.B. this can cause numerical problems some time....
  %sb = pinv([wRw+wX*wX' sum(wX); sum(wX) sum(incInd)])*[wX*oY(incInd); sum(wghtY)];
  %w=w*sb(1); b=sb(2);
else
  w=wb(1:end-1); b=wb(end);
end 

switch ( RType ) % diff types regularisor
 case 1; Rw=R*w;
 case 2; Rw=R(:).*w;
 case 3; Rw=R*reshape(w,szRw);
 case 4; Rw=reshape(w,szRw)*R;
 case 5; Rw=tprod(w,rdimIdx,R,[-(1:numel(szRw)) 1:numel(szRw)]); % middle dims
end
wX   = w'*X;
dv   = wX+b;
p    = 1./(1+exp(-dv(:))); % =Pr(x|y+)
Yerr = Y1-p.*sY;

% set the pre-conditioner
% N.B. the Hessian for this problem is:
%  H  =[X*diag(wght)*X'+2*C(1)*R  (X*wght');...
%       (X*wght')'                sum(wght)];
% where wght=P(y_true).*(1-P(y_true)) where 0<P(y_true)<1
% So: diag(H) = [sum(X.*(wght.*X),2) + 2*diag(R);sum(wght)];
% Now, the max value of wght=.25 = .5*(1-.5) and min is 0 = 1*(1-1)
% So approx assuming average wght(:)=.25/2; (i.e. about 1/2 points are on the margin)
%     diag(H) = [sum(X.*X,2)*.25/2+2*diag(R);N*.25/2];
wPC=opts.wPC; bPC=opts.bPC;
if ( isempty(wPC) ) 
  switch lower(opts.PCmethod)
	 case 'wb0'; wPC=(sum(X.*X,2))*.25/2; % H=X'*diag(wght)*X -> diag(H)=wght.*sum(X.^2,2)~= sum(X.^2,2)
	 case {'wb','adapt'};  
		g=1./(1+exp(-Y(:).*dv(:)));wght = g.*(1-g); wght(Y==0)=0;%ensure excluded points not in pre-cond
		wPC=sum(X.*repop(wght(:)','*',X),2);
  end
  % include the effect of the regularisor
  switch ( RType ) % diff types regularisor
   case 1; wPC=wPC+2*diag(R);
   case 2; wPC=wPC+2*R(:);
   case 3; tmp=repmat(diag(R) ,1,nf./size(R,1)); wPC=wPC+2*tmp(:); % leading dim
   case 4; tmp=repmat(diag(R)',nf./size(R,1),1); wPC=wPC+2*tmp(:); % trailing dim
   case 5; rsz=szX(1:end-1); rsz(setdiff(1:end,rdim))=1; wPC=repop(wPC,'+',2*reshape(diag(R),rsz));% middle dims
  end
  wPC(wPC<eps) = 1; 
  wPC=1./wPC;
end;
if ( isempty(bPC) ) 
	switch lower(opts.PCmethod)
	  case 'wb0';           bPC=1./(size(X,2)*.25/2);
	  case {'wb','adapt'};  bPC=1./sum(wght);
	end
end % ==mean(diag(cov(X)))
if ( isempty(wPC) ) wPC=ones(size(X,1),1); end;
if ( isempty(bPC) ) bPC=1; end;
if ( numel(wPC)==1 ) % scalar pre-condn
  PC = [ones(size(X,1),1)*wPC;bPC];
elseif ( max(size(wPC))==numel(wPC) ) % vector pre-condn
  PC = [wPC(:);bPC];
elseif ( all(size(wPC)==size(X,1)) )  % matrix pre-cond
  PC = zeros(size(X,1)+1); PC(1:size(wPC,1),1:size(wPC,2))=wPC; PC(end)=bPC;
else
  PC = [];
end

dJ   = [2*Rw(:) + mu - X*Yerr; ...
        -sum(Yerr)];
% precond'd gradient:
%  [H  0  ]^-1 [ Rw+mu-X'((1-g).Y))] 
%  [0  bPC]    [      -1'((1-g).Y))] 
if ( size(PC,2)==1 ) % vector pre-conditioner
  MdJ  = PC.*dJ; % pre-conditioned gradient
else % matrix pre-conditioner
  if ( size(PC,1)==size(X,1)+1 ) % PC is full size
    MdJ = PC*dJ;
  elseif ( RType==3 && size(wPC,1)==szX(1) )
    MdJ = wPC*reshape(dJ(1:end-1),szX(1:2)); MdJ=[MdJ(:);bPC*dJ(end)];
  elseif ( RType==4 && size(wPC,1)==szX(end-1) )
    MdJ = reshape(dJ(1:end-1),szX(1:2))*wPC; MdJ=[MdJ(:);bPC*dJ(end)];
  else % now what?
    
  end
end
Mr   =-MdJ;
d    = Mr;
dtdJ =-(d'*dJ);
r2   = dtdJ;

% expected loss = -P(+)*ln P(D|w,b,+) -P(-)*ln(P(D|w,b,-)
Ed   = -(log(max(p,eps))'*Yi(:,1)+log(max(1-p,eps))'*Yi(:,2)); 
Ew   = w'*Rw(:);     % -ln P(w,b|R);
if( ~isequal(mu,0) ) Emu=w'*mu; else Emu=0; end;
J    = Ed + Ew + Emu + opts.Jconst;       % J=neg log posterior

% Set the initial line-search step size
step=abs(opts.step); 
%if( step<=0 ) step=1; end % N.B. assumes a *perfect* pre-condinator
if( step<=0 ) step=min(sqrt(abs(J/max(dtdJ,eps))),1); end %init step assuming opt is at 0
tstep=step;

neval=1; lend='\r';
if(opts.verb>0)   % debug code      
   if ( opts.verb>1 ) lend='\n'; else fprintf('\n'); end;
   fprintf(['%3d) %3d x=[%5f,%5f,.] J=%5f (%5f+%5f) |dJ|=%8g\n'],0,neval,w(1),w(2),J,Ew,Ed,r2);
end

% pre-cond non-lin CG iteration
J0=J; r02=r2;
madJ=abs(J); % init-grad est is init val
w0=w; b0=b;
nStuck=0;
for iter=1:min(opts.maxIter,2e6);  % stop some matlab versions complaining about index too big

   oJ= J; oMr  = Mr; or2=r2; ow=w; ob=b; % record info about prev result we need

   %---------------------------------------------------------------------
   % Secant method for the root search.
   if ( opts.verb > 2 )
      fprintf('.%d %g=%g @ %g (%g+%g)\n',0,0,dtdJ,J,Ed,Ew); 
      if ( opts.verb>3 ) 
         hold off;plot(0,dtdJ,'r*');hold on;text(0,double(dtdJ),num2str(0)); 
         grid on;
      end
   end;
   ostep=inf;tstep=tstep;step=tstep;%max(tstep,abs(1e-6/dtdJ)); % prev step size is first guess!
   odtdJ=dtdJ; % one step before is same as current
   % pre-compute for speed later
	w0  = w; b0=b;
   wX0 = wX;
   dw  = d(1:end-1); db=d(end);
   dX  = dw'*X;
   if( ~isequal(mu,0) ) dmu = dw'*mu; else dmu=0; end;
   switch ( RType ) % diff types regularisor
    case 1; Rw=R*w;       dRw=dw'*Rw;  % scalar or full matrix
            Rd=R*dw;      dRd=dw'*Rd;
    case 2; Rw=R(:).*w;   dRw=dw'*Rw(:); % component weighting
            Rd=R(:).*dw;  dRd=dw'*Rd(:);
    case 3; Rw=R*reshape(w,szRw); dRw=dw'*Rw(:); % matrix weighting - leading dims
            Rd=R*reshape(dw,szRw);dRd=dw'*Rd(:); 
    case 4; Rw=reshape(w,szRw)*R; dRw=dw'*Rw(:); % matrix weighting - trailing dims
            Rd=reshape(dw,szRw)*R;dRd=dw'*Rd(:); 
    case 5; Rw=tprod(w,rdimIdx,R,[-(1:numel(szRw)) 1:numel(szRw)]);  dRw=dw'*Rw(:); % middle dims
            Rd=tprod(dw,rdimIdx,R,[-(1:numel(szRw)) 1:numel(szRw)]); dRd=dw'*Rd(:); % middle dims            
   end
   dtdJ0=abs(dtdJ); % initial gradient, for Wolfe 2 convergence test
   for j=1:opts.maxLineSrch;
      neval=neval+1;
      oodtdJ=odtdJ; odtdJ=dtdJ; % prev and 1 before grad values
      
		if ( 0 ) % Direct computation
		  w    = w0+tstep*dw;
		  wX   = w'*X;
		else % incremental computation
		  wX   = wX0+tstep*dX;
		end
		p    = 1./(1+exp(-(wX(:)+(b+tstep*db)))); % =Pr(x|y+)
		Yerr = Y1-p.*sY;
      dtdJ = -(2*(dRw+tstep*dRd) + dmu - dX*Yerr - db*sum(Yerr));
      %fprintf('.%d step=%g ddR=%g ddgdw=%g ddgdb=%g  sum=%g\n',j,tstep,2*(dRw+tstep*dRd),-dX*Yerr',-db*sum(Yerr),-dtdJ);
      if ( 0 ) % debug code to validate if the incremental gradient computation is valid
        swX  = (w0+tstep*dw)'*X;
		  p    = 1./(1+exp(-(swX(:)+(b+tstep*db)))); % =Pr(x|y+)
        %sw  = w + tstep*dw; 
        %sb  = b + tstep*db;
        sRw = R.*(w0+tstep*dw);%Rw+ tstep*Rd;
        % N.B. don't bother to compute the real gradient... we don't actually use it in the line search
        sdJ    = [2*sRw + mu - X*Yerr;...
                 -sum(Yerr)];
        sdtdJ   =-d'*sdJ;  % gradient along the line @ new position
		  Ed   = -(log(max(p,eps))'*Yi(:,1)+log(max(1-p,eps))'*Yi(:,2)); % P(D|w,b,fp)
		  Ew   = w(:)'*sRw(:);
        J    = Ed + Ew + opts.Jconst;              % J=neg log posterior
		  fprintf('.%da %g=%g @ %g (%g+%g)\n',j,tstep,sdtdJ,J,Ed,Ew); 
      end
            
      if ( opts.verb > 2 )
        %Ew   = w(:)'*Rw(:)+tstep*2*dRw+tstep.^2*dRd;  % w'*(R*reshape(w,szR));       % P(w,b|R);
        sw   = w0 + tstep*dw; 
        sb   = b  + tstep*db;
		  swX  = sw'*X;
		  p    = 1./(1+exp(-(swX(:)+(sb)))); % =Pr(x|y+)
        sRw  = R.*sw;
		  Ew   = sw(:)'*sRw(:);
		  Ed   = -(log(max(p,eps))'*Yi(:,1)+log(max(1-p,eps))'*Yi(:,2)); % P(D|w,b,fp)
        J    = Ed + Ew + opts.Jconst;              % J=neg log posterior
        if( ~isequal(mu,0) ) Emu=(w+tstep*d(1:end-1))'*mu; J=J+Emu; end;
        fprintf('.%d %g=%g @ %g (%g+%g)\n',j,tstep,dtdJ,J,Ed,Ew); 
        if ( opts.verb > 3 ) 
          plot(tstep,dtdJ,'*'); text(double(tstep),double(dtdJ),num2str(j));
        end
      end;

      % convergence test, and numerical res test
      if(iter>1||j>2) % Ensure we do decent line search for 1st step size!
         if ( abs(dtdJ) < opts.lstol0*abs(dtdJ0) || ... % Wolfe 2, gradient enough smaller
              abs(dtdJ*step) <= opts.tol )              % numerical resolution
            break;
         end
      end
      
      % now compute the new step size
      % backeting check, so it always decreases
      if ( oodtdJ*odtdJ < 0 && odtdJ*dtdJ > 0 ...      % oodtdJ still brackets
           && abs(step*dtdJ) > abs(odtdJ-dtdJ)*(abs(ostep+step)) ) % would jump outside 
         step = ostep + step; % make as if we jumped here directly.
         %but prev points gradient, this is necessary stop very steep orginal gradient preventing decent step sizes
         odtdJ = -sign(odtdJ)*sqrt(abs(odtdJ))*sqrt(abs(oodtdJ)); % geometric mean
      end
      ostep = step;
      % *RELATIVE* secant step size
      ddtdJ = odtdJ-dtdJ; 
      if ( ddtdJ~=0 ) nstep = dtdJ/ddtdJ; else nstep=1; end; % secant step size, guard div by 0
      nstep = sign(nstep)*max(opts.minStep,min(abs(nstep),opts.maxStep)); % bound growth/min-step size
      step  = step * nstep ;           % absolute step
      tstep = tstep + step;            % total step size      
   end
   if ( opts.verb > 2 ) fprintf('\n'); end;
   
   % Update the parameter values!
   % N.B. this should *only* happen here!
   w  = w0 + tstep*dw; 
   b  = b0 + tstep*db;
	if ( 1 ) % incremental compuation
     Rw = Rw + tstep*Rd;
	else % backup full computation
	  switch ( RType ) % diff types regularisor
		 case 1; Rw=R*w;                  % scalar or full matrix
		 case 2; Rw=R(:).*w;                 % component weighting
		 case 3; Rw=R*reshape(w,szRw);    % matrix weighting - leading dims
		 case 4; Rw=reshape(w,szRw)*R; % matrix weighting - trailing dims
		 case 5; Rw=tprod(w,rdimIdx,R,[-(1:numel(szRw)) 1:numel(szRw)]); % middle dims
	  end
	  wX   = w'*X;
	  p    = 1./(1+exp(-(wX(:)+b))); % =Pr(x|y+)
	end
   % compute the other bits needed for CG iteration
   dJ = [2*Rw(:) + mu - X*Yerr;...
         -sum(Yerr)];
   if ( size(PC,2)==1 ) % vector pre-conditioner
     MdJ  = PC.*dJ; % pre-conditioned gradient
   else % matrix pre-conditioner
     if ( size(PC,1)==size(X,1)+1 ) % PC is full size
       MdJ = PC*dJ;
     elseif ( RType==3 && size(wPC,1)==szX(1) ) % leading dim
       MdJ(1:end-1) = wPC*reshape(dJ(1:end-1),szX(1:2)); MdJ(end)=bPC*dJ(end);
     elseif ( RType==4 && size(wPC,1)==szX(end-1) ) % trailing dim
       MdJ(1:end-1) = reshape(dJ(1:end-1),szX(1:2))*wPC; MdJ(end)=bPC*dJ(end);
     else % now what?
       
     end
   end
   Mr =-MdJ;
   r2 =abs(Mr'*dJ); 
   
   % compute the function evaluation
	Ed   = -(log(max(p,eps))'*Yi(:,1)+log(max(1-p,eps))'*Yi(:,2)); % P(D|w,b,fp)
   Ew   = w'*Rw(:);% P(w,b|R);
   J    = Ed + Ew + opts.Jconst;       % J=neg log posterior
   if( ~isequal(mu,0) ) Emu=w'*mu; J=J+Emu; end;
   if(opts.verb>0)   % debug code      
      fprintf(['%3d) %3d x=[%8f,%8f,.] J=%5f (%5f+%5f) |dJ|=%8g' lend],...
              iter,neval,w(1),w(2),J,Ew,Ed,r2);
   end   

   if ( J > oJ*(1.001) || isnan(J) ) % check for stuckness
      if ( opts.verb>=1 ) warning(sprintf('%d) Line-search Non-reduction - aborted\n',iter)); end;
      J=oJ; w=ow; b=ob; 
      wX   = w'*X;
		nStuck=nStuck+1;
		if ( nStuck > 1 ) break; end;
	end;
   
   %------------------------------------------------
   % convergence test
   if ( iter==1 )     madJ=abs(oJ-J); dJ0=max(abs(madJ),eps); r02=max(r02,r2);
   elseif( iter<5 )   dJ0=max(dJ0,abs(oJ-J)); r02=max(r02,r2); % conv if smaller than best single step
   end
   madJ=madJ*(1-opts.marate)+abs(oJ-J)*(opts.marate);%move-ave objective grad est
   if ( r2<=opts.tol || ... % small gradient + numerical precision
        r2< r02*opts.tol0 || ... % Wolfe condn 2, gradient enough smaller
        neval > opts.maxEval || ... % abs(odtdJ-dtdJ) < eps || ... % numerical resolution
        madJ <= opts.objTol || madJ < opts.objTol0*dJ0 ) % objective function change
      break;
   end;    
   
   %------------------------------------------------
   % conjugate direction selection
   % N.B. According to wikipedia <http://en.wikipedia.org/wiki/Conjugate_gradient_method>
   %     PR is much better when have adaptive pre-conditioner so more robust in non-linear optimisation
   delta = max((Mr-oMr)'*(-dJ)/or2,0); % Polak-Ribier
   %delta = max(r2/or2,0); % Fletcher-Reeves
   d     = Mr+delta*d;     % conj grad direction
   dtdJ  = -d'*dJ;         % new search dir grad.
   if( dtdJ <= 0 )         % non-descent dir switch to steepest
      if ( opts.verb >= 2 ) fprintf('non-descent dir\n'); end;      
      d=Mr; dtdJ=-d'*dJ; 
   end; 
   
end;

if ( J > J0*(1+1e-4) || isnan(J) ) 
   if ( opts.verb>=0 ) warning('Non-reduction');  end;
   w=w0; b=b0;
end;

% compute the final performance with untransformed input and solutions
switch ( RType ) % diff types regularisor
 case 1; Rw=R*w;                  % scalar or full matrix
 case 2; Rw=R(:).*w;                 % component weighting
 case 3; Rw=R*reshape(w,szRw);    % matrix weighting - leading dims
 case 4; Rw=reshape(w,szRw)*R; % matrix weighting - trailing dims
 case 5; Rw=tprod(w,rdimIdx,R,[-(1:numel(szRw)) 1:numel(szRw)]); % middle dims
end
dv  = wX+b;
p   = 1./(1+exp(-dv(:)));         % [L x N] =Pr(x|y_+) = exp(w_ix+b)./sum_y(exp(w_yx+b));
Ed  = -(log(max(p,eps))'*Yi(:,1)+log(max(1-p,eps))'*Yi(:,2)); % expected loss
Ew   = w'*Rw(:);     % -ln P(w,b|R);
J    = Ed + Ew + opts.Jconst;       % J=neg log posterior
if( ~isequal(mu,0) ) Emu=w'*mu; J=J+Emu; end;
if ( opts.verb >= 0 ) 
   fprintf(['%3d) %3d x=[%8f,%8f,.] J=%5f (%5f+%5f) |dJ|=%8g\n'],...
           iter,neval,w(1),w(2),J,Ew,Ed,r2);
end

% compute final decision values.
if ( all(size(X)==size(oX)) ) f=dv; else f   = w'*oX + b; end;
f = reshape(f,[size(oY,1) 1]);
obj = [J Ew Ed];
wb=[w(:);b];
return;

%-----------------------------------------------------------------------
function [opts,varargin]=parseOpts(opts,varargin)
% refined and simplified option parser with structure flatten
i=1;
while i<=numel(varargin);  
   if ( iscell(varargin{i}) ) % flatten cells
      varargin={varargin{1:i} varargin{i}{:} varargin{i+1:end}};
   elseif ( isstruct(varargin{i}) )% flatten structures
      cellver=[fieldnames(varargin{i})'; struct2cell(varargin{i})'];
      varargin={varargin{1:i} cellver{:} varargin{i+1:end} };
   elseif( isfield(opts,varargin{i}) ) % assign fields
      opts.(varargin{i})=varargin{i+1}; i=i+1;
   else
      error('Unrecognised option');
   end
   i=i+1;
end
return;

%-----------------------------------------------------------------------------
function []=testCase()
%Make a Gaussian balls + outliers test case
nd=100; nClass=800;
[X,Y]=mkMultiClassTst([zeros(1,nd) -1 0 zeros(1,nd); zeros(1,nd) 1 0 zeros(1,nd); zeros(1,nd) .2 .5 zeros(1,nd)],[nClass nClass 50],[.3 .3; .3 .3; .2 .2],[],[-1 1 1]);[dim,N]=size(X);

wb0=randn(size(X,1)+1,1);
tic,lr_cg(X,Y,0,'verb',1,'objTol0',1e-10,'wb',wb0);toc


% now with indicator for Y
Yi=single(cat(2,Y(:)>0,Y(:)<0));
tic,lr_cg(X,Yi,0,'verb',1,'objTol0',1e-10,'wb',wb0);toc
% now with example weighting
wght  = .5+rand(size(Yi,1),1)*.5;
tic,[wb]=lr_cg(X,repop(Yi,'*',wght),0,'verb',1,'objTol0',1e-10,'wb',wb0);toc
% now heavily weighted universum examples
Ywght=Yi; Ywght(1:10,:)=6;
tic,[wb]=lr_cg(X,Ywght,0,'verb',1,'objTol0',1e-10,'wb',wb0);toc

clf;plotLinDecisFn(X,Y,wb(1:end-1),wb(end));


K=X'*X; tic, [alphab,f,J]=klr_cg(K,Y,0,'verb',1,'objTol0',1e-10);toc
wb=[X*alphab(1:end-1);alphab(end)];
dvk=wb(1:end-1)'*X+wb(end);

tic,[wb,f,Jlr]=lr_cg(X,Y,0,'verb',1,'objTol0',1e-10);toc
% compare with matlab builtin -- only for unreg situations
tic,[b]=glmfit(X,Y,'binomial','link','logit','constant','on');wb=[b(2:end);b(1)];toc
% only available in >R2012a
tic,[b]=lassoglm(X,Y,'binomial','link','logit','alpha',0,'lambda',0,'CV',1,'constant','on');wb=[b(2:end);b(1)];toc
dv=wb(1:end-1)'*X+wb(end);
mad(dvk,dv)

% same but now with a linear term
alpha0=randn(N,1); mu0=X*alpha0;
[alphab,J]=klr_cg(K,Y,[1 1],'mu',mu0,'verb',2);
[wb,J]    =lr_cg (X,Y,1,'mu',X*mu0,'verb',2);

% plot the resulting decision function
clf;plotLinDecisFn(X,Y,wb(1:end-1),wb(end));

trnInd=true(size(X,2),1);
fInds=gennFold(Y,10,'perm',1); 
trnInd=fInds(:,end)<0; tstInd=fInds(:,end)>0; trnSet=find(trnInd);

[wb0,f0,J0]=lr_cg(X(:,trnInd),Y(trnInd),1,'verb',1);
dv=wb(1:end-1)'*X(:,tstInd)+alphab(end);
dv2conf(Y(tstInd),dv(:))

% test implicit ignored
[wb,f,Jlr]=lr_cg(X,Y.*single(fInds(:,end)<0),1,'verb',1);

% test using the wght to ignore points
[wb,f,Jlr]=lr_cg(X,Y,1,'verb',1,'wght',single(trnInd));

% test the automatic pre-condnitioner 
lr_cg(X,Y,0,'wPC',1,'bPC',1); % no PC
lr_cg(X,Y,0,'PCmethod','wb0')% zeros PC
lr_cg(X,Y,0,'PCmethod','wb') % seed solution

lr_cg(X,Y,[10000000;ones(size(X,1)-1,1)],'verb',1,'objTol0',1e-10); % diff reg for diff parameters
lr_cg(X,Y,[10000000;ones(size(X,1)-1,1)],'verb',1,'objTol0',1e-10,'wPC',1./(1+[10000000;ones(size(X,1)-1,1)]));
lr_cg(repop([1e6;ones(size(X,1)-1,1)],'*',X),Y,1,'verb',1,'objTol0',1e-10,'wPC',1); %re-scale the data, no PC
lr_cg(repop([1e6;ones(size(X,1)-1,1)],'*',X),Y,1,'verb',1,'objTol0',1e-10); %re-scale the data, auto PC

% test matrix pre-conditioner
lr_cg(X,Y,diag([10000000;ones(size(X,1)-1,1)]),'verb',1,'objTol0',1e-10,'wPC',diag(1./(1+[10000000;ones(size(X,1)-1,1)])));

% test non-diagonal regularisor
w=randn(size(X,1),1); w=w./norm(w);
R=eye(size(X,1))+10000*w*w';
P=eye(size(X,1))-w*(1-1./10000)*w';
lr_cg(X,Y,R,'verb',1,'objTol0',1e-10);
% and now with the corrospending pre-conditioner
lr_cg(X,Y,R,'verb',1,'objTol0',1e-10,'wPC',P);

% test leading dims block regularisor and PC
X2d=reshape(X,[size(X,1)/4 4 size(X,2)]);
w  =randn(size(X2d,1),1); w=w./norm(w);
R  =eye(size(X2d,1))+100000*w*w';
P  =eye(size(X2d,1))-w*(1-1/100000)*w';
lr_cg(X2d,Y,R,'verb',1,'objTol0',1e-10);
% and now with the corrospending pre-conditioner
lr_cg(X2d,Y,R,'verb',1,'objTol0',1e-10,'wPC',P);


% test re-seeding for increasing Cs
Cs=2.^(1:7);
% without re-seeding
for ci=1:numel(Cs);
  [wbs(:,ci),f,Jlr]=lr_cg(X(:,trnInd),Y(trnInd),Cs(ci),'verb',1);
end
% with re-seeding
[wbs(:,1),f,Jlr]=lr_cg(X(:,trnInd),Y(trnInd),Cs(1),'verb',1,'wb',[]);
for ci=2:numel(Cs);
  [wbs(:,ci),f,Jlr]=lr_cg(X(:,trnInd),Y(trnInd),Cs(ci),'verb',1,'wb',wbs(:,ci-1));
end

% simple regulasor
tic,[wb,f,J]=lr_cg(X2d,Y,1,'verb',1,'dim',3);toc;

% test using a re-scaling regularisor
R=rand(size(X,1),1);
% transform both X and R to give the same as the orginal problem, just re-scaled
tic,[wb,f,Jlr]=lr_cg(repop(X,'*',sqrt(R)),Y,diag(R),'verb',1);toc
tic,[wb,f,Jlr]=lr_cg(repop(X,'*',sqrt(R)),Y,R,'verb',1);toc
% transform only R or only X to give the same problem
[wb,f,Jlr]=lr_cg(X(:,trnInd),Y(trnInd),R,'verb',1);
[wb,f,Jlr]=lr_cg(repop(X(:,trnInd),'*',1./sqrt(R)),Y(trnInd),1,'verb',1);

% try a regularisor which imposes that both components should be similar
% R=[1 -1;-1 1] thus high cross correlations are good
R=-ones(size(X,1),size(X,1));R(1:size(R,1)+1:end)=1; 
[wb,f,Jlr]=lr_cg(X(:,trnInd),Y(trnInd),R,'verb',1);

% test using mu to specify a prior towards a particular solution
mu=[1 1]';
[wb,f,Jlr]=lr_cg(X(:,trnInd),Y(trnInd),64,'verb',1,'mu',64*-2*mu);
Cs=2.^(1:7);
for ci=1:numel(Cs);
  [wbs(:,ci),f,Jlr]=lr_cg(X(:,trnInd),Y(trnInd),Cs(ci),'verb',1,'mu',Cs(ci)*-2*mu,'Jconst',Cs(ci)*mu'*mu);
end
clf;plot(wbs)

% test iterative approx to the l1 loss
tic,
C=1; eta=1; %eta=1e-10;
[wb0,f0,J0]=lr_cg(X(:,trnInd),Y(trnInd),C/2,'verb',1,'objTol0',1e-1,'maxIter',2);
wbs=wb0;
for i=1:20;
  oJ=J;
  W  = wbs(1:end-1,i); b=wbs(end,i);
  Ew = sum(abs(W));
  wX = W(:)'*X;
  dv = wX+b;
  g  = 1./(1+exp(-Y'.*dv));         % Pr(x|y)
  Ed = -log(max(g,eps))*(Y.*Y); % -ln P(D|w,b,fp)
  J  = Ed+C*Ew;
  if ( (oJ-J)<1e-2 ) eta=eta/2; end; 
  fprintf('%3d) w=[%s]  J=%5.3f (%5.3f+%5.3f) eta=%5.3g\n',i,sprintf('%5.3f,',W(1:min(end,4))),J,Ew(1:min(end,3)),Ed,eta);
  % N.B. only solve each sub-problem approximately as we're going to update the reg and solve again later anyway
  R  = (1./max(abs(W),eta))/2;  
  [wb,f,Jlr]=lr_cg(X(:,trnInd),Y(trnInd),C*R,'verb',-1,'wb',wbs(:,i),'objTol0',1e-1,'maxIter',size(X,1));
  wbs(:,i+1)=wb;
end
toc



% test iterative approx to the groupwise - l2/l1 loss
tic,
C=1; eta=.01; %eta=1e-10;
% % non-overlapping groups of 3 variables
% structMx=zeros(size(X,1),size(X,1)/3); for i=1:size(structMx,2); structMx((i-1)*3+(1:3),i)=1; end;
% % overlapping groups - linear
% structMx=zeros(size(X,1),size(X,1)); for i=1:size(structMx,1); structMx(i:end,i)=1; end; 
% overlapping groups - linear, bi-directional
structMx=zeros(size(X,1),size(X,1)*2); for i=1:size(structMx,1); structMx(i:end,i*2-1)=1; structMx(1:i,i*2)=1;end; 
% % overlapping groups - graph (graph lasso)
% structMx=zeros(size(X,1),size(X,1)); for i=1:size(structMx,2)-1; structMx(i:i+1,i)=1; end; 
% normalise group weighting
structMx=repop(structMx,'./',max(eps,sum(structMx))); % unit value in each group
% normalise so that structured reg has same norm as diag regularisor
structMx=structMx*size(X,1)/sum(structMx(:));
% seed solution
[wb0,f0,J0]=lr_cg(X(:,trnInd),Y(trnInd),C*10,'verb',1,'objTol0',1e-1,'maxIter',size(X,1));
wbs=wb0;
for i=1:20;
  oJ=J;
  W  = wbs(1:end-1,i); b=wbs(end,i);
  nrms= sqrt((W(:).^2)'*structMx);
  Ew = sum(nrms);
  wX = W(:)'*X;
  dv = wX+b;
  g  = 1./(1+exp(-Y'.*dv));         % Pr(x|y)
  Ed = -log(max(g,eps))*(Y.*Y); % -ln P(D|w,b,fp)
  J  = Ed+C*Ew;
  if ( (oJ-J)<1e-2 ) eta=eta/2; end; 
  fprintf('%3d) w=[%s]  J=%5.3f (%5.3f+%5.3f) eta=%5.3g\n',i,sprintf('%5.3f,',W(1:min(end,4))),J,Ew(1:min(end,3)),Ed,eta);
  % N.B. only solve each sub-problem approximately as we're going to update the reg and solve again later anyway
  R    = structMx*(1./max(nrms(:),eta)); % variational coefficient for each variable
  [wb,f,Jlr]=lr_cg(X(:,trnInd),Y(trnInd),C*R,'verb',-1,'wb',wbs(:,i),'objTol0',2e-1,'maxIter',size(X,1));
  wbs(:,i+1)=wb;
end
toc


% test iterative approx to the groupwise edge regularisor 
tic,
C=1; eta=.01; %eta=1e-10;
% % non-overlapping groups of 3 variables
structMx=zeros(size(X,1),size(X,1)/3); for i=1:size(structMx,2); structMx((i-1)*3+(1:3),i)=1; end;
% overlapping groups
%structMx=zeros(size(X,1),size(X,1)); for i=1:size(structMx,2); structMx(i:end,i)=1; end; 
% normalise group weighting
structMx=repop(structMx,'./',max(eps,sum(structMx))); % unit value in each group
% normalise so that structured reg has same norm as diag regularisor
structMx=structMx*size(X,1)/sum(structMx(:));
% seed solution
[wb0,f0,J0]=lr_cg(X(:,trnInd),Y(trnInd),C*10,'verb',1,'objTol0',1e-1,'maxIter',size(X,1));
wbs=wb0;
for i=1:20;
  oJ=J;
  W  = wbs(1:end-1,i); b=wbs(end,i);
  nrms= sqrt((W(:).^2)'*structMx);
  Ew = sum(nrms);
  wX = W(:)'*X;
  dv = wX+b;
  g  = 1./(1+exp(-Y'.*dv));         % Pr(x|y)
  Ed = -log(max(g,eps))*(Y.*Y); % -ln P(D|w,b,fp)
  J  = Ed+C*Ew;
  if ( (oJ-J)<1e-2 ) eta=eta/2; end; 
  fprintf('%3d) w=[%s]  J=%5.3f (%5.3f+%5.3f) eta=%5.3g\n',i,sprintf('%5.3f,',W(1:min(end,4))),J,Ew(1:min(end,3)),Ed,eta);
  % N.B. only solve each sub-problem approximately as we're going to update the reg and solve again later anyway
  R    = structMx*(1./max(nrms(:),eta)); % variational coefficient for each variable
  [wb,f,Jlr]=lr_cg(X(:,trnInd),Y(trnInd),C*R,'verb',-1,'wb',wbs(:,i),'objTol0',2e-1,'maxIter',size(X,1));
  wbs(:,i+1)=wb;
end
toc

% test 2d inputs and replicated regulisor
X2d=reshape(X,[3,size(X,1)/3,size(X,2)]);
R=diag([10 1 1]); % force to not use dim(1)
% 1st with explicit R
Rfull=zeros(size(X,1),size(X,1));
for i=1:size(R,1):size(Rfull,1); Rfull(i-1+(1:size(R,1)),i-1+(1:size(R,2)))=R; end;
[wb,f,Jlr]=lr_cg(X,Y,Rfull,'verb',1);
tic,for i=1:10; [wb,f,Jlr]=lr_cg(X,Y,Rfull,'verb',1); end;toc
% then with implicit one
[wb,f,Jlr]=lr_cg(X2d,Y,R,'verb',1);
tic,for i=1:10; [wb,f,Jlr]=lr_cg(X2d,Y,R,'verb',1); end; toc

% test iterative approx to low rank solution finding
tic,
C=1; eta=1;
X2d=reshape(X,[3,4,size(X,2)]);
% test does swaping the dimensions order affect the solution
%X2d=permute(reshape(X,[3,4,size(X,2)]),[2 1 3]); 
[wb0,f0,J0,obj]=lr_cg(X2d,Y,C/2,'verb',0,'objTol0',1e-2,'maxIter',size(X,1));
wbs=wb0; Ws=[]; Us=[]; Ss=[]; Vs=[]; 
i=1;J=inf;
for i=1:size(X2d,1)*10;
  oJ=J;
  W=reshape(wbs(1:end-1,i),size(X2d,1),size(X2d,2)); b=wbs(end,i);
  Ws(:,:,i)=W; 
  [U,S,V]=svd(W,'econ'); S=diag(S);
  Us(:,:,i)=U;Ss(:,i)=S;Vs(:,:,i)=V;
  Ew   = sum(abs(S));
  wX   = W(:)'*reshape(X2d,[],size(X2d,ndims(X2d)));;
  dv   = wX+b;
  g    = 1./(1+exp(-Y'.*dv));         % Pr(x|y)
  Ed   = -log(max(g,eps))*(Y.*Y); % -ln P(D|w,b,fp)
  J =Ed+C*Ew;
  if ( (oJ-J)<1e-2 && min(abs(S))<eta ) eta=eta/2; end; 
  if ( mod(i,1)==0 ) fprintf('%3d) w=[%s]  J=%5.3f (%5.3f+%5.3f) eta=%g\n',i,sprintf('%5.3f,',S),J,Ew,Ed,eta); end;
  R=eye(size(U,1),size(U,1))*1./(eta) + U*diag((1./(max(abs(S),eta))-1/(eta)))*U'; % leading dim
  %R=eye(size(V,1),size(V,1))*1./(eta) + V*diag((1./(max(abs(S),eta))-1/(eta)))*V'; % trailing dim
  R=R/2;
  % N.B. only solve each sub-problem approximately as we're going to update the reg and solve again later anyway
  [wb,f,Jlr,obj]=lr_cg(X2d,Y,C*R,'verb',-1,'wb',wbs(:,i),'objTol0',1e-1,'maxIter',size(X,1));
  wbs(:,i+1)=wb;
end
toc

% test iterative approx to low rank solution + channel selection
tic,
C=1; eta=1e-4;
[wb0,f0,J0]=lr_cg(X2d,Y,C/2,'verb',1,'objTol0',1e-1,'maxIter',2);
wbs=wb0; i=1;
for i=1:100;
  W=reshape(wbs(1:end-1,i),size(X2d,1),size(X2d,2));
  [U,S,V]=svd(W,'econ'); S=diag(S);
  nrmC = sqrt(sum(W.^2,2));
  fprintf('%3d) r=[%s] c=[%s]\n',i,sprintf('%5.3f,',S),sprintf('%5.3f,',nrmC));
  R=U*diag(1./abs(S))*U' + diag(1./abs(nrmC))*15;
  R=R/2;
  % N.B. only solve each sub-problem approximately as we're going to update the reg and solve again later anyway
  [wb,f,Jlr]=lr_cg(X2d,Y,C*R,'verb',-1,'wb',wbs(:,i),'objTol0',1e-1,'maxIter',size(X,1));
  wbs(:,i+1)=wb;
end
toc



% test iterative approx to low rank solution finding -- 
%  alt reg where we project on the decomposition of the current solution
tic,
C=1; eta=1;
X2d=reshape(X,[3,4,size(X,2)]);
% test does swaping the dimensions order affect the solution
X2d=permute(reshape(X,[3,4,size(X,2)]),[2 1 3]); 
[wb0,f0,J0]=lr_cg(X2d,Y,C/2,'verb',1,'objTol0',1e-1,'maxIter',2);
wbs=wb0;  Ws=[]; Us=[]; Ss=[]; Vs=[]; 
i=1; J=inf;
for i=1:size(X,1)*10;
  oJ=J;
  %if ( mod(i,size(X,1))==0 ) eta=eta/5; end;
  W=reshape(wbs(1:end-1,i),size(X2d,1),size(X2d,2));
  Ws(:,:,i)=W; 
  [U,S,V]=svd(W,'econ'); S=diag(S);
  Us(:,:,i)=U;Ss(:,i)=S;Vs(:,:,i)=V;
  Ew   = sum(abs(S));
  wX   = W(:)'*reshape(X2d,[],size(X2d,ndims(X2d)));;
  dv   = wX+b;
  g    = 1./(1+exp(-Y'.*dv));         % Pr(x|y)
  Ed   = -log(max(g,eps))*(Y.*Y); % -ln P(D|w,b,fp)
  J    = Ed+C*Ew;
  if ( (oJ-J)<1e-5 && min(abs(S))<eta ) eta=eta/2; end; 
  if (mod(i,1)==0)fprintf('%3d) w=[%s]  J=%5.3f (%5.3f+%5.3f) eta=%g\n',i,sprintf('%5.3f,',S),J,Ew,Ed,eta);end;
  R=eye(numel(W),numel(W))*1./(eta);
  for ri=1:numel(S); Ww = U(:,ri)*V(:,ri)'; R=R+(1./(max(abs(S(ri)),eta))-1/eta)*Ww(:)*Ww(:)'; end;
  R=R/2;
  % N.B. only solve each sub-problem approximately as we're going to update the reg and solve again later anyway
  [wb,f,Jlr]=lr_cg(X2d,Y,C*R,'verb',-1,'wb',wbs(:,i),'objTol0',1e-1,'maxIter',size(X,1));
  wbs(:,i+1)=wb; 
end
toc


% test iterative approx to low tensor-rank solution finding -- 
%  alt reg where we project on the decomposition of the current solution
tic,
C=1; eta=.001;
X3d=reshape(X,[3,4,size(X,1)/3/4,size(X,2)]);
[wb0,f0,J0]=lr_cg(X3d,Y,C/2,'verb',1,'objTol0',1e-1,'maxIter',2);
wbs=wb0;  Ws=[]; Us=[]; Ss=[]; Vs=[];  Zs=[];
i=1; J=inf; rank=max([size(X3d,1),size(X3d,2),size(X3d,3)])+5;
for i=1:100;
  oJ=J;
  %if ( mod(i,size(X,1))==0 ) eta=eta/5; end;
  W=reshape(wbs(1:end-1,i),size(X3d,1),size(X3d,2),size(X3d,3));
  Ws(:,:,:,i)=W; 
  if ( i==1 ) % use a few random re-starts to get a minimum degeneracy solution
    [S,U,V,Z]=parafac_als_inc(W,'rank',rank,'verb',1,'orthoPen',1e6);
    %[c,cc,cmx]=parafacCorr({S U V Z});degen=prod(cmx,3)-eye(size(cmx,1));clf;imagesc(degen);set(gca,'clim',[-1 1]*max(abs(degen(:))));colormap ikelvin;colorbar
    % mS=inf;
    % for ri=1:50; 
    %   [Sr,Ur,Vr,Zr]=parafac_als(W,'rank',rank,'C1',1e-7,'priorC',.1,'verb',0,'objTol0',0,'tol0',1e-1,'maxIter',20);
    %   if ( sum(Sr) < mS ) mS=sum(Sr); S=Sr; U=Ur; V=Vr; Z=Zr; end;
    % end
  end
  [S,U,V,Z]=parafac_als_inc(W,'rank',rank,'seed',{S U V Z},'verb',1,'objTol0',1e-4,'orthoPen',1e7);
  Us(:,:,i)=U;Ss(:,i)=S;Vs(:,:,i)=V;Zs(:,:,i)=Z;
  Ew   = sum(abs(S));
  wX   = W(:)'*reshape(X3d,[],size(X2d,ndims(X2d)));;
  dv   = wX+b;
  g    = 1./(1+exp(-Y'.*dv));         % Pr(x|y)
  Ed   = -log(max(g,eps))*(Y.*Y); % -ln P(D|w,b,fp)
  J    = Ed+C*Ew;
  if ( abs(oJ-J)<1e-2 ) eta=eta/2; end; 
  if (mod(i,1)==0)fprintf('%3d) w=[%s]  J=%5.3f (%5.3f+%5.3f) eta=%g\n',i,sprintf('%5.3f,',S),J,Ew,Ed,eta);end;
  R=eye(numel(W),numel(W))*1./(eta);
  for ri=1:numel(S);  % N.B. this only really works if the components are *orthogonal*
    Ww = repop(U(:,ri)*V(:,ri)','*',shiftdim(Z(:,ri),-2)); R=R+(1./(max(abs(S(ri)),eta))-1/eta)*Ww(:)*Ww(:)'; 
  end;
  R=R/2;
  % N.B. only solve each sub-problem approximately as we're going to update the reg and solve again later anyway
  [wb,f,Jlr]=lr_cg(X3d,Y,C*R,'verb',-1,'wb',wbs(:,i),'objTol0',1e-1,'maxIter',size(X,1));
  wbs(:,i+1)=wb; 
end
toc
