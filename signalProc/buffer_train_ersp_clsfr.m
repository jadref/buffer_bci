function [clsfr,res,X,Y]=buffer_train_ersp_clsfr(X,Y,hdr,varargin);
% train ERSP (frequency-domain) classifier with ft-buffer based data/events input
%
%   [clsfr,res,X,Y]=buffer_train_ersp_clsfr(X,Y,hdr,varargin);
%
% Inputs:
%  X -- [ch x time x epoch] data
%       OR
%       [struct epoch x 1] where the struct contains a buf field of buffer data
%       OR
%       {[float ch x time] epoch x 1} cell array of data
%  Y -- [epoch x 1] set of labels for the data epochs
%       OR
%       [struct epoch x 1] set of buf event structures which contain epoch labels in value field
%  hdr-- [struct] buffer header structure
% Options:
%  capFile -- [str] name of file which contains the electrode position info  ('1010')
%  overridechnms -- [bool] does capfile override names from the header    (false)
%  varargin -- all other options are passed as option arguments to train_ersp_clsfr, e.g.
%              freqband,timeband,spatialfilter,badchrm,badtrrm,detrend,etc..
% Outputs:
%  clsfr   -- [struct] a classifer structure
%  res     -- [struct] a results structure
%  X       -- [ppch x pptime x ppepoch] pre-processed data (N.B. may/will have different size to input X)
%  Y       -- [ppepoch x 1] pre-processed labels (N.B. will have diff num examples to input!)
%
% See Also: train_ersp_clsfr
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
if ( isstruct(Y) ) % convert event struct into labels
  if ( isnumeric(Y(1).value) ) Y=cat(1,Y.value); 
  elseif(isstr(Y(1).value) )   Y=cat(1,{Y.value});
  else error('Dont know how to handle Y value type');
  end
end; 

fs=[];
if ( isstruct(hdr) )
  if ( isfield(hdr,'channel_names') ) chNames=hdr.channel_names; 
  elseif( isfield(hdr,'label') )      chNames=hdr.label;
  else 
    warning('Couldnt find channel names in header');
    chNames={}; for di=1:size(X,1); chNames{di}=sprintf('%d',di); end;
  end;
  if ( isfield(hdr,'fsample') )       fs=hdr.fsample; 
  elseif ( isfield(hdr,'Fs') )        fs=hdr.Fs;
  elseif( isfield(hdr,'SampleRate') ) fs=hdr.SampleRate; 
  else warning('Couldnt find sample rate in header, using 100'); fs=100;
  end;
elseif ( iscell(hdr) && isstr(hdr{1}) )
  chNames=hdr;
end

% get position info and identify the eeg channels
di = addPosInfo(chNames,opts.capFile,opts.overridechnms); % get 3d-coords
ch_pos=cat(2,di.extra.pos3d); ch_names=di.vals; % extract pos and channels names
iseeg=[di.extra.iseeg];

% call the actual function which does the classifier training
[clsfr,res,X,Y]=train_ersp_clsfr(X,Y,'ch_names',ch_names,'ch_pos',ch_pos,'fs',fs,'badCh',~iseeg,varargin{:});
return;
