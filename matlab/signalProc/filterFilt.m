function [X,state]=filterFilt(X,state,varargin);
% apply IIR/FIR filter to the data
%
% Options:
%  dim        -- [int ] the dimensions along which to apply the filter
%  filter     -- the filter to use, either:
%                {'name' order cutoff 'type'} name and parameters for filter to use, one-of;
%                name is one-of: 
%                      'butter' -- butterworth, 'buttersos' -- butterworth with second-order-section imp
%                     'fir' -- finite impuluse response, 'firmin' -- min-phase finite impluse response
%                type is one of: 'low','high','stop','bandpass'
%                ord  is filter order : around fs for FIR or 6 for IIR (butter)
%                cuttoff in hz is: [1x1] for low/high pass, or [lowcutoff highcutoff] for bandpass/stop
%               OR [nTaps x 1] a set of coefficients to use in a FIR filter
%               OR {[nTaps1 x 1] [nTaps2 x 1]} set of IIR coeffients
%  N.B. see FIR1 for how to make an FIR filter, e.g. B=fir1(30,fcutOff*2/fSample,'low');
%  N.B. see FIRMINPHASE for how to make a min-phase FIR or min-lag FIR filter
%  N.B. see BUTTER for how to make an IIR filter, e.g. [A,B]=butter(6,fcutOff*2/fSample,'low');
%  fs           -- [float] sample rate of the raw data for setting the filter parameters
%
% Outputs:
%  X - [size(X)] the filtered data
%  state - [struct] the internal state of the filter process
%      .A - [1 x order] the Y coefficients for the filter
%      .B - [1 x order] the X coefficients for the filter order
%         OR
%      .A - [order x 6] the X,Y coefficients for the
%           second-order-section implementation of the filter
%      .B - []
%      .filtstate - [] the filter coeficients to propogate between calls
%      .dim - [int] the dimension the filter applies to
% Examples:
%   % 1) Simple band-pass filter along dimension 2
%   % First call with initial data to configure and warmup the filters
%   [X,filtstate]=filterFilt(X,[],'dim',2,'filter',{'buttersos',6,[.1 27],'bandpass'});
%   % continuous processing applying the filters
%   while(true);
%      X = getNewData();
%      [X,filtstate]=filterFilt(X,filtstate);
%   end;  
if( nargin<2 ) state=[]; end;
if( ~isempty(state) && isstruct(state) ) % ignore other arguments if state is given
  opts =state;
else
  opts=struct('dim',2,'filter',[],'A',[],'B',[],'filtstate',[],...
              'hdr',[],'fs',[],'ch_names','','ch_pos',[],'verb',0);
  [opts]=parseOpts(opts,varargin);
  fs =opts.fs;
  if(isempty(fs) && ~isempty(opts.hdr))
    if(isfield(opts.hdr,'fSample')) fs=opts.hdr.fSample; elseif(isfield(opts.hdr,'Fs')) fs=opts.hdr.Fs; end;
  end;

  % intialize the filter coefficients if not set yet
  if( isempty(opts.A) || isempty(opts.B) )
    [opts.A,opts.B]=initFilter(opts.filter,fs);
    opts.filtstate =warmupFilter(opts.A,opts.B,X,dim);
  end
end
dim=opts.dim;
dim(dim<0)=ndims(X)+dim(dim<0)+1;
szX=size(X); szX(end+1:max(dim))=1;
if( numel(dim)<2 )
  nEp=1;
else
  if( dim(2)~=dim(1)+1 ) error('Multiple trial dims not supported yet!'); end;
  nEp=prod(szX(dim(2:end)));
end;

% force conversion to double precision to apply the filter to avoid numerical stabilty issues if needed
doubleFilter=false; if ( ~isa(X,'double') ) doubleFilter=true; end

% make a index expression to extract the current epoch.
xidx  ={}; for di=1:numel(szX); xidx{di}=int32(1:szX(di)); end;

if( opts.verb>=0 && nEp>10 ) fprintf('filterFilt:'); end;
for epi=1:nEp; % auto-apply incrementally if given multiple epochs
  if( opts.verb>=0 && nEp>10 ) textprogressbar(epi,nEp); end;

                                % extract the data for this epoch
  Xei=X;
  if( numel(dim)>1 )
    xidx{dim(2)}=epi;                             
    Xei=X(xidx{:});
  end    
  if( doubleFilter ) Xei=double(Xei); end
                                % apply the filter
  if ( isempty(opts.B) ) % Second-order-section filter
    % N.B. this is *not* computationally efficient as we pass
    % through all the data multiple times..
    for li=1:size(opts.A,1); % apply the sos filter cascade
      [Xei,state.filtstate(:,:,li)]=filter(opts.A(li,1:3),opts.A(li,4:6),Xei,opts.filtstate(:,:,li),dim(1));       
    end
  else % transfer-function filter    
    [Xei,opts.filtstate]=filter(opts.B,opts.A,double(Xei),opts.filtstate,dim(1));
  
  end
  if ( doubleFilter ) Xei=single(Xei); end; % covert back to single
                                % put result back into X
  if( numel(dim)==1 )
    X         =Xei;
  else
    X(xidx{:})=Xei;
  end
