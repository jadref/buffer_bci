function [filt]=mkFilter(len,bands,xscale,ramptype)
% Make different types of spectral/temporal filter
%
% filt = mkFilter(len,bands/type,xscale,ramptype)
% simple code to make a temporal/spectral window given a set of pass-bands
% Inputs
%  len   -- Number of elements in the output filter
%         OR
%           [len x 1] vector of bin centers
%  bands -- Either:
%         a) vector with the pass-band limits, padded at ends with ramptype
%             [ lo hi ] or [ lo cent hi ] or [ lo-cut lo-pass hi-pass hi-cut] 
%             N.B. the 1st elment in the filter has band value of 0!!!
%            OR
%             [ -1 lo-cut lo-pass hi-pass hi-cut] where negative hi-pass/cut values
%               work back from the end of the time range
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
%  ramptype -- 'str' type of ramp to use at the edges of the band-pass filter.           ('cos')
%              one of: 'cos' - raised cosine, 'lin' - linear
% Outputs:
%  filt  -- [len x 1] filter or 
%           [len x numel(bands)] filters for vector-cell-array inputs
%           N.B. this is normalise such that its max amplitude==1
%
% Example:
%  filt= mkFilter(floor(nSamp/2),[8 10 24 28],1/duration); % mk fftfilter filter for data nSamp long = duration (s)
% N.B. for constant weight overlapping window functions you should use:
%  blackman=.30,kaiser(2)=.45, rest=.5
if ( nargin < 3 || isempty(xscale) ) xscale=1; end;
if ( nargin < 4 || isempty(ramptype) ) ramptype='cos'; end;
% BODGE: make old calling convention still work (mostly)
if ( ~iscell(bands) ) bands={bands}; end;
if ( numel(len)>1 ) xscale=len; len=numel(xscale); end;
if ( isempty(len) && numel(xscale)>1 ) len=numel(xscale); end;
% gen full point label if not given
if ( numel(xscale)==1 && isnumeric(xscale) )  xscale=(0:len-1)*xscale; end; 

if ( isempty(bands{1}) )  
   filt=ones(len,1);   

