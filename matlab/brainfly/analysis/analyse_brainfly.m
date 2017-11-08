run ../../utilities/initPaths
datasets_brainfly();
dataRootDir = '~/data/bci'; % main directory the data is saved relative to in sub-dirs
trlen_ms=750;
label   ='movement'; % generic label for this slice/analysis type
makePlots=1; % flag if we should make summary ERP/AUC plots whilst slicing

% get the set of algorithms to run
algorithms_brainfly();
% list of default arguments to always use
% N.B. Basicially this is a standard ERSP analysis setup
default_args={,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[6 8 80 90],'width_ms',250,'aveType','abs'};

% summary results storage.  Format is 2-d cell array.  Each row is an algorithm run with 4 columns: {subj session algorithm_label performance}
try % load the previously saved results if possible..
  res=load(fullfile(dataRootDir,expt,sprintf('analyse_res')));
catch
  res={};
end

% run the given analysis
si=1; sessi=3;
for si=1:numel(datasets);
  subj   =datasets{si}{1};
  session=datasets{si}{1+sessi};
  saveDir=session;
  if(~isempty(stripFrom))
    tmp=strfind(stripFrom,session);
    if ( ~isempty(tmp) ) saveDir=session(1:tmp);  end
  end
                                % load the sliced data
  dname = fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_sliced',subj,label));
  if( ~exist(dname,'file') )
    warning('Couldnt find sliced data for : %s.  skipping',dname);
    continue;
  end
  load(dname);

  % run the set of algorithms to test
  for ai=1:numel(algorithms)
    [clsfr{ai},res{ai}]=buffer_train_ersp_clsfr(data,devents,hdr,default_args{:},algorithms{ai}{2:end},'visualize',0);
                                % save the summary results
    res{end+1}={subj session algorithms{ai}{1} res{ai}.opt.tst};
    fprintf('%d) %s %s %s = %f\n',res{end}{:});
  end
                                % save the updated summary results
  save(fullfile(dataRootDir,expt,sprintf('analyse_res')),'res');    
end
