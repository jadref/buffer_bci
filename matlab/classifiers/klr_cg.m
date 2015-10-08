function [wb,f,J,obj]=klr_cg(K,Y,C,varargin);
% Regularised Kernel Logistic Regression Classifier
%
% [alphab,f,J,obj]=klr_cg(K,Y,C,varargin)
% Regularised Kernel Logistic Regression Classifier using a pre-conditioned
% conjugate gradient solver on the primal objective function
%
% J = C(1) w' K w + C(2) w'*K mu + sum_i log( (1 + exp( - y_i ( w'*K_i + b ) ) )^-1 ) 
%
% Inputs:
%  K       - [NxN] kernel matrix
%  Y       - [Nx1] matrix of -1/0/+1 labels, (0 label pts are implicitly ignored)
%  C       - the regularisation parameter, roughly max allowed length of the weight vector
%            good default is: .1*var(data) = .1*(mean(diag(K))-mean(K(:))))
%
% Outputs:
%  alphab  - [(N+1)x1] matrix of the kernel weights and the bias [alpha;b]
%  f       - [Nx1] vector of decision values
%  J       - the final objective value
%  obj     - [J Ew Ed]
%  p       - [Nx1] vector of conditional probabilities, Pr(y|x)
%  mu      - [Nx1] vector containing mu
%
% Options:
%  alphab  - [(N+1)x1] initial guess at the kernel parameters, [alpha;b] ([])
%  ridge   - [float] ridge to add to the kernel to improve convergence.  
%             ridge<0 -- absolute ridge value
%             ridge>0 -- size relative to the mean kernel eigenvalue
%  maxEval - [int] max number for function evaluations                    (N*5)
%  maxIter - [int] max number of CG steps to do                           (inf)
%  maxLineSrch - [int] max number of line search iterations to perform    (50)
%  objTol0 - [float] relative objective gradient tolerance                (1e-5)
%  objTol  - [float] absolute objective gradient tolerance                (0)
%  tol0    - [float] relative gradient tolerance, w.r.t. initial value    (0)
%  lstol0  - [float] line-search relative gradient tolerance, w.r.t. initial value   (1e-2)
%  tol     - [float] absolute gradient tolerance                          (0)
%  verb    - [int] verbosity                                              (0)
%  step    - initial step size guess                                      (1)
%  wght    - point weights [Nx1] vector of label accuracy probabilities   ([])
%            [2x1] for per class weightings
%            [1x1] relative weight of the positive class
%            N.B. to give each class equal importance use: wght= [1/np 1/nn]*(np+nn)
%                 where np=number positive examples, nn=number negative examples
%  nobias  - [bool] flag we don't want the bias computed                  (false)
% Copyright 2006-     by Jason D.R. Farquhar (jdrf@zepler.org)

% Permission is granted for anyone to copy, use, or modify this
% software and accompanying documents for any uncommercial
% purposes, provided this copyright notice is retained, and note is
% made of any changes that have been made. This software and
% documents are distributed without any warranty, express or
% implied
if ( nargin < 3 ) C(1)=0; end;
opts=struct('alphab',[],'dim',[],'mu',[],'Jconst',0,...
            'maxIter',inf,'maxEval',[],'tol',0,'tol0',0,'lstol0',1e-5,'objTol',0,'objTol0',1e-4,...
            'verb',0,'step',0,'wght',[],'X',[],'ridge',0,'maxLineSrch',50,...
            'maxStep',3,'minStep',5e-2,'marate',.95,'bPC',[],'incThresh',.75,'optBias',0,'maxTr',inf);
[opts,varargin]=parseOpts(opts,varargin{:});
opts.ridge=opts.ridge(:);
if ( isempty(opts.maxEval) ) opts.maxEval=5*sum(Y(:)~=0); end
% Ensure all inputs have a consistent precision
if(isa(K,'double') & isa(Y,'single') ) Y=double(Y); end;
if(isa(K,'single')) eps=1e-7; else eps=1e-16; end;
opts.tol=max(opts.tol,eps); % gradient magnitude tolerence

[dim,N]=size(K); Y=Y(:); % ensure Y is col vector

% check for degenerate inputs
if ( all(Y>=0) || all(Y<=0) )
  warning('Degnerate inputs, 1 class problem');
end

if ( opts.ridge>0 ) % make the ridge relative to the max eigen-value
   opts.ridge = opts.ridge*median(abs(diag(K)));
   ridge = opts.ridge;
else % negative value means absolute ridge
   ridge = abs(opts.ridge);
end

% check if it's more efficient to sub-set the kernel, because of lots of ignored points
oK=K; oY=Y;
incIdx=Y(:)~=0;
if ( sum(incIdx)./numel(Y) < opts.incThresh ) % if enough ignored to be worth it
   if ( sum(incIdx)==0 ) error('Empty training set!'); end;
   K=K(incIdx,incIdx); Y=Y(incIdx);
end

% generate an initial seed solution if needed
wb=opts.alphab;   % N.B. set the initial solution
if ( ~isempty(wb) )
  if ( size(K,1)~=numel(wb)-1 ) wb=[wb(incIdx);wb(end)]; end;
else
  wb=zeros(size(K,1)+1,1,class(K)); 
  %N.B. this doesn't actually seem to help reduce the total number of iterations cv. prototype clsfr
  if ( 0 && size(K,1)>=1.5*opts.maxTr && all(wb==0) ) % use sub-set to get seed solution
    subidx =false(size(Y)); 
    pIdx=find(Y>0);perm=randperm(numel(pIdx));subidx(pIdx(perm(1:min(end,floor(opts.maxTr./2)))))=true;
    nIdx=find(Y<0);perm=randperm(numel(nIdx));subidx(nIdx(perm(1:min(end,floor(opts.maxTr./2)))))=true;
    wb0 = klr_cg(K(subidx,subidx),Y(subidx),C.*sum(subidx)/size(K,1)*2,opts); % N.B. re-scale C for less pts
    wb(subidx) = wb0(1:end-1); wb(end)=wb0(end);
  
  else % use a prototype classifier to get initial seed solution    
   % prototype classifier seed
   wb(Y>0)=.5./sum(Y>0); wb(Y<0)=-.5./sum(Y<0); % vector between pos/neg class centers
   wK = wb(1:end-1)'*K; 
   if(sum(incIdx)<size(K,2)) wK(~incIdx)=0; end % prevent cheating by using test-trial information
   % find least squares optimal scaling and bias
   sb = pinv([C(1)*wK*wb(1:end-1)+wK*wK' sum(wK); sum(wK) sum(Y~=0)])*[wK*Y; sum(Y)];
   wb(1:end-1)=wb(1:end-1)*sb(1); wb(end)=sb(2);
 end
end 

% N.B. this form of loss weighting has no true probabilistic interpertation!
wght=1;wghtY=Y;
if ( ~isempty(opts.wght) ) % point weighting -- only needed in wghtY
   if ( numel(opts.wght)==1 ) % weight ratio between classes
     wght=zeros(size(Y));
     wght(Y<0)=1./sum(Y<0)*opts.wght; wght(Y>0)=(1./sum(Y>0))*opts.wght;
     wght = wght*sum(abs(Y))./sum(abs(wght)); % ensure total weighting is unchanged
   elseif ( numel(opts.wght)==2 ) % per class weights
     wght=zeros(size(Y));
     wght(Y<0)=opts.wght(1); wght(Y>0)=opts.wght(2);
   elseif ( numel(opts.wght)==N )
     wght=opts.wght;
   else
     error('Weight must be 2 or N elements long');
   end
   wghtY=wght.*Y;
end

% Normalise the kernel to prevent rounding issues causing convergence problems
% = average kernel eigen-value + regularisation const = ave row norm
diagK= K(1:size(K,1)+1:end); 
if ( sum(incIdx)<size(K,1) ) diagK=diagK(incIdx); end;
muEig=median(diagK); % approx hessian scaling, for numerical precision
% adjust alpha and regul-constant to leave solution unchanged
wb(1:end-1)=wb(1:end-1)*muEig;
C(1) = C(1)./muEig;

% set the bias (i.e. b) pre-conditioner
bPC=opts.bPC;
if ( isempty(bPC) ) % bias pre-condn with the diagonal of the hessian
   bPC  = sqrt(abs(muEig + 2*C(1))./muEig);   % N.B. use sqrt for safety?
   bPC  = 1./bPC;
   %fprintf('bPC=%g\n',bPC);
end

mu=opts.mu; 
if( ~isempty(mu) ) 
  muK  = mu'*K; 
  C(end+1:2)=1; 
  % include effect of the kernel normalisation
  mu=mu.*muEig; 
  C(2)=C(2)./muEig;   
else 
  mu=0; muK=0; C(2)=0; 
end;

wK   = (wb(1:end-1)'*K + ridge'.*wb(1:end-1)')./muEig;

% find least squares optimal scaling and bias
% sb=pinv([C(1)*wK*wb(1:end-1)+wK*(wght.*wK)' sum(wK*wght); ...
%          sum(wK*wght) sum(wght'*single(Y~=0))])*[wK*(wght.*Y); sum(wght'*Y)];
% wb(1:end-1)=wb(1:end-1)*sb(1); wK=wK*sb(1); wb(end)=sb(2);

dv   = wK+wb(end);
g    = 1./(1+exp(-Y'.*dv)); g=max(g,eps); % =Pr(x|y), max to stop log 0
Yerr = wghtY'.*(1-g);

% precond'd gradient:
%  [K  0  ]^-1 [(lambda*wK-K((1-g).Y))] = [lambda w - (1-g).Y]
%  [0  bPC]    [ -1'*((1-g).Y)        ]   [ -1'*(1-g).Y./bPC  ] 
MdJ   = [(2*C(1)*wb(1:end-1) + C(2)*mu - Yerr'); ...
         -sum(Yerr)./bPC];
dJ    = [(K*MdJ(1:end-1)+ridge*MdJ(1:end-1))./muEig; ...
         -sum(Yerr)];
% MdJ   = [(C(1)*wb(1:end-1) - Yerr')./diag(K); -sum(Yerr) ];
% dJ    = [K*(MdJ(1:end-1).*diag(K)); MdJ(end)];
Mr   =-MdJ;
d    = Mr;
dtdJ =-(d'*dJ);
r2   = dtdJ;
r02  = r2;

Ed   = -log(g)*(Y.*wghtY); % -ln P(D|w,b,fp)
Ew   = wK*wb(1:end-1);     % -ln P(w,b|R);
J    = Ed + C(1)*Ew;       % J=neg log posterior
if( C(2) ) 
  Emu  = muK*wb(1:end-1); 
  J    = J+ C(2)*Emu + opts.Jconst;
end

% Set the initial line-search step size
step=opts.step;
if( step<=0 ) step=min(sqrt(abs(J/max(dtdJ,eps))),1); end %init step assuming opt is at 0
step=abs(step); tstep=step;

neval=1; lend='\r';
if(opts.verb>0)   % debug code      
   if ( opts.verb>1 ) lend='\n'; else fprintf('\n'); end;
   fprintf(['%3d) %3d x=[%5f,%5f,.] J=%5f (%5f+%5f) |dJ|=%8g\n'],0,neval,wb(1),wb(2),J,Ew./muEig,Ed,r2);
end

% pre-cond non-lin CG iteration
J0=J; madJ=abs(J); % init-grad est is init val
wb0=wb; Kd=zeros(size(wb),class(wb)); dJ=zeros(size(wb),class(wb));
for iter=1:min(opts.maxIter,2e6);  % stop some matlab versions complaining about index too big

   oJ= J; oMr  = Mr; or2=r2; owb=wb; % record info about prev result we need

   %---------------------------------------------------------------------
   % Secant method for the root search.
   if ( opts.verb > 2 )
      fprintf('.%d %g=%g @ %g (%g+%g)\n',0,0,dtdJ,J,Ed,Ew./muEig); 
      if ( opts.verb>3 ) 
         hold off;plot(0,dtdJ,'r*');hold on;text(0,double(dtdJ),num2str(0)); 
         grid on;
      end
   end;
   ostep=inf;step=tstep;%max(tstep,abs(1e-6/dtdJ)); % prev step size is first guess!
   odtdJ=dtdJ; % one step before is same as current
   wK0 = wK;
   dK  = (d(1:end-1)'*K+d(1:end-1)'.*ridge')./muEig; % N.B. v'*M is 50% faster than M*v'!!!
   db  = d(end);
   dKw = dK*wb(1:end-1); dKd=dK*d(1:end-1);
   if ( C(2) ) dKmu=muK*d(1:end-1); end;
   dtdJ0=abs(dtdJ); % initial gradient, for Wolfe 2 convergence test
   for j=1:opts.maxLineSrch;
      neval=neval+1;
      oodtdJ=odtdJ; odtdJ=dtdJ; % prev and 1 before grad values
      
      % Eval the gradient at this point.  N.B. only gradient needed for secant
      wK    = wK0    + tstep*dK; 
      b     = wb(end)+ tstep*d(end);
      g     = 1./(1+exp(-Y'.*(wK+b))); 
      Yerr  = wghtY'.*(1-g);
      %MdJ   = [2*C(1)*wb(1:end-1) - Yerr';...
      %         -sum(Yerr)./bPC];
      %dJ   = [(K*MdJ(1:end-1)+ridge.*MdJ(1:end-1))./muEig; ...
      %         bPC*MdJ(end)];
      %dtdJ   =-d'*dJ; = d'*M^-1*MdJ = ([K,bPC]d)'*MdJ  % gradient along the line @ new position
      dtdJ   =-(2*C(1)*(dKw+tstep*dKd) - dK*Yerr' + -db*sum(Yerr)); % gradient along the line @ new position
      if ( C(2) ) dtdJ = dtdJ - C(2)*dKmu; end;
      
      if ( opts.verb > 2 )
         Ed   = -log(max(g,eps))*(Y.*wghtY);         % P(D|w,b,fp)
         Ew   = wK*wb(1:end-1)+tstep*wK*d(1:end-1);  % P(w,b|R);
         J    = Ed + C(1)*Ew;               % J=neg log posterior         
         if( C(2) ) 
           Emu  = muK*wb(1:end-1) + tstep*muK*d(1:end-1); 
           J    = J+ C(2)*Emu + opts.Jconst;
         end
         fprintf('.%d %g=%g @ %g (%g+%g)\n',j,tstep,dtdJ,J,Ew./muEig,Ed); 
         if ( opts.verb > 3 ) 
            plot(tstep,dtdJ,'*'); text(double(tstep),double(dtdJ),num2str(j));
         end
      end;

      % convergence test, and numerical res test
      if(iter>1|j>3) % Ensure we do decent line search for 1st step size!
         if ( abs(dtdJ) < opts.lstol0*abs(dtdJ0) | ... % Wolfe 2, gradient enough smaller
              abs(dtdJ*step) <= opts.tol )              % numerical resolution
            break;
         end
      end
      
      % now compute the new step size
      % backeting check, so it always decreases
      if ( oodtdJ*odtdJ < 0 & odtdJ*dtdJ > 0 ...      % oodtdJ still brackets
           & abs(step*dtdJ) > abs(odtdJ-dtdJ)*(abs(ostep+step)) ) % would jump outside 
        step = ostep + step; % make as if we jumped here directly.
        % but prev points gradient, this is necessary stop very steep orginal gradient preventing decent step sizes
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
   % update the solution with this step
   wb  = wb + tstep*d;
      
   % compute the other bits needed for CG iteration
   MdJ   = [2*C(1)*wb(1:end-1) + C(2)*mu - Yerr';...
            -sum(Yerr)./bPC];
   dJ(1:end-1) = (MdJ(1:end-1)'*K+MdJ(1:end-1)'.*ridge)./muEig;
   dJ(end)     = bPC*MdJ(end);
   %dJ(1:end-1) = (2*C(1)*wK + C(2)*muK./muEig -(Yerr*K)./muEig); % N.B. wK0 and dK already include muEig
   %dJ(end)     = bPC*MdJ(end);
   Mr =-MdJ;
   r2 =abs(Mr'*dJ); 
      % compute the function evaluation
   Ed   = -log(max(g,eps))*(Y.*wghtY);% P(D|w,b,fp)
   Ew   = wK*wb(1:end-1);             % P(w,b|R);
   J    = Ed + C(1)*Ew;               % J=neg log posterior
   if( C(2) ) 
     Emu  = muK*wb(1:end-1); 
     J    = J+ C(2)*Emu + opts.Jconst;
   end
   if(opts.verb>0)   % debug code      
      fprintf(['%3d) %3d x=[%8f,%8f,.] J=%5f (%5f+%5f) |dJ|=%8g' lend],...
              iter,neval,wb(1),wb(2),J,Ew./muEig,Ed,r2);
   end   

   if ( J > oJ*(1+1e-3) || isnan(J) ) % check for stuckness
      if ( opts.verb>=1 ) warning('Line-search Non-reduction - aborted'); end;
      J=oJ; wb=owb; break;
   end;
   
   %------------------------------------------------
   % convergence test
   if ( iter==1 )     madJ=abs(oJ-J); dJ0=max(abs(madJ),eps); r02=r2;
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
   delta = max((Mr-oMr)'*(-dJ)/or2,0); % Polak-Ribier
   %delta = max(r2/or2,0); % Fletcher-Reeves
   d     = Mr+delta*d;     % conj grad direction
   dtdJ  =-d'*dJ;          % new search dir grad.
   if( dtdJ <= 0 )         % non-descent dir switch to steepest
      if ( opts.verb >= 2 ) fprintf('non-descent dir\n'); end;      
      d=Mr; dtdJ=-d'*dJ; 
   end; 
   
end;
if ( opts.verb >= 0 ) 
   fprintf(['%3d) %3d x=[%8f,%8f,.] J=%5f (%5f+%5f) |dJ|=%8g\n'],...
           iter,neval,wb(1),wb(2),J,Ew./muEig,Ed,r2);
end

if ( J > J0*(1+1e-4) || isnan(J) ) 
   if ( opts.verb>=0 ) warning('Non-reduction');  end;
   wb=wb0;
end;

%HACK!: do an extra bias optimisation!
% N.B. this may be necessary because b isn't pre-conditioned as well as the rest of
% the parameters
if ( opts.optBias )
   f = wb(1:end-1)'*K + ridge'.*wb(1:end-1)' + wb(end); % inc ridge for consistency
   optB=optLRbias(Y,f,[],wghtY);
   wb(end)=wb(end)+optB;
end

% fix the stabilising K normalisation
wb(1:end-1) = wb(1:end-1)./muEig;

% compute final decision values.
if ( numel(Y)~=numel(incIdx) ) % map back to the full kernel space, if needed
   nwb=zeros(size(oK,1)+1,1); nwb(incIdx)=wb(1:end-1); nwb(end)=wb(end); wb=nwb;
   K=oK; Y=oY;
end

f = wb(1:end-1)'*K + wb(end); f = reshape(f,size(Y));
p = 1./(1+exp(-f)); % Pr(y==1|x,w,b)
obj = [J Ew./muEig Ed];
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
function [b]=optLRbias(Y,dv,tol,wghtY)
% compute the optimal change in the bias from a given classifiers output
%
%  [b]=optLRbias(Y,dv)
if ( nargin < 3 || isempty(tol) ) tol=1e-8; end;
if ( nargin < 4 || isempty(wghtY) ) wghtY=Y; end;
ind=Y~=0; Y=Y(ind); dv=dv(ind); wghtY=wghtY(ind); % ignore 0 labelled points

b=0; ob=b; db=inf; Ed=inf; deltab=0; rho=.5;
for iter=1:10;
   oEd=Ed; odb=abs(db); odeltab=deltab;
   % compute the updated solution
   g     = 1./(1+exp(-Y(:).*(dv(:)+b))); g=max(g,eps); % stop log 0
   Yerr  = wghtY(:).*(1-g(:));
   Ed    = -sum(log(g(:))); % the true objective funtion value
   db    = -sum(Yerr);
   ddb   = g'*(1-g);
   deltab= db./ddb; % Newton gradient

   % convergence test
   if ( iter==1 ) db0=abs(db); Ed0=Ed; end;
   if ( Ed > oEd ) rho=rho*.5; b=ob; Ed=oEd; deltab=odeltab; else rho=min(rho*2,1); end; % re-compute the trust region
   if ( abs(db) < tol || abs(odb-abs(db))./db0 < tol ) break; end; % relative convergence test

   %fprintf('%d) b=%0.5g Ed=%0.5g rho=%g db=%0.5g ddb=%0.5g\n',iter,b,Ed,rho,db,ddb);
   
   % now do stabilised the newton step
   ob=b; b  = b - rho*deltab;  % N.B. this is buggy!
end
return;

%-----------------------------------------------------------------------------
function []=testCase()
%Make a Gaussian balls + outliers test case
[X,Y]=mkMultiClassTst([-1 0; 1 0; .2 .5],[400 400 50],[.3 .3; .3 .3; .2 .2],[],[-1 1 1]);[dim,N]=size(X);

K=X'*X; % N.B. add 1 to give implicit bias term
trnInd=true(size(K,1),1);
[alphab,f,J]=klr_cg(K,Y,0,'verb',1);

fInds=gennFold(Y,10,'perm',1); 
trnInd=fInds(:,end)<0; tstInd=fInds(:,end)>0; trnSet=find(trnInd);

[alphab,f,J]=klr_cg(K(trnInd,trnInd),Y(trnInd),1,'verb',1,'ridge',1e-7);
dv=K(tstInd,trnInd)*alphab(1:end-1)+alphab(end);
dv2conf(Y(tstInd),dv)

% test implicit ignored
[alphab0,f0,J0]=klr_cg(K,Y.*single(trnInd),1,'verb',1,'ridge',1e-7);
mad(alphab0,[alphab(trnInd);alphab(end)])



% for linear kernel
alpha=zeros(N,1);alpha(find(trnInd))=alphab(1:end-1); % equiv alpha
clf;plotLinDecisFn(X,Y,X(:,trnInd)*alphab(1:end-1),alphab(end),[],alpha);

% positive and negative example centroids
mu=X(:,trnInd)*[max(alphab(1:end-1),0) min(alphab(1:end-1),0)];
hold on; scatPlot(mu(:,1),'ro','markersize',10);scatPlot(mu(:,2),'bo','markersize',10); scatPlot(sum(mu,2),'ko','markersize',15);
dv=sum(mu,2)'*X;

% unbalanced data
wght=[1,sum(Y>0)/sum(Y<=0)];


% test with an additional linear term
[X,Y]=mkMultiClassTst([-1 0; 1 0; .2 .5],[400 400 50],[.3 .3; .3 .3; .2 .2],[],[-1 1 1]);[dim,N]=size(X);
K=X'*X; % Simple linear kernel
N=size(X,2);
mu0=randn(N,1);

[alphab,J]=priorklr_cg(K,Y,[1 1],mu0,'verb',2,'objTol0',1e-8);
[alphab,J,fk]=klr_cg(K,Y,[1 1],'mu',mu0,'verb',2,'objTol0',1e-8);
% compare with the raw version
[wb,J,fl]=lr_cg(X,Y,1,'mu',X*mu0,'verb',2,'objTol0',1e-8);
mad(fk,fl)