end
if ( opts.verb>=0 && nEp>10 ) fprintf('done\n'); end;
state=opts;
return;

function [A,B]=initFilter(filter,fs)
% get the coefficients for a FIR/IIR filter given the parameters
% in filter
%                {'name' order cutoff 'type'} name and parameters for filter to use, one-of;
%                name is one-of: 
%                      'butter' -- butterworth, 'buttersos' -- butterworth with second-order-section imp
%                     'fir' -- finite impuluse response, 'firmin' -- min-phase finite impluse response
%                type is one of: 'low','high','stop','bandpass'
%                ord  is filter order : around fs for FIR or 6 for IIR (butter)
%                cuttoff in hz is: [1x1] for low/high pass, or [lowcutoff highcutoff] for bandpass/stop
%               OR [nTaps x 1] a set of coefficients to use in a FIR filter
%               OR {[nTaps1 x 1] [nTaps2 x 1]} set of IIR coeffients
%  N.B. see FIR1 for how to make an FIR filter, e.g. B=fir1(30,fcutOff*2/fSample,'low');
%  N.B. see FIRMINPHASE for how to make a min-phase FIR or min-lag FIR filter
%  N.B. see BUTTER for how to make an IIR filter, e.g. [A,B]=butter(6,fcutOff*2/fSample,'low');
%  fs           -- [float] sample rate of the raw data for setting the filter parameters
%
% Outputs:
%   A - the Y part of the output.
%      N.B. if size(A,1)>1 => A represents a second-order-section fitler
%   B - the X part of the filter.
  
  if ( isnumeric(filter) )
    B=filter(:); A=1;   
  elseif ( iscell(filter) && numel(filter)==2 )
    B=filter{1}(:); A=filter{2}(:);
  elseif ( iscell(filter) && ischar(filter{1}) ) % filter name
    filttype=lower(filter{1});
    ord=filter{2};
    bands=filter{3};
    type='high'; if(numel(filter)>3) type=filter{4}; end;
    switch filttype;
      case {'butter','buttersos'};
        [B,A]=butter(ord,bands*2/fs,type);
        if (strcmp(filttype,'buttersos')) A=tf2sos(B,A); B=[]; end;
      case {'fir','firmin'};
        B   =fir1(ord,bands*2/fs,type);
        A   =1;
        if ( isequal(filter{1},'firmin') )B=firminphase(B); end
        [ans,gDelay]=max(abs(B));
      otherwise;
        error('Unrecognised filter design type');
    end
  end
  opts.B=B;
  opts.A=A;


function filtstate=warmupFitler(A,B,X,dim)
  % pre-warm the filter on time-reversed data
  if( nargin<3 ) dim=2; end;
  if( dim >3  ) error('Only for dim<3 for now'); end;
  % extract 100 samples of time-reversed data
  if( dim==1 )        tmp=X(min(end,100):-1:1,:,1); 
  elseif ( dim==2 )   tmp=X(:,min(end,100):-1:1,1);
  end

  if( isa(X,'single') )  tmp=double(tmp); end;
  if( ~isempty(B) ) % normal filter warmup
    [tmp,filtstate]=filter(B,A,tmp,[],dim);
  else % SOS
    [tmp,filtstate]=filter(A(1,1:3),A(1,4:6),tmp,[],dim);
    filtstate=repmat(filtstate,[1 1 size(A,1)]);
    for li=2:size(A,1); % apply the filter cascade
       [tmp,filtstate(:,:,li)]=filter(state.sos(li,1:3),state.sos(li,4:6),tmp,[],dim);
    end
  end  
  return;

  


                        %----------------------------------------------------
function testcase()
X=cumsum(randn(2,1000*10),2);

% 1 call
[fX,s]=filterFilt(X,[],'filter',{'butter',6,.1,'high'},'fs',100); 
XfX=cat(3,X,fX);clf;image3d(XfX,1,'disptype','plot','Zvals',{'X' 'fX'});

X3d=reshape(X,[size(X,1),size(X,2)/10,10]);
s=[];fX=[];  % call in blocks
for ei=1:size(X3d,3);
  [fX(:,:,ei),s]=filterFilt(X3d(:,:,ei),s,'filter',{'butter' 6 .1 'high'},'fs',100);
end;

XfX=cat(3,X3d(:,:),fX(:,:));clf;image3d(XfX,1,'disptype','plot','Zvals',{'X' 'fX'});
