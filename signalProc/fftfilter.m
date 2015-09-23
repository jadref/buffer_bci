function [fg,g]=fftfilter(f,g,len,dim,detrendp,win,hilbertp,MAXEL,verb);
% Spectrally filter the input signal with g using ffts
%
%  [fg,g]=fftfilter(f,g[,len,dim,detrendp,win,hilbertp,MAXEL,verb]);
% Inputs:
%  f   -- [n-d] signal 
%  g   -- [Lx1] spectral filter vector.  L <= size(f,dim)
%         (Note: use mkFilter to make this filter, e.g.
%          mkFilter(floor(size(f,dim)/2),[8 10 24 28],1/duration); % 10-24 Hz band pass)
%  len -- [2x1] len(1) = N-point fft to use for *f*, ([size(f,dim), size(f,dim)])
%               len(2) = Output sample size (for up/down sample) 
%         **N.B.** due to a bug, down-sampling only allows **ODD** sized outputs....
%  dim -- dimension to filter along. (first non-singlenton dimension)
%  detrendp -- [int] do we detrend the input before fourier filtering?  (1)
%               0=no, 1=detrend, 2=center
%  win -- [size(f,dim)x1] window to apply to the data before fft transform ([])
%  hilbertp -- [int] are we doing a hilbert transform? (0)
%              0=non-hilbert, 1=hilbert with amp only out, 2=hilbert with phase only out, 3=hilbert with amp+phase
%  MAXEL -- maximum number of array elments to process at a time
%  verb  -- [int] verbosity level <=0-off, >0 for on
% Outputs:
%  fg  -- [size(f) with dim=len(2)] f convolved with g
%  g   -- the actual filter we used
%
% Example:
%   fftfilter(X,mkFilter(floor(size(X,2)/2),[0 0 30 40],1/3),[],2); % low-pass @30 for X with time in dim2
if ( nargin < 3 || isempty(len) ) len=size(f,dim); end;
if ( nargin < 4 || isempty(dim) ) dim=find(size(f)>1,1); end;
if ( nargin < 5 || isempty(detrendp) ) detrendp=1; end;
if ( nargin < 6 ); win=[]; 
else 
  if ( ~isempty(win) && numel(win)~=size(f,dim) ); error('incompatiable window size'); end;
  if ( all(win==1) ) win=[]; end; % fast-path when no window applied
end;
if ( nargin < 7 || isempty(hilbertp) ) hilbertp=0; end;
if ( nargin < 8 || isempty(MAXEL) ) MAXEL=2e6; end;
if ( nargin < 9 || isempty(verb) ) verb=-1; end;
if ( numel(len) < 2 ) len=[len repmat(size(f,dim),2-numel(len),1)]; end;
len(len==0)=size(f,dim); % convert 0's to full size
len=round(len); % ensure integer
if ( any(dim<0) ) dim=ndims(f)+dim+1; end;
if ( size(g,1)==1 ) g=g'; end; % ensure col vector

if ( numel(g) < len(1) ) % 0-pad & replicate to pos+neg freq
   g=[g; zeros(floor(len(1)/2)-numel(g),1)];     % 0 pad
   if ( hilbertp ) 
      g=[g; zeros(1+mod(len(1),2),1); zeros(numel(g)-1,1)]; % only keep positive frequencies
   else
      g=[g; zeros(1+mod(len(1),2),1); g(end:-1:2)]; % +/- freq
   end
end

g = shiftdim(g,-(dim-1)); % make g the right size

if ( len(2)>size(f,dim) ) % upsample
   warning('UpSampling not implemented yet!');
   len(2)=size(f,dim);
elseif ( len(2)<len(1) ) % downsample
   % index expression to rip out the subset we want
   nFreq = ((len(2)-1)/2)*(len(1)./size(f,dim)); % nFreqs to ifft, accounting for 0-padding
   if ( mod(len(1),2)==1 ) nFreq=floor(nFreq); end;
   sIdx=[1 1+(1:ceil(nFreq)) len(1)+1-(floor(nFreq):-1:1)];
else
   sIdx=1:size(f,dim);
end
if ( numel(sIdx)<len(2) ) len(2)=numel(sIdx); end;
%len(2)=numel(sIdx);

if( detrendp ) 
   dtwght=1; % weight to edges to reduce wrap-arround artifacts
%   if ( size(f,dim)>90 ) dtwght=ones(size(f,dim),1); dtwght(min(20,round(end*.10)):max(end-20+1,round(end*.90)))=0; end; 
end;

