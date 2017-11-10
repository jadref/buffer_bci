function [f,fraw,p,X,isbadch,isbadtr]=apply_erp_clsfr(X,clsfr,verb)
% apply a previously trained classifier to the input data
% 
%  [f,fraw,p,X]=apply_erp_clsfr(X,clsfr,verb)
%
% Inputs:
%  X - [ ch x time (x epoch) ] data set
%  clsfr - [struct] trained classifier structure as given by train_1bitswitch
%  verb - [int] verbosity level
% Output:
%  f     - [size(X,epoch) x nCls] the classifier's raw decision value
%  fraw  - [size(X,dim) x nSp] set of pre-binary sub-problem decision values
%  p     - [size(X,epoch) x nCls] the classifier's assessment of the probablility of each class
%  X     - [n-d] the pre-processed data
if( nargin<3 || isempty(verb) ) verb=0; end;

if( isfield(clsfr,'type') && ~strcmpi(clsfr.type,'erp') )
  warning(sprintf('Wrong type of classifier given, expected ERP got : %s',clsfr.type));
end


%0) convert to singles (for speed)
X=single(X);

%0) bad channel removal
if ( isfield(clsfr,'isbad') && (~isempty(clsfr.isbad) && sum(clsfr.isbad)>0) )
  X=X(~clsfr.isbad,:,:,:);
end

%1) Detrend
if ( isfield(clsfr,'detrend') && clsfr.detrend ) % detrend over time
  if ( isequal(clsfr.detrend,1) )
    X=detrend(X,2); % detrend over time
  elseif ( isequal(clsfr.detrend,2) )
    X=repop(X,'-',mean(X,2));
  end
end 

%2) check for bad channels
isbadch=false;
if ( isfield(clsfr,'badchthresh') && ~isempty(clsfr.badchthresh) )
  X2=sqrt(max(0,tprod(X,[1 -2 -3],[],[1 -2 -3])./size(X,2)./size(X,3)));
  isbadch = X2 > clsfr.badchthresh;
  if ( verb>=0 && any(isbadch) ) 
    fprintf('Bad channel >%5.3f:',clsfr.badchthresh); 
    for i=1:numel(X2); 
      fprintf('%5.3f',X2(i)); if(isbadch(i))fprintf('*');else fprintf(' '); end; fprintf(' ');  
    end
    fprintf('\n');
  end;
  % replace this channel with the CAR of the rest... so spat-filt should
  % still work
  if ( any(isbadch) )
    car = mean(X,1); for badchi=find(isbadch)'; X(badchi,:,:)=car;end
  end
end

%3) fixed spatial filter
if ( isfield(clsfr,'spatialfilt') && ~isempty(clsfr.spatialfilt) )
  X=tprod(X,[-1 2 3 4],clsfr.spatialfilt,[1 -1]); % apply the SLAP
end

%3.5) adaptive spatial filter
if ( isfield(clsfr,'adaptspatialfiltFn') && ~isempty(clsfr.adaptspatialfiltFn) )
   if( ~iscell(clsfr.adaptspatialfiltFn) ) clsfr.adaptspatialfiltFn={clsfr.adaptspatialfiltFn}; end;
   [X,clsfr.adaptspatialfiltstate] = feval(clsfr.adaptspatialfiltFn{1},X,clsfr.adaptspatialfiltstate,clsfr.adaptspatialfiltFn{2:end});
end

%4) spectral filter
if ( isfield(clsfr,'filt') && ~isempty(clsfr.filt) )
  X=fftfilter(X,clsfr.filt,clsfr.outsz,2,2);
elseif ( clsfr.outsz(2)~=size(X,2) ) % downsample only
  X=subsample(X,clsfr.outsz(2));
end

%4.2) time range selection
if ( ~isempty(clsfr.timeIdx) ) 
  X    = X(:,clsfr.timeIdx,:);
end

%4.5) check for bad trials
isbadtr=false;
if ( isfield(clsfr,'badtrthresh') && ~isempty(clsfr.badtrthresh) )
  X2 = sqrt(max(0,tprod(X,[-1 -2 1],[],[-1 -2 1])./size(X,1)./size(X,2)));
  isbadtr = X2 > clsfr.badtrthresh;
  if ( verb>=0 && any(isbadtr) ) 
    fprintf('Bad tr >%5.3f:',clsfr.badtrthresh); 
    for i=1:numel(X2); 
      fprintf('%5.3f',X2(i)); if(isbadtr(i))fprintf('*');else fprintf(' '); end; fprintf(' ');  
    end
    fprintf('\n'); 
  end;
end

%5) feature post-processing filter
if ( isfield(clsfr,'featFiltFn') && ~isempty(clsfr.featFiltFn) )
  if( ~iscell(clsfr.featFiltFn) ) clsfr.featFiltFn={clsfr.featFiltFn}; end;
  for ei=1:size(X,3); % incrementall call the function
	 [X(:,:,ei),clsfr.featFiltState]=feval(clsfr.featFilt{1},X(:,:,ei),clsfr.featFiltState,clsfr.featFilt{2:end});
  end  
end

%6) apply classifier
[f, fraw]=applyLinearClassifier(X,clsfr);

%6.5) correct classifier output for bad trials..
if ( any(isbadtr) )
  %if ( isfield(clsfr,'dvstats') )
  %  f(isbadtr) = mean(clsfr.dvstats.mu(1:2)); % mean dv?
  %else    
    f(isbadtr) = 0;
  %end
end

% Pr(y==1|x,w,b), map to probability of the positive class
if ( clsfr.binsp ) 
   p = 1./(1+exp(-f)); 
else % direct multi-class softmax
   p = exp(f-max(f,2)); p=repop(p,'./',sum(p,2));
end
if ( verb>1 ) fprintf('Classifier prediction:  %g %g\n', f,p); end;

return;
%------------------
function testCase();
X=oz.X;
fs=256; oz.di(2).info.fs;
width_samp=fs*250/1000;
wX=windowData(X,1:width_samp/2:size(X,2)-width_samp,width_samp,2); % cut into overlapping 250ms windows
[ans,f2]=apply_erp_clsfr(wX,fs,clsfr);
f2=reshape(f2,[size(wX,3) size(wX,4) size(f2,2)]);
