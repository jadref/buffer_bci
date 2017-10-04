function [x,s]=temporalEmbeddingFilt(x,s,alpha)
% temporal feature embedding -- using exp-filtered input features
%
%   [x,s,mu,std]=temporalEmbeddingFilt(x,s,alpha)
%
% Inputs:
%   x - [nd x nf] the data to filter
%   s - [struct] internal state of the filter
%   alpha - [nEmbed x 1] exponiential decay factor for each of the embedding rates
%           fx_i(t) = (1-alpha) x(t) + alpha fx(t)
% Outputs:
%   x - [nd x nf*nEmbed] 
%   s - [struct] updated filter state
%
% Examples:
%     [x,s]=temporalEmbeddingFilt(x,s,[1 10]); % add 10-call half-life embedding  
%     [x,s]=temporalEmbeddingFilt(x,s,[1 10 100]); % add 10 and 100-call half-life embedding

% convert to decay factor
if ( any(alpha>1) )  alpha(alpha>1)=exp(log(.5)./alpha(alpha>1)); end; 
if ( any(alpha==1))  alpha(alpha==1)=0; end; % alpha=1 is special case...
if ( isempty(s) )
  s=struct('sx',zeros([size(x),numel(alpha)],class(x)),...
           'N',zeros(numel(alpha),1),...
           'alpha',alpha);
end;

% TODO: [] vectorize this?
nx=zeros(size(s.sx));
for ai=1:numel(s.alpha);
  %weight accumulated for this alpha, for warmup
  s.N(ai)     = s.alpha(ai).*s.N(ai) + (1-s.alpha(ai)).*1;
  s.sx(:,:,ai)= s.alpha(ai).*s.sx(:,:,ai) + (1-s.alpha(ai)).*x; %weighted sum of x
  nx(:,:,ai)   = s.sx(:,:,ai)./s.N(ai); % this averge is the new feature
end
x=nx(:,:);
return;
%-----------------------------------------------------------------------------
function testCase()
X=cumsum(randn(2,1,100),3);

% simple test
s=[];fX=[];ei=1;
for ei=1:size(X,3);
  [fXei,s]=temporalEmbeddingFilt(X(:,:,ei),s,[1 10 100]);
  if(isempty(fX))fX=fXei; else fX=cat(3,fX,fXei); end;
end;
clf;image3d(fX,1,'disptype','plott','Yvals',[1 10 100]);

% clsfr test
[clsfr,res,X,Y]=buffer_train_ersp_clsfr(data,devents,hdr,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','wht','clsfrCh',{'C' 'FC' 'CP'},'freqband',{[6 8 44 46] [54 56 70 78]},'width_ms',250,'timefeat',1,'featFiltFn',{'temporalEmbeddingFilt' [1 50 100]},'objFn','mlr_cg','binsp',0,'spMx','1vR','visualize',0);
