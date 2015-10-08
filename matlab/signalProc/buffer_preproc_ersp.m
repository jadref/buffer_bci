function [X,pipeline]=buffer_preproc_ersp(X,hdr,varargin);
% train ERP (time-domain) classifier with ft-buffer based data/events input
%
%   [X,pipeline]=buffer_preproc_ersp(X,hdr,varargin);
%
% Inputs:
%  X -- [ch x time x epoch] data
%       OR
%       [struct epoch x 1] where the struct contains a buf field of buffer data
%       OR
%       {[float ch x time] epoch x 1} cell array of data
%  hdr-- [struct] buffer header structure
% Options:
%  capFile -- [str] name of file which contains the electrode position info  ('1010')
%  overridechnms -- [bool] does capfile override names from the header    (false)
%  varargin -- all other options are passed as option arguments to train_ersp_clsfr
% Outputs:
%  X       -- [ppch x pptime x ppepoch] pre-processed data (N.B. may/will have different size to input X)
%  pipeline-- [struct] structure with parameters use to pre-process the data
% See Also: preproc_ersp, buffer_preproc_erp
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

fs=[]; chNames=[];
if ( isstruct(hdr) )
  if ( isfield(hdr,'channel_names') ) chNames=hdr.channel_names; 
  elseif( isfield(hdr,'label') )      chNames=hdr.label;
  end;
  if ( isfield(hdr,'fsample') )       fs=hdr.fsample; 
  elseif ( isfield(hdr,'Fs') )        fs=hdr.Fs;
  elseif( isfield(hdr,'SampleRate') ) fs=hdr.SampleRate; 
  else warning('Couldnt find sample rate in header, using 100'); fs=100;
  end;
elseif ( iscell(hdr) && ischar(hdr{1}) )
  chNames=hdr;
end
if ( isempty(chNames) ) 
  warning('No channel names set');
  chNames={}; for di=1:size(X,1); chNames{di}=sprintf('%d',di); end;
end

% get position info and identify the eeg channels
di = addPosInfo(chNames,opts.capFile,opts.overridechnms); % get 3d-coords
iseeg=false(size(X,1),1); iseeg([di.extra.iseeg])=true;
if ( any(iseeg) ) 
  ch_pos=cat(2,di.extra.pos3d); ch_names=di.vals; % extract pos and channels names    
else % fall back on showing all data
  warning('Capfile didnt match any data channels -- no EEG?');
  ch_pos=[]; ch_names=di.vals; iseeg(:)=true;
end

% call the actual function which does the classifier training
[X,pipeline]=preproc_ersp(X,'ch_names',ch_names,'ch_pos',ch_pos,'fs',fs,'badCh',~iseeg,varargin{:});
return;
%---------
function testcase();
