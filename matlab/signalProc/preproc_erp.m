function [X,pipeline,info,opts]=preproc_erp(X,varargin)
% simple pre-processing function
% 
% [X,pipeline,info,opts]=preproc(X,...)
%
% Inputs:
%  X         - [ ch x time x epoch ] data set
% Options:  (specify as 'name',value pairs, e.g. train_ersp_clsfr(X,Y,'fs',10);
%  Y         - [ nEpoch x 1 ] set of data class labels
%  ch_names  - {str} cell array of strings which label each channel
%  ch_pos    - [3 x nCh] 3-d co-ordinates of the data electrodes
%              OR
%              {str} cell array of strings which label each channel in *1010 system*
%  capFile   - 'filename' file from which to load the channel position information.
%              *this overrides* ch_pos if given
%  overridechnms - [bool] flag if channel order from 'capFile' overrides that from the 'ch_names' option
%  fs        - sampling rate of the data
%  timeband  - [2 x 1] band of times to use for classification, all if empty ([])
%  freqband  - [2 x 1] or [3 x 1] or [4 x 1] band of frequencies to use
%              EMPTY for *NO* spectral filter
%              OR
%              { nFreq x 1 } cell array of discrete frequencies to pick
%  width_ms  - [float] width in millisecs for the windows in the welch spectrum (250)
%              estimation.  
%              N.B. the output frequency resolution = 1000/width_ms, so 4Hz with 250ms
%  spatialfilter -- [str] one of 'slap','car','none','csp','ssep'              ('slap')
%       WARNING: CSP is particularly prone to *overfitting* so treat any performance estimates with care...
%  badchrm   - [bool] do we do bad channel removal    (1)
%  badchthresh - [float] threshold in std-dev units to id channel as bad (3.5)
%  badtrrm   - [bool] do we do bad trial removal      (1)
%  badtrthresh - [float] threshold in std-dev units to id trial as bad (3)
%  detrend   - [int] do we detrend/center the data          (1)
%              0 - do nothing
%              1 - detrend the data
%              2 - center the data (i.e. subtract the mean)
%  visualize - [int] visualize the data
%               0 - don't visualize
%               1 - visualize, but don't wait
%               2 - visualize, and wait for user before continuing
%  verb      - [int] verbosity level
%  class_names - {str} names for each of the classes in Y in *increasing* order ([])
% Outputs:
%  X       -- [ppch x pptime x ppepoch] pre-processed data (N.B. may/will have different size to input X)
%  pipeline-- [struct] structure with parameters use to pre-process the data
%  info    -- [struct] structure with other information about what has been done to the data.  
%              Specificially:
%               .ch_names-- {str nCh x 1} names of each channel as from cap-file
%               .ch_pos  -  [3 x nCh] position of each channel as from capfile
%               .badch   -- [bool nCh x 1] logical indicating which channels were found bad
%               .badtr   -- [bool N x 1] logical indicating which trials were found bad
%  opts    -- [struct] the options used for in this call
[pipeline,res,X]=train_clsfr_erp(X,[],varargin{:},'classify',0);
return;
