function [X,isbadch,isbadtr]=apply_preproc(X,pipeline,verb)
% apply a previously trained preprocessing pipeline to new input data
% 
%  [X,isbadch,isbadtr]=apply_preproc(X,pipeline,verb)
%
% Inputs:
%  X - [ ch x time (x epoch) ] data set
%  pipeline - [struct] trained classifier structure as given by preproc
%  verb - [int] verbosity level
% Output:
%  X     - [n-d] the pre-processed data
%  isbadch - [bool size(X,1) x 1] indicates which channels were detected as bad and removed
%  isbadtr - [bool size(X,3) x 1] indicates which epochs were detected as bad and removed
if( nargin<3 || isempty(verb) ) verb=0; end;


%0) convert to singles (for speed)
X=single(X);

%0) bad channel removal
if ( isfield(pipeline,'isbad') && ~isempty(pipeline.isbad) )
  X=X(~pipeline.isbad,:,:,:);
end

%1) Detrend
X=detrend(X,2); % detrend over time

%2) check for bad channels
isbadch=false;
if ( isfield(pipeline,'badchthresh') && ~isempty(pipeline.badchthresh) )
  X2=sqrt(max(0,tprod(X,[1 -2 -3],[],[1 -2 -3])./size(X,2)./size(X,3)));
  isbadch = X2 > pipeline.badchthresh;
  if ( verb>=0 && any(isbadch) ) 
    fprintf('Bad channel >%5.3f:',pipeline.badchthresh); 
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

%3) Spatial filter
if ( isfield(pipeline,'spatialfilt') && ~isempty(pipeline.spatialfilt) )
  X=tprod(X,[-1 2 3 4],pipeline.spatialfilt,[1 -1]); % apply the SLAP
end

%4) spectral filter
if ( isfield(pipeline,'filt') && ~isempty(pipeline.filt) )
  X=fftfilter(X,pipeline.filt,pipeline.outsz,2,1);
elseif ( pipeline.outsz(2)~=size(X,2) ) % downsample only
  X=subsample(X,pipeline.outsz(2));
end

%4.2) time range selection
if ( ~isempty(pipeline.timeIdx) ) 
  X    = X(:,pipeline.timeIdx,:);
end

%4.5) check for bad trials
isbadtr=false;
if ( isfield(pipeline,'badtrthresh') && ~isempty(pipeline.badtrthresh) )
  X2 = sqrt(max(0,tprod(X,[-1 -2 1],[],[-1 -2 1])./size(X,1)./size(X,2)));
  isbadtr = X2 > pipeline.badtrthresh;
  if ( verb>=0 && any(isbadtr) ) 
    fprintf('Bad tr >%5.3f:',pipeline.badtrthresh); 
    for i=1:numel(X2); 
      fprintf('%5.3f',X2(i)); if(isbadtr(i))fprintf('*');else fprintf(' '); end; fprintf(' ');  
    end
    fprintf('\n'); 
  end;
end
return;
