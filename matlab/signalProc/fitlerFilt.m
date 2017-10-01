function [x,s]=firFilt(x,s,varargin);
% apply FIR filter to the data
%
% Options:
%  dim        -- the dimension along which to apply the filter
%  filter     -- the filter to use, either:
%                {'name' 'type' order cutoff} name and parameters for filter to use, one-of;
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
%  center       -- [bool] flag if we center before applying the filter
%  fs           -- [float] sample rate of the raw data for setting the filter parameters

if( nargin<2 ) state=[]; end;
if( ~isempty(state) && isstruct(state) ) % ignore other arguments if state is given
  opts =state;
else
   opts=struct('dim',2,'filter',[],'center',1,'A',[],'B',[],'filtstate','',...
               'fs',[],'ch_names','','ch_pos',[],'verb',0);
   [opts]=parseOpts(opts,varargin);

   % intialize the filter coefficients if not set yet
   if( isempty(opts.A) || isempty(opts.B) )
      if ( isnumeric(opts.filter) )
         B=opts.filter(:); A=1;   
      elseif ( iscell(opts.filter) && numel(opts.filter)==2 )
         B=opts.filter{1}(:); A=opts.filter{2}(:);
      elseif ( iscell(opts.filter) && isstr(opts.filter{1}) ) % filter name
         filttype=lower(opts.filter{1});
         fs=opts.fs;
         type=opts.filter{2};  ord=opts.filter{3};  bands=opts.filter{4};
         switch filttype;
           case {'butter','buttersos'}; [B,A]=butter(ord,bands*2/fs,type);
             if (strcmp(filttype,'buttersos')) [sos,sosg]=tf2sos(B,A); end;
           case {'fir','firmin'};        B   =fir1(ord,bands*2/fs,type); A=1;
             if ( isequal(opts.filter{1},'firmin') )B=firminphase(B); end
             [ans,gDelay]=max(abs(B));
           otherwise;
             error('Unrecognised filter design type');
         end
      end
   end
end
dim=opts.dim;
szX=size(X); szX(end+1:max(dim))=1;
if( numel(dim)<3 ) nEp=1; else nEp=szX(dim(3)); end;

dim=n2d(z,opts.dim); 

% force conversion to double precision to apply the filter to avoid numerical stabilty issues if needed
doubleFilter=false; if ( ~isa(X,'double') ) doubleFilter=true; end

% make a index expression to extract the current epoch.
xidx  ={}; for di=1:numel(szX); xidx{di}=int32(1:szX(di)); end;
nep   =szX(dim(1));

if( opts.verb>=0 && nEp>10 ) fprintf('filterFilt:'); end;
for epi=1:nEp; % auto-apply incrementally if given multiple epochs
  if( opts.verb>=0 && nEp>10 ) textprogressbar(epi,nEp); end;
                                % extract the data for this epoch
   xidx{dim(1)}=epi;                             
   Xei=X(xidx{:});

   % pre-process the data
   if ( opts.center )       Xei = repop(Xei,'-',mean(Xei,dim(1))); end;
   if ( opts.doubleFilter ) % convert to double and back in the filtering
      [Xei,opts.filtstate]=filter(opts.B,opts.A,double(Xei),opts.filtstate,dim(1));
      Xei=single(Xei); % covert back to single
   else
      [Xei,opts.filtstate]=filter(opts.B,opts.A,Xei,opts.filtstate,dim(1));
   end
   X(xidx{:})=Xei;
end
if ( opts.verb>=0 && nEp>10 ) fprintf('done\n'); end;
return;
%----------------------------------------------------
function testcase()
