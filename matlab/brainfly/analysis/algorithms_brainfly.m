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

%% algorithms{end+1}={'adaptwht3s_stdfilt3' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(3)},'featFiltFn',{'stdFilt' s2calls(3)}};
%algorithms{end+1}={'adaptwht3s_predbiasfilt3' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(3)},'predFiltFn',{'robustBiasFilt' s2calls(3)}};

algorithms{end+1}={'adaptwht7s' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(7)}};
%algorithms{end+1}={'adaptwht7s_stdfilt7' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(7)},'featFiltFn',{'stdFilt' s2calls(7)}};
%algorithms{end+1}={'adaptwht7s_biasfilt7' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(7)},'featFiltFn',{'robustBiasFilt' s2calls(7)}};
algorithms{end+1}={'adaptwht7s_predbiasfilt7' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(7)},'predFiltFn',{'robustBiasFilt' s2calls(7)}};
%algorithms{end+1}={'adaptwht7s_predbiasfilt30' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(7)},'predFiltFn',{'robustBiasFilt' s2calls(30)}};
%algorithms{end+1}={'adaptwht30s_predbiasfilt7' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(30)},'predFiltFn',{'robustBiasFilt' s2calls(7)}};

%algorithms{end+1}={'adaptwht7s_predprecfilt30' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(7)},'predFiltFn',{'percentialFilt' s2calls(30)}};
%algorithms{end+1}={'adaptwht7s_predprecfilt15' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(7)},'predFiltFn',{'percentialFilt' s2calls(15)}};


%algorithms{end+1}={'adaptwht15s_stdfilt15' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(15)},'featFiltFn',{'stdFilt' s2calls(15)}};
%algorithms{end+1}={'adaptwht15s_predbiasfilt15' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(15)},'predFiltFn',{'robustBiasFilt' s2calls(15)}};

%% algorithms{end+1}={'adaptwht30s_stdfilt30' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(30)},'featFiltFn',{'stdFilt' s2calls(30)}};
%algorithms{end+1}={'adaptwht30s_predbiasfilt30' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(30)},'predFiltFn',{'robustBiasFilt' s2calls(30)}};

%% algorithms{end+1}={'adaptwht60s' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(60)}};
%% algorithms{end+1}={'adaptwht60s_stdfilt60' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(60)},'featFiltFn',{'stdFilt' s2calls(60)}};
%% algorithms{end+1}={'adaptwht600s_stdfilt600' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(600)},'featFiltFn',{'stdFilt' s2calls(600)}};
%% algorithms{end+1}={'adaptwht60s_biasfilt60' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(60)},'featFiltFn',{'robustBiasFilt' s2calls(60)}};
%% algorithms{end+1}={'adaptwht60s_predbiasfilt30' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(60)},'predFiltFn',{'robustBiasFilt' s2calls(30)}};
%algorithms{end+1}={'adaptwht60s_predbiasfilt60' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(60)},'predFiltFn',{'robustBiasFilt' s2calls(60)}};
%% algorithms{end+1}={'adaptwht60s_predbiasfilt15' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(60)},'featFiltFn',{'robustBiasFilt' s2calls(15)}};

%% algorithms{end+1}={'adaptwht600s' 'spatialfilter','none','adaptspatialfiltFn',{'adaptWhitenFilt','covFilt',s2samp(600)}};

%algorithms{end+1}={'wht_biasfilt7' 'spatialfilter','wht','featFiltFn',{'robustBiasFilt' s2calls(60)}};

%% algorithms{end+1}={'wht_stdfilt60' 'spatialfilter','wht','featFiltFn',{'stdFilt' s2calls(60)}};
%algorithms{end+1}={'wht_stdfilt15' 'spatialfilter','wht','featFiltFn',{'stdFilt' s2calls(15)}};

%algorithms{end+1}={'wht_stdfilt15_predbiasfilt7' 'spatialfilter','wht','featFiltFn',{'stdFilt' s2calls(15)},'predFiltFn',{'robustBiasFilt' s2calls(7)}};

%% algorithms{end+1}={'wht_stdfilt300_predbiasfilt60' 'spatialfilter','wht','featFiltFn',{'stdFilt' s2calls(300)},'predFiltFn',{'robustBiasFilt' s2calls(60)}};
%% algorithms{end+1}={'wht_stdfilt30_predbiasfilt30' 'spatialfilter','wht','featFiltFn',{'stdFilt' s2calls(30)},'predFiltFn',{'robustBiasFilt' s2calls(30)}};

%algorithms{end+1}={'wht_medwelch_predbiasfilt7s' 'spatialfilter','wht','aveType','medianabs','predFiltFn',{'robustBiasFilt' s2calls(7)}};

algorithms{end+1}={'wht_predbiasfilt7s' 'spatialfilter','wht','predFiltFn',{'robustBiasFilt' s2calls(7)}};
%algorithms{end+1}={'wht_predbiasfilt15s' 'spatialfilter','wht','predFiltFn',{'robustBiasFilt' s2calls(15)}};
%algorithms{end+1}={'wht_predbiasfilt30s' 'spatialfilter','wht','predFiltFn',{'robustBiasFilt' s2calls(30)}};
%% algorithms{end+1}={'wht_predbiasfilt60' 'spatialfilter','wht','predFiltFn',{'robustBiasFilt' s2calls(60)}};


%algorithms{end+1}={'wht_predpercilt7s' 'spatialfilter','wht','predFiltFn',{'percentialFilt' s2calls(7)}};
%algorithms{end+1}={'wht_predpercfilt15s' 'spatialfilter','wht','predFiltFn',{'percentialFilt' s2calls(15)}};
%algorithms{end+1}={'wht_predpercfilt30s' 'spatialfilter','wht','predFiltFn',{'percentialFilt' s2calls(30)}};
%% algorithms{end+1}={'wht_predbiasfilt60' 'spatialfilter','wht','predFiltFn',{'percentialFilt' s2calls(60)}};
