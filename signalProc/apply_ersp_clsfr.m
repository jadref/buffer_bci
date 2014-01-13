function [f,fraw,p,X]=apply_ersp_clsfr(X,clsfr,verb)
% apply a previously trained classifier to the input data
% 
%  [f,fraw,p]=apply_ersp_clsfr(X,clsfr,verb) 
%
% Inputs:
%  X - [ ch x time x epoch ] data set
%  clsfr - [struct] trained classifier structure as given by train_1bitswitch
%  verb - [int] verbosity level
% Output:
%  f    - [size(X,epoch) x nCls] the classifier's raw decision value
%  fraw - [size(X,dim) x nSp] set of pre-binary sub-problem decision values
%  p    - [size(X,dim) x nSp] the classifiers predictions as probabilities
%  X    - [n-d] the pre-processed data
if( nargin<3 || isempty(verb) ) verb=0; end;

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

%3.5) check for bad trials
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
  %3.3) convert to powers
  X=2*(real(X).^2 + imag(X).^2); 
  %3.4) convert to output type
  switch ( lower(clsfr.welchAveType) )
   case 'db';
    X=10*log10(X)./sum(clsfr.windowFn); % map to db (and normalise)
   case 'power'; % do nothing
   otherwise; X=sqrt(abs(X)); % map to amplitudes
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