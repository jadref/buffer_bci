function [clsfr,res]=buffer_train_ersp_clsfr(X,Y,hdr,varargin);
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

fs=[];
if ( isstruct(hdr) )
  if ( isfield(hdr,'channel_names') ) chNames=hdr.channel_names; end;
  if ( isfield(hdr,'fsample') ) fs=hdr.fsample; end;
elseif ( iscell(hdr) && isstr(hdr{1}) )
  chNames=hdr;
end

% get position info and identify the eeg channels
di = addPosInfo(chNames,opts.capFile,opts.overridechnms); % get 3d-coords
ch_pos=cat(2,di.extra.pos3d); ch_names=di.vals; % extract pos and channels names
iseeg=[di.extra.iseeg];

% call the actual function which does the classifier training
[clsfr,res]=train_ersp_clsfr(X,Y,'ch_names',ch_names,'ch_pos',ch_pos,'fs',fs,'badCh',~iseeg,varargin{:});
return;
