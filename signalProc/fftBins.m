function [freqs]=fftBins(L,dur,fs,posOnly)
% compute the frequency bins for fft output
% 
%  [freqBins]=fftBins(L,dur [,fs,posOnly])
% Inputs:
%  L   -- [int] the length of the input signal
%  dur -- [float] the temporal duration of the input signal
%  fs  -- [float] the sample rate of the input signal
%  posOnly -- [bool] return pos+neg frequencies or only positive (0)
% Outputs:
%  freqBins -- the center frequencies of the fft output spectrum
%              N.B. + and - freqs
if ( nargin < 2 ) dur=[]; end;
if ( nargin < 4 || isempty(posOnly) ) posOnly=0; end;
if ( nargin > 2 && ~isempty(fs) )
   if ( isempty(dur) ) dur   = L/fs;
   elseif ( isempty(L) ) L = round(fs*dur);
   end
end
if ( isempty(dur) ) dur=1; end;
freqs = [0 1:floor(L/2) -floor(L/2)+(mod(L+1,2)):-1]/dur;
if ( posOnly ) freqs=freqs(1:floor(L/2)+1); end;
return;
%--------------------------------------------------------------------
function testCase()
plot(fftBins(101,2))
plot(fftBins(100,2))
plot(fftBins(100,[],50))