elseif ( iscell(bands{1}) ) 
   filt=zeros(len,numel(bands));
   for j=1:numel(bands); % build a result for each input by recursive calls
      filt(:,j)=mkFilter(len,bands{j},xscale,ramptype);
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
    
    case 'bartlet'; % triangle window -- non-zero at limits
     filt= [1:ceil(len/2) floor(len/2):-1:1]/(len/2);
    
    case {'bartlet0','triangle'}; % triangle window -- zero at limits
     filt= [0:ceil(len/2)-1 floor(len/2)-1:-1:0]/(len/2);

    case {'gaus','gaussian'};  % 2-sigma centered gaussian over whole region
     sigma=(len-1)/2; if ( numel(bands)>1 ) sigma=bands{2}; end
     if (sigma<=0 ) sigma=1; end; % guard divide by 0
     filt= exp(-.5*(([0:len-1]'-(len-1)/2)./sigma).^2);

    case {'gaus.5','gaus2'};  % 2-sigma centered gaussian over whole region
     sigma=(2*len-1)/2; if ( numel(bands)>1 ) sigma=bands{2}; end
     if (sigma<=0 ) sigma=1; end; % guard divide by 0
     filt= exp(-.5*(([0:2*len-1]'-(2*len-1)/2)./sigma).^2);
     filt= filt(end-len+1:end); % 2nd half only returned    
     if ( strcmp(bands{1}(end-1:end),'.5') )
        filt= sqrt(filt);
     else
        filt= filt.^2;
     end

    case 'hanning'; % raised cosine -- non-zero at limits
     filt= .5*(1- cos( ([1:len])*2*pi/(len+1) ));

    case {'hanning.5','hanning2'}; % 1/2 of the raised cosine -- non-zero at limits
     filt= .5*(1- cos( ([1:(2*len)])*2*pi/(len*2+1) ));
     filt= filt(end-len+1:end); % only the 2nd half returned
     % BODGE: for the autocorr component transformation sqrt to simulate pre-power-comp-usage
     if ( strcmp(bands{1}(end-1:end),'.5') )
        filt= sqrt(filt);
     else
        filt= filt.^2;
     end

    case {'hanningL','hanningR'}; % 1/2 of the raised cosine -- non-zero at limits
     filt= .5*(1- cos( ([1:(2*len)])*2*pi/(len*2+1) ));
     % get the half we want
     if ( strcmp(bands{1}(end),'L') ) filt= filt(1:len); else filt= filt(end-len+1:end); end

    case 'hanning0';% raised cosine -- zero at limits
     filt= .5*(1- cos( ([0:len-1])*2*pi/(len-1) ));
    
    case 'hamming'; % hamming window (optimised for min side-lobe size)
     filt= .53836 - (1-.5386)*cos( ([0:len-1])*2*pi/(len-1) ); 
        
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
     filt=filt-min(filt); filt=filt./max(filt); % ensure is 0 at edges and 1 at max

    otherwise;
     try; % try as a function to evaluate
        fopts={}; if ( numel(bands>1) ) fopts=bands(2:end); end;
        filt = feval(bands{1},len,fopts{:});
     catch;
        error('Unrecognised window type: %s\n',bands{1});
     end
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
      elseif( numel(bands{i})==5 )
		  if ( isequal(bands{i}(1),-1) ) % neg values count back from the end of the range
			 bands{i}=bands{i}(2:end);
			 if ( any(bands{i}<0) )
				bands{i}(bands{i}<0) = xscale(end)+bands{i}(bands{i}<0);
			 end
		  else
			 warning('5 values spec but dont know how to use');
		  end
      end
      if ( numel(bands{i})==4 ) % use xscale to convert to indicies 
        band=zeros(4,1);
        for j=1:numel(bands{i}); 
          band(j)=bands{i}(j);
          band(j)=max(min(band(j),xscale(end)),xscale(1)); % bound to the available range
          if ( isnumeric(xscale) )
            [ans,binidx]= min(abs(band(j)-xscale)); % nearest bin center
            if( xscale(binidx)<band(j) && binidx<numel(xscale) ) band(j) = binidx + (band(j)-xscale(binidx))/(xscale(binidx+1)-xscale(binidx));
            elseif( xscale(binidx)>band(j) && binidx>1         ) band(j) = binidx + (band(j)-xscale(binidx))/(xscale(binidx)-xscale(binidx-1));
            else                                                 band(j) = binidx; 
            end
          else % work with cell array xscale spec
            for k=1:numel(xscale);
              if(isequal(bands{i}{j},xscale{k}))band(j)=k;break;end;
            end
          end
        end
         if( all(band<=1) || all(band>=len) ) 
            warning('Band is outside the requested length');
         end
         % build the filter
         tmpf=zeros(size(filt));
         if( ceil(band(1))<ceil(band(2)) )       % up-ramp            
            grad=1./(band(2)-band(1));
            tmpf(ceil(band(1)):ceil(band(2)))=min(1,((ceil(band(1)):ceil(band(2)))-band(1))*grad);
         elseif ( band(2)<=1 ) % zero is special
           tmpf(ceil(band(2)))=1;
         else
            tmpf(ceil(band(2)))=.5; % proportional part, compensate for the +.5
         end
         tmpf(ceil(band(2))+1:ceil(band(3))-1)= 1; % top-hat
			if ( ceil(band(3))<ceil(band(4)) )      % down-ramp
            grad=1./(band(3)-band(4));
            tmpf(ceil(band(3)):ceil(band(4)))=min(1,((ceil(band(3)):ceil(band(4)))-band(4))*grad);
			elseif ( band(3)>=xscale(end) ) % end-of-scale is also special
			  tmpf(ceil(band(3)))=1;
         else
           tmpf(ceil(band(3)))=.5;
         end
         filt=max(filt,tmpf(1:numel(filt)));
			if ( any(strcmp(ramptype,{'lin','tri'})) )
					 ; % already linear
			elseif ( strcmp(ramptype,'cos') )
           filt=.5-.5*cos(pi*filt);  % smooth the edges with raised cosine
			elseif ( any(strcmp(ramptype,'sqrtcos')) ) % sqrt to preserve power after filtering
			  filt=sqrt((1-cos(pi*filt))/2);
			elseif ( any(strcmp(ramptype,'sqrt')) )
			  %filt=sqrt(filt);
			  filt=sqrt((1-cos(pi*filt))/2);
			else
			  warning('unrecognised ramptype'); 
			end
      
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
len=40;fs=2;dur=len/fs; sampres=1/fs; freqs=0:sampres:(len-1)*sampres;
filt2=mkFilter(len,[5 10],1./fs); % 1 filter about 7Hz, 2-param version
filt3=mkFilter(len,[5 7 10],1./fs); % 1 filter about 7Hz, 3-param version
filt4=mkFilter(len,[0 5 10 15],1./fs); % 1 filter about 7Hz, 4-param version
filt5=mkFilter(len,[-1 0 5 10 15],1./fs); % 1 filter about 7Hz, 5-param version
filt6=mkFilter(len,[-1 0 5 -10 -5],1./fs); % 1 filter about 7Hz, 5-param version, neg-vals
clf;plot(freqs,[filt2 filt3 filt4 filt5 filt6],'linewidth',1);
filt=mkFilter(len,{[0 1 3 5] [10 12 15 17]},sampres); % 1 multi modal filter
filt=mkFilter(len,{{[0 1 3 5]} {[10 12 15 17]}},sampres); % 2 filters
filt=mkFilter(len,{[0 1 3 5] [10 12 15 17]},freqs); % given bin centers
filt=mkFilter(len,[0 inf])

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
filt=mkFilter(len/2,[8 9 11 12],1./dur); 
subplot(211);plot((0:numel(filt)-1)/dur,filt,'*-');
xlabel('freq (hz)');title('Spectral filter');
ifilt=(ifft([filt;0;filt(end:-1:2)]));
subplot(212);plot(linspace(0,dur,len),fftshift(ifilt),'*-');
xlabel('time (s)');title('Temporal filter');

% with an interesting xscale..
mkFilter(10,{'P9' 'P10'},{'1' '2' '3' 'P9' 'P10'})
