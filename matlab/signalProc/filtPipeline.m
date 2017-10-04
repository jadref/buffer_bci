function [X,state]=filtPipeline(X,state,varargin);
% apply a sequence of filters in a pipeline to the data
% apply a sequence of filters to the input data
%
% Example:
%  % apply EMG removal then EOG removal
%  [Y,pstate]=filtPipeline(X,[],{'rmEMGFilt',[1 2 3]},{'artChRegress',[1 2 3],[1 2]});

opts={};
if( isempty(state) )  % extract the pipeline from the state
  % BODGE: deal with the name/position options as a special case....
  opts=struct('ch_names',[],'ch_pos',[],'fs',[]);
  [opts,varargin]=parseOpts(opts,varargin);
  opts={'ch_names',opts.ch_names,'ch_pos',opts.ch_pos,'fs',opts.fs};
  pipeline     =varargin;
  pipelinestate=[];  
else % extract the pipeline from the arguments
  pipeline     =state.pipeline;      % function to run + args
  pipelinestate=state.pipelinestate; % running state for each function
end

% apply the pipeline
if(isempty(pipelinestate))pipelinestate=cell(1,numel(pipeline));end;
for pi=1:numel(pipeline);
  if( ischar(pipeline{pi}) ) pipeline{pi}={pipeline{pi}}; end;
  [X,pipelinestate{pi}]=feval(pipeline{pi}{1},X,pipelinestate{pi},pipeline{pi}{2:end},opts{:});
end

% put the state into the state variable
state.pipeline     =pipeline;
state.pipelinestate=pipelinestate;
return;
%-------------------------------------------------------------------
function testCase();
nSrc=10; nNoise=2; nCh=10; nSamp=1000; nEp=1000;
S=cumsum(randn(nSrc,nSamp,nEp),2); S=repop(S,'-',mean(S,2)); % sources with roughly 1/f spectrum
S(1:nNoise,:,:)=randn(nNoise,nSamp,nEp); %noise sources with flat spectrum
S=repop(S,'./',sqrt(sum(S(:,:).^2,2))); % unit-power signals

                                % signal forward model
A=eye(nSrc,nCh); % 1-1 mapping
A=randn(nSrc,nCh); % random sources [ M x d ]
% spatially smeared but centered sources
a=mkSig(nCh,'gaus',nCh/2,nCh/4);[ans,mi]=max(a);a=a([mi:end 1:mi-1]);A=zeros(nSrc,nCh);for i=1:size(A,1);A(i,:)=circshift(a,i-1);end; 
                                % data construction
X =reshape(A'*S(:,:),[nCh,nSamp,nEp]); % source+propogaged noise

% cascade: emg-RM -> eog-RM
[Y1,emgst]=rmEMGFilt(X,[],[1 2 3]); %EMG
[Y2,eogst]=artChRegress(Y1,[],[1 2 3],[1 2]); %EOG ch1+2

                                % with filt-pipeline
[Y,pstate]=filtPipeline(X,[],{'rmEMGFilt',[1 2 3]},{'artChRegress',[1 2 3],[1 2]});
mad(Y,Y2)


