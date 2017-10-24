function [X,state]=filterFilt(X,state,varargin);
% apply FIR filter to the data
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
%                cuttoff is: [1x1] for low/high pass, or [lowcutoff highcutoff] for bandpass/stop
%               OR [nTaps x 1] a set of coefficients to use in a FIR filter
%               OR {[nTaps1 x 1] [nTaps2 x 1]} set of IIR coeffients
%  N.B. see FIR1 for how to make an FIR filter, e.g. B=fir1(30,fcutOff*2/fSample,'low');
%  N.B. see FIRMINPHASE for how to make a min-phase FIR or min-lag FIR filter
%  N.B. see BUTTER for how to make an IIR filter, e.g. [A,B]=butter(6,fcutOff*2/fSample,'low');
%  fs           -- [float] sample rate of the raw data for setting the filter parameters

if( nargin<2 ) state=[]; end;
if( ~isempty(state) && isstruct(state) ) % ignore other arguments if state is given
  opts =state;
else
  opts=struct('dim',2,'filter',[],'A',[],'B',[],'filtstate',[],...
              'fs',[],'ch_names','','ch_pos',[],'verb',0);
  [opts]=parseOpts(opts,varargin);

                           % intialize the filter coefficients if not set yet
  if( isempty(opts.A) || isempty(opts.B) )
    if ( isnumeric(opts.filter) )
      B=opts.filter(:); A=1;   
    elseif ( iscell(opts.filter) && numel(opts.filter)==2 )
      B=opts.filter{1}(:); A=opts.filter{2}(:);
    elseif ( iscell(opts.filter) && ischar(opts.filter{1}) ) % filter name
      filttype=lower(opts.filter{1});
      fs=opts.fs;
      ord=opts.filter{2};
      bands=opts.filter{3};
      type='high'; if(numel(opts.filter)>3) type=opts.filter{4}; end;
      switch filttype;
        case {'butter','buttersos'};
          [B,A]=butter(ord,bands*2/fs,type);
          if (strcmp(filttype,'buttersos')) [sos,sosg]=tf2sos(B,A); end;
        case {'fir','firmin'};
          B   =fir1(ord,bands*2/fs,type);
          A   =1;
          if ( isequal(opts.filter{1},'firmin') )B=firminphase(B); end
          [ans,gDelay]=max(abs(B));
        otherwise;
          error('Unrecognised filter design type');
         end
    end
    opts.B=B;
    opts.A=A;
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
    
                                % apply the filter
  if ( doubleFilter ) % convert to double and back in the filtering
    [Xei,opts.filtstate]=filter(opts.B,opts.A,double(Xei),opts.filtstate,dim(1));
    Xei=single(Xei); % covert back to single
  else
    [Xei,opts.filtstate]=filter(opts.B,opts.A,Xei,opts.filtstate,dim(1));
  end

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
