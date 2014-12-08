% buffer controlled execution of the different signal processing phases.
%
% Input events: (type,value)
%  (startPhase.cmd,capfitting) -- show capfitting
%  (startPhase.cmd,calibrate)  -- start calibration phase processing (i.e. cat data)
%  (startPhase.cmd,testing)    -- start test phase, i.e. on-line prediction generation
%  (startPhase.cmd,exit)       -- stop everything
configureNF;

if( ~exist('capFile','var') || isempty(capFile) ) 
  [fn,pth]=uigetfile('../utilities/*.txt','Pick cap-file'); capFile=fullfile(pth,fn);
  if ( isequal(fn,0) || isequal(pth,0) ) capFile='1010.txt'; end; % 1010 default if not selected
end
if ( ~isempty(strfind(capFile,'1010.txt')) ) overridechnms=0; else overridechnms=1; end; % force default override
thresh=[.5 3];  badchThresh=.5;
if ( ~isempty(strfind(capFile,'tmsi')) ) thresh=[.0 .1 .2 5]; badchThresh=1e-4; end;
datestring = datestr(now,'yymmdd');
dname='training_data';
cname='clsfr';
if ( ~exist('verb','var') ) verb =1; end;
if ( ~exist('subject','var') ) subject='test'; end;
if ( ~exist('clsSubj','var') ) clsSubj=''; end;

% main loop waiting for commands and then executing them
if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) 
  clsfrfile = [cname '_' subject '_' datestring];
  if ( ~exist([clsfrfile '.mat'],'file') ) clsfrfile=[cname '_' subject]; end;
  if ( ~exist([clsfrfile '.mat'],'file') )
    clsfr = buffer_train_nf_clsfr(width_ms,feedback,hdr,'spatialfilter','none','capFile',capFile,'overridechnms',overridechnms);
    clsfrfile = [cname '_' subject '_' datestring];
    fprintf('saving to : %s',clsfrfile);  save(clsfrfile,'clsfr');
  end
  load(clsfrfile);
  if ( isfield(clsfr,'clsfr') ) clsfr=clsfr.clsfr; end; 
  clsSubj = subject;
end;

% apply prediction generator until we get told to stop
cont_applyClsfr(clsfr,'step_ms',step_ms,'predFilt',@(x,s) stdFilt(x,s,expSmoothFactor),'predEventType',feedbackEventType,'endType','neurofeedback');
