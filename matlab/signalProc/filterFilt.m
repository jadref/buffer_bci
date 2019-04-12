function [X,state]=filterFilt(X,state,varargin);
% apply IIR/FIR filter to the data
%
% Options:
%  dim        -- [int ] the dimensions along which to apply the filter
%  fs         -- [float] the sample rate of the data
%  ch_names   -- {'' } the names of the channels in X  (!IGNORED!)
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
%      .A - [order x 6] and .B - [] => A has the X,Y coefficients for the
%           second-order-section implementation of the filter
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
  if(any(opts.dim)<0) opts.dim(opts.dim<0)=ndims(X)+opts.dim(opts.dim<0)+1; end;
  
  % intialize the filter coefficients if not set yet
  if( isempty(opts.A) || isempty(opts.B) )
    [opts.A,opts.B]=initFilter(opts.filter,fs);
    opts.filtstate =warmupFilter(opts.A,opts.B,X,opts.dim);
  end
end
dim=opts.dim;
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
  if ( isempty(opts.B) || size(opts.A,1)>1 ) % Second-order-section filter
    % N.B. cannot use sosfilt as it **does not** provide the filter state as 
    % output to propogation between calls
    % N.B. this is *not* computationally efficient as we pass
    % through all the data multiple times..
    for li=1:size(opts.A,1); % apply the sos filter cascade
      [Xei,opts.filtstate(:,:,li)]=filter(opts.A(li,1:3),opts.A(li,4:6),Xei,opts.filtstate(:,:,li),dim(1));
    end
    if(~isempty(opts.B) ) Xei=opts.B*Xei; end;
  else % transfer-function filter    
    [Xei,opts.filtstate]=filter(opts.B,opts.A,Xei,opts.filtstate,dim(1));
  
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
    type={'high'}; if(numel(filter)>3) type=filter(4); end;
    if( strcmp(type{:},'bandpass') ) type={}; end;
    bands=filter{3}*2/fs; bands=max(0,min(1,bands));
    if( numel(bands)>1 )
      if( bands(2)>=1 )     bands=bands(1); type={'high'};
      elseif( bands(1)<=0 ) bands=bands(2); type={'low'};
      end;
    end
    switch filttype;
      case {'butter'}
        if( exist('OCTAVE_VERSION','builtin') && ~exist('butter') )
		  warning('loading the signal package : this may mess up your paths!!!');
          pkg load signal;
        end;
        if(  ord>6 ) warning('Butter is unstable with order>6'); end;
        [A,B]=butter(ord,bands,type{:});
      case {'buttersos'};
        if( exist('OCTAVE_VERSION','builtin') && ~exist('butter') )
		  warning('loading the signal package : this may mess up your paths!!!');
          pkg load signal;
        end;
        if(ord>10) warning('buttersos may be unstable with order>10'); end;
        [z,p,k]=butter(ord,bands,type{:}); % more stable to use zero-pole as intermediate
        A=zp2sos(z,p,k);B=1;
      case {'fir','firmin'};
        B   =fir1(ord,bands,type{:});
        A   =1;
        if ( isequal(filter{1},'firmin') )B=firminphase(B); end
        [ans,gDelay]=max(abs(B));
      otherwise;
        error('Unrecognised filter design type');
    end
  end
  return

function filtstate = filticwarmup(A,B,X,Y)
  % X = [d x t]
  if nargin < 4, Y = zeros(size(X)); end 

  nz = max(length(a)-1,length(b)-1);
  zf = zeros(nz,size(X,1)); % [order x d]
  % Pad arrays x and y to length nz if required
  X(:,end+1:nz)=0;
  Y(:,end+1:nz)=0;

  for i=nz:-1:1
    for j=i:nz-1
      zf(j,:) = b(j+1)*x(:,i)' - a(j+1)*y(:,i)'+zf(j+1,:);
    end
    zf(nz)=b(nz+1)*x(:,i)'-a(nz+1)*y(:,i)';
  end
  return;

%----------------------------------------------------
function testcase()
X=ones(2,1000);
X=cumsum(randn(2,1000*10),2);
X(1,:)=X(1,:)+1e3; % massive offset and difference between channels

% test initialization on simple inputs
[fX,s]=filterFilt(ones(2,1000),[],'filter',{'buttersos',8,.5,'high'},'fs',100);
clf;plot(fX');
max(abs(fX(:)))

% 1 call
[fX,s]=filterFilt(X,[],'filter',{'butter',8,.5,'high'},'fs',100);
clf;image3d(cat(3,X,fX),1,'disptype','plot','Zvals',{'X' 'fX'});
[fX,s]=filterFilt(X,[],'filter',{'buttersos',16,.1,'high'},'fs',100); 
clf;image3d(cat(3,X,fX),1,'disptype','plot','Zvals',{'X' 'fX2'});

% effect of order and edge-proximity on stability
[fX10,s]=filterFilt(X,[],'filter',{'buttersos',10,[.3 27],'bandpass'},'fs',250);
[fX14,s]=filterFilt(X,[],'filter',{'buttersos',14,[.3 27],'bandpass'},'fs',250);
clf;subplot(211);plot(fX10');title('ord=10'); subplot(212);plot(fX14');title('ord=14'); 

filter={'buttersos' 8 1 'high'}
X3d=reshape(X,[size(X,1),size(X,2)/10,10]);
fXo=filterFilt(X3d(:,:),[],'filter',filter,'fs',250);
s=[];
fXi=zeros(size(X3d));  % call in blocks
for ei=1:size(X3d,3);
  [fXi(:,:,ei),s]=filterFilt(X3d(:,:,ei),s,'filter',filter,'fs',250);
end;
clf;image3d(cat(3,fXo,fXi(:,:)),1,'disptype','plot','Zvals',{'fX once' 'fX incremental'});
mad(fXo,fXi)
max(abs(fXo(:)))

                                % with pre-config
fXii=zeros(size(X3d));  % call in blocks
[fXii(:,:,1),s]=filterFilt(X3d(:,:,1),[],'filter',{'buttersos',16,.1,'high'},'fs',100);
for ei=2:size(X3d,3);
  [fXii(:,:,ei),s]=filterFilt(X3d(:,:,ei),s);
end;
mad(fXii,fXi)

XfX=cat(3,X3d(:,:),fX(:,:));clf;image3d(XfX,1,'disptype','plot','Zvals',{'X' 'fX'});
