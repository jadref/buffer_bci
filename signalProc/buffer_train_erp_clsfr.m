function [clsfr,res,X]=buffer_train_erp_clsfr(X,Y,hdr,varargin);
% train classifier with ft-buffer based data/events input
% 
opts=struct('capFile','1010','overridechnms',0);
[opts,varargin]=parseOpts(opts,varargin);
if ( nargin<3 ) error('Insufficient arguments'); end;
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
X=single(X);
if ( isstruct(Y) ) Y=cat(1,Y.value); end; % convert event struct into labels

fs=[]; chNames=[];
if ( isstruct(hdr) )
  if ( isfield(hdr,'channel_names') ) chNames=hdr.channel_names; end;
  if ( isfield(hdr,'fsample') ) fs=hdr.fsample; end;
elseif ( iscell(hdr) && isstr(hdr{1}) )
  chNames=hdr;
end

% get position info and identify the eeg channels
di = addPosInfo(chNames,opts.capFile,opts.overridechnms); % get 3d-coords
ch_pos=cat(2,di.extra.pos3d); ch_names=di.vals; % extract pos and channels names
iseeg=false(size(X,1),1); iseeg([di.extra.iseeg])=true;

% call the actual function which does the classifier training
[clsfr,res,X]=train_erp_clsfr(X,Y,'ch_names',ch_names,'ch_pos',ch_pos,'fs',fs,'badCh',~iseeg,varargin{:});
return;
%---------
function testcase();
% buffer stuff
capFile='cap_tmsi_mobita_num';
clsfr=buffer_train_erp_clsfr(traindata,traindevents,hdr,'spatialfilter','car','freqband',[.1 .3 8 10],'objFn','lr_cg','compKernel',0,'dim',3,'capFile',capFile,'overridechnms',1);
X=cat(3,traindata.buf);
apply_erp_clsfr(X,clsfr)
