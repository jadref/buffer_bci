function [f,fraw,p,X,clsfr]=apply_ersp_clsfr(X,clsfr,verb)
% apply a previously trained classifier to the input data
% 
%  [f,fraw,p,X,clsfr]=apply_ersp_clsfr(X,clsfr,verb) 
%
% Inputs:
%  X - [ ch x time x epoch ] data set
%  clsfr - [struct] trained classifier structure as given by train_ersp_clsfr
%  verb - [int] verbosity level
% Output:
%  f    - [size(X,epoch) x nCls] the classifier's raw decision value
%  fraw - [size(X,dim) x nSp] set of pre-binary sub-problem decision values
%  p    - [size(X,dim) x nSp] the classifiers predictions as probabilities
%  X    - [n-d] the pre-processed data
%  clsfr- [struct] input classifier updated w.r.t. any adaptive changes over time
if( nargin<3 || isempty(verb) ) verb=0; end;

if( isfield(clsfr,'type') && ~strcmpi(clsfr.type,'ersp') )
  warning(sprintf('Wrong type of classifier given, expected ERSP got : %s',clsfr.type));
end
if ( isa(X,'single') ) eps=1e-6; else eps=1e-10; end;

%0) convert to singles (for speed)
X=single(X);

%0) bad channel removal
if ( isfield(clsfr,'isbad') && ~isempty(clsfr.isbad) )
  X=X(~clsfr.isbad,:,:,:);
end

%1) Detrend
if ( isfield(clsfr,'detrend') && isequal(clsfr.detrend,1) )
  X=detrend(X,2); % detrend over time
end

%2) check for new bad channels
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

%4.2) time range selection
if ( ~isempty(clsfr.timeIdx) ) 
  X    = X(:,clsfr.timeIdx,:);
end

%3) Spatial filter
if ( isfield(clsfr,'spatialfilt') && ~isempty(clsfr.spatialfilt) )
  X=tprod(X,[-1 2 3 4],clsfr.spatialfilt,[1 -1]); % apply the SLAP
end

%3.5) adaptive spatial filter
if ( isfield(clsfr,'adaptspatialfilt') && ...
	  ~isempty(clsfr.adaptspatialfilt) && ~isequal(clsfr.adaptspatialfilt,0) )
  if ( size(X,3)>1 ) warning('Adaptive filtering only when called with single trials.'); end
  % single number = memory for adapt whitener
  if ( isnumeric(clsfr.adaptspatialfilt) )
	 % compute average spatial covariance for this trial
	 chCov = tprod(X,[1 -2 -3],[],[2 -2 -3])./size(X,2)./size(X,3); 
	 % update the running average
	 if( ~isfield(clsfr,'chCov') ) % initialize
		clsfr.chCov=chCov;
	 else % update
	   % between 0 and 1 is an exp weighting factor
		% N.B. alpha = exp(log(.5)./(half-life))
		if ( clsfr.adaptspatialfilt>0 && clsfr.adaptspatialfilt<1 ) % exp-weighted moving average
		  chCov = clsfr.adaptspatialfilt*chCov + (1-clsfr.adaptspatialfilt)*chCov;
		  clsfr.chCov = chCov;
		else % integers 1 or larger => ring buffer
		  if ( abs(clsfr.adaptspatialfilt)==1 ) % just use current entry
			 clsfr.chCov=chCov;
		  elseif ( abs(clsfr.adaptspatialfilt)==2 ) % this and previous
			 tmp  = ( clsfr.chCov + chCov) /2;
			 clsfr.chCov = chCov; % record current info for next time
			 chCov= tmp; % use average of now and previous
		  else
			 error('Ring buffer for cov-estimation not supported yet!');
		  end
		end
	 end
	 % compute the whitener from the local adapative covariance estimate
	 [U,s]=eig(double(chCov)); s=diag(s); % N.B. force double to ensure precision with poor condition
	 % select non-zero entries - cope with rank deficiency, numerical issues
	 si = s>eps & ~isnan(s) & ~isinf(s) & abs(imag(s))<eps;
	 fprintf('%g ',s(si));fprintf('\n');
	 W  = U(:,si)*diag(1./s(si))*U(:,si)'; % compute symetric whitener	 
	 X  = tprod(X,[-1 2 3 4],W,[-1 1]); % apply it to the data
  end
end

%3.75) check for bad trials
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

%3) convert to spectral
if ( size(X,2)>numel(clsfr.windowFn) )
  X=welchpsd(X,2,'windowType',clsfr.windowFn(:),'aveType',clsfr.welchAveType,'detrend',1);
else
  %3.1) temporal window
  X=repop(X,'*',clsfr.windowFn(:)');
  %3.2) fft
  X=fft(X,[],2);
  %3.2.5 positive frequencies only
  X=X(:,1:ceil((size(X,2)-1)/2)+1,:);
  %3.3) convert to powers
  X=2*(real(X).^2 + imag(X).^2); 
  %3.4) convert to output type
  switch ( lower(clsfr.welchAveType) )
   case 'db';
    X=10*log10(X)./sum(clsfr.windowFn); % map to db (and normalise)
   case 'power'; % do nothing
   case {'amp','abs'}; X=sqrt(abs(X)); % map to amplitudes
   otherwise; error('Unrecognised welch averaging type');
  end
  X=X./sum(clsfr.windowFn(:));
end

%4) sub-select the range of frequencies we care about
if ( isfield(clsfr,'freqIdx') && ~isempty(clsfr.freqIdx) )
  X=X(:,clsfr.freqIdx,:); % sub-set to the interesting frequency range
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
p = 1./(1+exp(-f)); 

return;
%------------------
function testCase();
X=oz.X;
fs=256; oz.di(2).info.fs;
width_samp=fs*250/1000;
wX=windowData(X,1:width_samp/2:size(X,2)-width_samp,width_samp,2); % cut into overlapping 250ms windows
[ans,f2]=apply_ersp_clsfr(wX,fs,clsfr);
f2=reshape(f2,[size(wX,3) size(wX,4) size(f2,2)]);

% test adaptive whitening
X=cumsum(randn(4,100,1000),2); % simulate 4-ch (muse) data
% insert a non-stationarity
X(2,:,10:50)=X(2,:,10:50)*10;

% get a 'classifier' for this type of data
clsfr = train_ersp_feedback_clsfr(X,[],'nfParams',struct('label','alpha','freqband',[8 12],'electrodes',{{'FP1' 'FP2'}}),'fs',100,'capFile','muse','overridechnms',1);
oclsfr=clsfr;

% apply it to the data in an adaptive fashion
clsfr=oclsfr;
clsfr.adaptspatialfilt=exp(log(1/2)/10); % alpha = exp(log(.5)./(half-life))
ei=1;
fprintf('apply:');
f=[];fa=[];
for ei=1:size(X,3);
  f(ei) = apply_ersp_clsfr(X(:,:,ei),oclsfr);
  [fa(ei),ans,ans,ans,clsfr]=apply_ersp_clsfr(X(:,:,ei),clsfr);
  textprogressbar(ei,size(X,3));
end
clf;plot([f;fa]','linewidth',2);legend('f','fa')
