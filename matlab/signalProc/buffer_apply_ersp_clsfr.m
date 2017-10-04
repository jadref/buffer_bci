function [clsfr,f,fraw,p,X]=buffer_apply_ersp_clsfr(X,clsfr,verb)
% apply a previously trained classifier to the input data
% 
%  [clsfr,f,fraw,p,X]=buffer_apply_erp_clsfr(X,clsfr,varargin)
%
% Inputs:
%   X -- [ch x time x epoch] data
%        OR
%        [struct epoch x 1] where the struct contains a buf field of buffer data
%        OR
%        {[float ch x time] epoch x 1} cell array of data
%  clsfr - [struct] classifier structure
%  verb  - [int] verbosity level (0)
% Output:
%  clsfr - [struct] updated classifier after application to this data
%  f    - [size(X,epoch) x nCls] the classifier's raw decision value
%  fraw - [size(X,dim) x nSp] set of pre-binary sub-problem decision values
%  p     - [size(X,epoch) x nCls] the classifier's assessment of the probablility of each class
%  X     - [n-d] the pre-processed data
if( nargin<3 || isempty(verb))  verb=0; end;
% extract the data - from field begining with trainingData
if ( iscell(X) ) 
  if ( isnumeric(X{1}) ) 
    X=cat(3,X{:});
  else
    error('Unrecognised data format!');
  end
elseif ( isstruct(X) )
  X=cat(3,X.buf);
end 
[clsfr, f, fraw, p, X]=apply_ersp_clsfr(X,clsfr,verb);
if ( verb>0 ) fprintf('Classifier prediction:  %g %g\n', f,p); end;
return;
%------------------
function testCase();
X=oz.X;
fs=256; oz.di(2).info.fs;
width_samp=fs*250/1000;
wX=windowData(X,1:width_samp/2:size(X,2)-width_samp,width_samp,2); % cut into overlapping 250ms windows

% non-adaptive classifier train -- so apply should be identical
[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','wht','clsfrCh',{'C' 'FC' 'CP'},'freqband',{[6 8 44 46] [54 56 70 78]},'width_ms',250,'timefeat',1,'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);
% adaptive classifier
[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','adaptspatialfiltFn',{'filtPipeline' {'rmEMGFilt','covFilt',500} {'artChRegress',[],{'AF7' 'Fp1' 'Fpz' 'Fp2' 'AF8'},'covFilt',500} {'adaptWhitenFilt','covFilt',50}},'clsfrCh',{'C' 'FC' 'CP'},'freqband',{[6 8 44 46] [54 56 70 78]},'width_ms',250,'timefeat',1,'featFiltFn',{'stdFilt' 50},'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);

[ans,of,ofraw,op,oX] = buffer_apply_ersp_clsfr(data,clsfr);

mad(X,oX), if(ans==0) fprintf('Pre-processing OK\n'); end;
ct=conf2loss(dv2conf(res.Y,res.opt.f)),ctst=conf2loss(dv2conf(res.Y,of(:,1))), if ( ct==ctst ) fprintf('cr OK\n'); else fprintf('cr FAILED\n'); end;
mad(res.opt.f,of(:,1)), if(ans==0) fprintf('Clsfr dv OK\n'); else fprintf('Clsfr dv FAILED\n'); end;
mad(dv2conf(res.Y,res.opt.f),dv2conf(res.Y,of(:,1))), if ( ans==0 ) fprintf('Confusion matrix OK\n'); else fprintf('Confusion matrix FAILED\n'); end;
mad(res.opt.f,ofraw(:,1)), if(ans==0) fprintf('Clsfr OK\n'); else fprintf('Clsfr FAILED\n'); end;
corrcoef(double(res.opt.f),double(of(:,1)))

% incremental apply
incclsfr=clsfr;
incf=[];
for ei=1:numel(data);
   [incclsfr,fei] = buffer_apply_ersp_clsfr(data(ei),incclsfr);
   if(isempty(incf))incf=fei(:)';incf=repmat(incf,numel(data),1);
   else incf(ei,:)=fei(:)';
   end;
   textprogressbar(ei,numel(data));
end
mad(of,incf), if( ans<1e-3 ) fprintf('Inc OK\n'); else fprintf('Inc FAILED\n'); end;