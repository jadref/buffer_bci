% list of default arguments to always use
% N.B. Basicially this is a standard ERSP analysis setup
default_args={,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[6 8 80 90],'width_ms',250,'aveType','abs'};

% specify the analysis configuration options to pass to buffer_train_ersp_clsfr
% format cell-array of cell-arrays.  For each sub-cell array 1st element is a unique label
% for this analysis, remaining arguments are a list of options to be passed to buffer_train_ersp_clsfr as:
%   buffer_train_ersp_clsfr(data,devents,hdr,algorithms{ai}{2:end})
algorithms{1}={'wht_welch' };
algorithms{end+1}={};
