if( ~exist('fs','var') || isempty(fs) ) fs         = 250; end;
trlen_ms   = 750;
ms2samp    = @(x) x*fs/1000;
s2samp     = @(x) x*fs;
calls2samp = @(x) x*fs*1000/trlen_ms;
s2calls    = @(x) x*1000./trlen_ms;

% specify the analysis configuration options to pass to buffer_train_ersp_clsfr
% format cell-array of cell-arrays.  For each sub-cell array 1st element is a unique label
% for this analysis, remaining arguments are a list of options to be passed to buffer_train_ersp_clsfr as:
%   buffer_train_ersp_clsfr(data,devents,hdr,algorithms{ai}{2:end})
algorithms={};
algorithms{1}={'wht_welch' 'spatialfilter','wht'};
% example of how to add a new algorithm
%algorithms{end+1}={};

algorithms{end+1}={'adaptwht60s' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(60)}};
algorithms{end+1}={'adaptwht600s' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(600)}};
algorithms{end+1}={'adaptwht15s_stdfilt15' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(15)},'featFiltFn',{'stdFilt' s2calls(15)}};
algorithms{end+1}={'adaptwht30s_stdfilt30' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(30)},'featFiltFn',{'stdFilt' s2calls(30)}};
algorithms{end+1}={'adaptwht60s_stdfilt60' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(60)},'featFiltFn',{'stdFilt' s2calls(60)}};
algorithms{end+1}={'adaptwht600s_stdfilt600' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(600)},'featFiltFn',{'stdFilt' s2calls(600)}};
algorithms{end+1}={'adaptwht60s_biasfilt60' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(60)},'featFiltFn',{'biasFilt' s2calls(60)}};
algorithms{end+1}={'wht_stdfilt60' 'spatialfilter','wht','featFiltFn',{'stdFilt' s2calls(600)}};