szf = size(f); len = round(len); szf(dim)=len(2);
fg=zeros(szf,class(f)); if ( hilbertp==2 ) fg=complex(fg); end; % only if want power + phase
[idx,chkStrides,nchnks]=nextChunk([],size(f),dim,MAXEL);
ci=0; if ( verb >= 0 && nchnks>1 ) fprintf('%s:',mfilename); end;
while ( ~isempty(idx) )
   tmp = f(idx{:});
   if ( detrendp==1 );        tmp=detrend(tmp,dim,1,dtwght,MAXEL);  % detrend
   elseif ( detrendp==2 );    tmp=repop(tmp,'-',mean(tmp,dim)); % center
   end
   if ( ~isempty(win) );      tmp=repop(tmp,'*',shiftdim(win(:),-dim+1)); end; % apply temporal window
	% fourier transform
   if ( len(1)>size(f,dim) ); tmp=fft(tmp,len(1),dim); else tmp=fft(tmp,[],dim); end;
   tmp=repop(tmp,'.*',g);    % apply the filter
   if ( len(2) < len(1) ) % down-sample
      tmpIdx={};for di=1:ndims(tmp); tmpIdx{di}=1:size(tmp,di); end; tmpIdx{dim}=sIdx;
      tmp=tmp(tmpIdx{:});    % only keep the points we want
   elseif ( len(2) > len(1) ) % up-sample, add more frequency points
      error('Not implementated yet'); 
   end
   tmp=ifft(tmp,[],dim).*(size(tmp,dim)./len(1)); % inverse-transform
   if ( len(2) < size(tmp,dim) ) % down-sample
      tmpIdx={};for di=1:ndims(tmp); tmpIdx{di}=1:size(tmp,di); end; tmpIdx{dim}=1:len(2);
      tmp=tmp(tmpIdx{:});    % only keep the points we want
   end
   if(hilbertp==0)     tmp=real(tmp); % real-only
   elseif(hilbertp==1) tmp=2*abs(tmp); 
   elseif(hilbertp==2) tmp=angle(tmp); 
   elseif(hilbertp==3) tmp=2*tmp; 
   end; % amp/phase?
   outIdx=idx; outIdx{dim}=1:len(2);
   fg(outIdx{:})=tmp; % only store the non-padded bit
   idx=nextChunk(idx,szf,chkStrides);
   if ( verb >=0 && nchnks>1 ) ci=ci+1; textprogressbar(ci,nchnks);  end
end
if ( verb>=0 && nchnks>1) fprintf('\n'); end;
return;

%---------------------------------------------------------------------------
function testcase()
f=cumsum(randn(1000,100)); %f=cumsum(randn(999,100)); 
dim=1;
sf=512; dur_s=size(f,dim)/sf;

clf; 
subplot(211);plot(f(:,1)); hold on; 
subplot(212);plotspect(f(:,1),sf,dim); hold on; 

c=linecol;subplot(211); plot(ff(:,1),c); subplot(212); plotspect(ff(:,1),sf,dim,c);

% normal
ff=fftfilter(f,mkFilter(size(f,dim)/2,[0.7 10],1/dur_s),[],dim);

% 0-padded normal
ff=fftfilter(f,mkFilter(size(f,dim)/2,[0.7 10],1/dur_s),size(f,1)*1.1,dim);

% down-sample
ff=fftfilter(f,mkFilter(size(f,dim)/2,[0.7 10],1/dur_s),[size(f,1) size(f,1)*.9],dim);

% 0-padded + down-sample
ff=fftfilter(f,mkFilter(size(f,dim)/2,[0.7 10],1/dur_s),[size(f,1)*1.5 size(f,1)*.9],dim);

% chunked
ff=fftfilter(f,mkFilter(size(f,dim)/2,[0.7 10],1/dur_s),size(f,1)*1.1,dim);

% with linear detrend
ff=fftfilter(f,mkFilter(size(f,dim)/2,[0.1 10],1/dur_s),[],dim,1);

% with hilbert
f=[sin(1:(2*pi)/10:100)*10 sin(1:(2*pi)/10:100)*20 sin(1:(2*pi)/4:100)*30]'+5;
dim=1;
sf=100; dur_s=size(f,dim)/sf;
ff=fftfilter(f,mkFilter(size(f,dim)/2,[0 inf],1/dur_s),[],dim,1,[],1);
clf;plot([f ff])
fflp=fftfilter(ff,mkFilter(size(f,dim)/2,[0 5],1/dur_s),[],dim,0);
clf;plot([f ff fflp])
