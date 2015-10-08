function [filt]=mkFilter(len,bands,xscale)
% Make different types of spectral/temporal filter
%
% filt = mkFilter(len,bands/type,xscale)
% simple code to make a temporal/spectral window given a set of pass-bands
% Inputs
%  len   -- Number of elements in the output filter
%         OR
%           [len x 1] vector of bin centers
%  bands -- Either:
%         a) vector with the band limits, 
%             [ min max ] or [ min cent max ] or [ mstart mend maxstart maxend]
%             N.B. the 1st elment in the filter has band value of 0!!!
%         b) String describing the filter type wanted, possibly with optional parameters one of:
%          {rect,one,gaussian,hamming,hamming0,hanning,hanning0,bartlet,blackman,kasier}
%         c) Cell array of filter types and their optional parameters, e.g. {'gaus' 10} or band limits
%         d) Cell array of cell arrays.  Each sub-cell-array defines 1
%            output filter
%         e) [len x 1] vector containing the actual filter to use
%      N.B. this can be a cell array of bands types and the resulting filter
%           is the max of these filters
%  xscale-- Scaling of the x axis, used to convert from bands to sample
%           indexs, (N.B. use 1/fs for time filters, and 1/duration=fs/len for spectral) (1)
%           OR
%           [len x 1] vector of bin centers
%
% Outputs:
%  filt  -- [len x 1] filter or 
%           [len x numel(bands)] filters for vector-cell-array inputs
%           N.B. this is normalise such that its max amplitude==1
%
% Example:
%  filt= mkFilter(floor(nSamp/2),[8 10 24 28],1/duration); % mk fftfilter filter for data nSamp long = duration (s)
% N.B. for constant weight overlapping window functions you should use:
%  blackman=.37,kaiser(2)=.46, rest=.5
if ( nargin < 3 ) xscale=1; end;
% BODGE: make old calling convention still work (mostly)
if ( ~iscell(bands) ) bands={bands}; end;
if ( numel(len)>1 ) xscale=len; len=numel(xscale); end;
if ( isempty(len) && numel(xscale)>1 ) len=numel(xscale); end;

if ( isempty(bands{1}) )  
   filt=ones(len,1);   

elseif ( iscell(bands{1}) ) 
   filt=zeros(len,numel(bands));
   for j=1:numel(bands); % build a result for each input by recursive calls
      filt(:,j)=mkFilter(len,bands{j},xscale);
   end

elseif ( iscell(xscale) ) % exact match only
  filt=zeros(len,1);
  mi=zeros(numel(bands),1);
  for bi=1:numel(bands);
    for xi=1:numel(xscale);
      if ( isequal(bands{bi},xscale{xi}) ) mi(bi)=xi; break; end
    end
  end
  if( any(mi==0) ) 
    warning(sprintf('Some vals didnt match: [%s]',sprintf('%d',find(mi==0))));
  end
  filt(mi(mi>0))=1;
  
