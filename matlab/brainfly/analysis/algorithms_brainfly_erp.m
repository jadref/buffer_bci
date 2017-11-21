% specify the analysis configuration options to pass to buffer_train_ersp_clsfr
% format cell-array of cell-arrays.  For each sub-cell array 1st element is a unique label
% for this analysis, remaining arguments are a list of options to be passed to buffer_train_ersp_clsfr as:
%   buffer_train_ersp_clsfr(data,devents,hdr,algorithms{ai}{2:end})
algorithms={};
algorithms{1}={'wht' 'detrend',1,'spatialfilter','wht'};
% example of how to add a new algorithm
%algorithms{end+1}={};