elseif ( ischar(bands{1}) )
   filt=zeros(len,1);
   switch bands{1}
    case {'rect','rectangle','one','tophat','box','boxcar'};
     filt=ones(len,1);
    
    case {'gaus','gaussian'};  % 2-sigma centered gaussian over whole region
     sigma=(len-1)/2; if ( numel(bands)>1 ) sigma=bands{2}; end
     filt= exp(-.5*(([0:len-1]'-(len-1)/2)./sigma).^2);
    
    case 'hamming'; % hamming window (optimised for min side-lobe size)
     filt= .53836 - (1-.5386)*cos( ([0:len-1])*2*pi/(len-1) ); 
    
    case 'hanning'; % raised cosine -- non-zero at limits
     filt= .5*(1- cos( ([1:len])*2*pi/(len+1) ));
    
    case 'hanning0';% raised cosine -- zero at limits
     filt= .5*(1- cos( ([0:len-1])*2*pi/(len-1) ));
    
    case 'bartlet'; % triangle window -- non-zero at limits
     filt= [1:ceil(len/2) floor(len/2):-1:1]/(len/2);
    
    case 'bartlet0'; % triangle window -- zero at limits
     filt= [0:ceil(len/2)-1 floor(len/2)-1:-1:0]/(len/2);
    
    case 'blackman'; % 2nd order raised cosine
     filt= .424 - .497*cos([0:len-1]*2*pi/(len-1)) + 0.078*cos([0:len-1]*4*pi/(len-1));
    
    case 'kaiser';   
     % approx DPSS method using Kaiser's approx
     % N.B. alpha controls the side-lobe level vs main-lobe peak trade-off
     %      alpha \approx 1/2 * \Delta_t \Delta_f
     %      i.e. alpha is the product of temporal and spectral resolution
     % see http://ccrma.stanford.edu/~jos/sasp/Kaiser_Window_Beta_Parameter.html
     alpha=2; if ( numel(bands)>1 ) alpha=bands{2}; end
     filt=besseli(0,alpha*pi*[sqrt(1-(([0:len-1]-(len-1)/2)/(len/2)).^2)])/besseli(0,alpha*pi);
    
    otherwise;
     error('Unrecognised window type: %s\n',bands{1});
  end
  filt=filt(:); % ensure is column vector

elseif( isnumeric(bands{1}) && numel(bands{1})==1 )
   filt=bands{1}*ones(len,1);
   
else
   filt=zeros(floor(len),1);
   for i=1:numel(bands)
      if ( numel(bands{i})==3 ) 
         bands{i}=[bands{i}(1) bands{i}(2) bands{i}(2) bands{i}(3)];
      elseif( numel(bands{i})==2 )
         bands{i}=[bands{i}(1) bands{i}(1) bands{i}(2) bands{i}(2)];
      end
      if ( numel(bands{i})==4 )
         % convert from frequencies to indicies in the fft'd data array
         if ( numel(xscale)==1 ) 
           band=max(min((bands{i}/xscale)+.5,size(filt,1)),0); % N.B. shift to bin end? why????
         else % find closest point
           for j=1:numel(bands{i}); 
             if ( isnumeric(xscale) )
               [ans,band(j)]= min(abs(bands{i}(j)-xscale)); 
             else % work with cell array xscale spec
               for k=1:numel(xcale);
                 if(isequal(bands{i}{j},xscale{k}))band(j)=k;break;end;
               end
             end
           end
         end
         grad=1./max([band(2)-band(1) band(4)-band(3)],eps);
         if( all(band<=1) || all(band>=len) ) 
            warning('Band is outside the requested length');
         end
         % build the filter
         tmpf=zeros(size(filt));
         if( ceil(band(1))<ceil(band(2)) )       % up-ramp
            rng=[.5*(ceil(band(1))-band(1)).^2*grad(1);
                 1-.5*(band(2)-floor(band(2))).^2*grad(1)];
            tmpf(ceil(band(1)):ceil(band(2)))=linspace(rng(1),rng(2),ceil(band(2))-ceil(band(1))+1);
         elseif ( band(2)==.5 ) % zero is special
           tmpf(ceil(band(2)))=1;
         else
            tmpf(ceil(band(2)))=ceil(band(2))-.5 -mean([band(1),band(2)]-.5); % proportional part, compensate for the +.5
         end
         tmpf(ceil(band(2))+1:ceil(band(3))-1)= 1; % top-hat
         if ( ceil(band(3))<ceil(band(4)) )      % down-ramp
            rng=[1-.5*(ceil(band(3))-band(3)).^2*grad(2);
                 .5*(band(4)-floor(band(4))).^2*grad(2)];
            tmpf(ceil(band(3)):ceil(band(4)))=linspace(rng(1),rng(2),ceil(band(4))-ceil(band(3))+1);
         else
            tmpf(ceil(band(3)))=mean([band(3),band(4)]-.5)-floor(band(3)-.5-1e-4); % proportional part, compensate for the +.5
         end
         filt=max(filt,tmpf(1:numel(filt)));
         filt=.5-.5*cos(pi*filt);  % smooth the edges
      
      elseif ( numel(bands{i})==size(filt,1) )
         filt=max(filt,bands{i}(:));
      
      else
         error('Incorrectly specified set of band limits');
      end
   
   end
 end
 for i=1:size(filt,2);% unit amplitude
   filt(:,i) = filt(:,i)./max(filt(:,i));
 end
return
%---------------------------------------------------------------------------
function []=testCases()
len=40;fs=2; sampres=1/fs; freqs=0:sampres:(len-1)*sampres;
filt=mkFilter([0 5 10 15],len,1./fs); % 1 filter about 7Hz
plot(freqs,filt);
filt=mkFilter(len,{[0 1 3 5] [10 12 15 17]},sampres); % 1 multi modal filter
filt=mkFilter(len,{{[0 1 3 5]} {[10 12 15 17]}},sampres); % 2 filters
filt=mkFilter(len,{[0 1 3 5] [10 12 15 17]},freqs); % given bin centers

% test with a very low spectral resolution and high band spec resolution
clf;
filt=mkFilter(250,[7 8 27 28],500/500);freqs=fftBins(500,[],500);plot(freqs(1:numel(filt)),filt,'.-k');
hold on;
filt=mkFilter(50,[7 8 27 28],500/100); freqs=fftBins(100,[],500);plot(freqs(1:numel(filt)),filt,'.-')
filt=mkFilter(25,[7 8 27 28],500/50);  freqs=fftBins(50,[],500);hold on;plot(freqs(1:numel(filt)),filt,'.-g')


% compute the correct overlap ratio, for constant weight
nwindows=4; overlap=.5; N=493;
width=floor(N/((nwindows-1)*overlap+1));% nwindows=(N-width)/(overlap*width)+1;
ff=mkFilter('hanning',width);
X=zeros(N,nwindows);
for i=1:size(X,2);
   X((i-1)*round(size(ff,1)*overlap)+[1:size(ff,1)],i)=ff;
end;
clf;plot(X);hold on; plot(sum(X,2),'k','LineWidth',3);


% Test the quality of the filters in time-domain implementation
fs=50;dur=1;len=dur*fs;
filt=mkFilter([8 9 11 12],len/2,1./dur); 
subplot(211);plot((0:numel(filt)-1)/dur,filt,'*-');
xlabel('freq (hz)');title('Spectral filter');
ifilt=(ifft([filt;0;filt(end:-1:2)]));
subplot(212);plot(linspace(0,dur,len),fftshift(ifilt),'*-');
xlabel('time (s)');title('Temporal filter');

% with an interesting xscale..
mkFilter(10,{'P9' 'P10'},{'1' '2' '3' 'P9' 'P10'})
