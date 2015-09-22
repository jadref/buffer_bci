function [str]=clsfr2txt(str,clsfr)
% convert a clsfr object into the ascii interchange format
%
%  [str]=mat2txt(str,clsfr)
if ( nargin<2 ) 
  str=[];
else % add double new line if not there
  if ( ~isempty(str) && ~strcmp(str(end-1:end),sprintf('\n\n')) )
	  str=[str sprintf('\n\n')];
  end
end
% Type
str=sprintf('%s\n#Type:\n%s',str,clsfr.type);
% fs
str=sprintf('%s\n#fSample:\n%f',str,clsfr.fs);
% detrend
str=sprintf('%s\n#detrend:\n%d',str,clsfr.detrend);
% isbadch
str=sprintf('%s\n#isbadch: (1x%d)\n%s',str,numel(clsfr.isbad),sprintf('%d ',clsfr.isbad));
% spatialfilter
str=sprintf('%s\n\n\n#spatialfilter: (%dx%d)\n%s',str,size(clsfr.spatialfilt,1),size(clsfr.spatialfilt,2),mat2str([],clsfr.spatialfilt));
% spectral filter
str=sprintf('%s\n\n#spectralfilt: (1x%d)\n%s',str,numel(clsfr.filt),sprintf('%g ',clsfr.filt));
% outsz
str=sprintf('%s\n\n#outsz:\n%d %d',str,clsfr.outsz);
% timeIdx
str=sprintf('%s\n\n#timeIdx: (1x%d)\n%s',str,numel(clsfr.timeIdx),sprintf('%d ',clsfr.timeIdx));
% welch window
str=sprintf('%s\n\n#welch_taper: (1x%d)\n%s',str,numel(clsfr.windowFn),sprintf('%g ',clsfr.windowFn));
% welch ave type
str=sprintf('%s\n\n#welchAveType:\n%s',str,clsfr.welchAveType);
% freqIdx
str=sprintf('%s\n\n#freqIdx: (1x%d)\n%s',str,numel(clsfr.freqIdx),sprintf('%d ',clsfr.freqIdx));
% subProbDesc
str=sprintf('%s\n\n#subProbDesc: (1x%d)\n%s',str,numel(clsfr.spDesc),sprintf('%s ',clsfr.spDesc{:}));
% W
str=sprintf('%s\n\n\n#W: (%dx%dx%d)\n',str,size(clsfr.W,1),size(clsfr.W,2),size(clsfr.W,3));
for spi=1:size(clsfr.W,3);
	 str=mat2txt(str,clsfr.W(:,:,spi));
end
% b
str=sprintf('%s\n\n#b: (1x%d)\n%s',str,numel(clsfr.b),sprintf('%g ',clsfr.b));
% finished!
return;
%---------------------------------------------------------------------------------
function testCase();
feedback = struct('label','alphaL',...
                  'freqband',[8 12],...
                  'electrodes',{{'FP2'}}); % don't forget double cell for struct
capFile = 'muse';
overridechnms=1;
clsfr = train_nf_clsfr(1000,feedback,[],'spatialfilter','none','capFile',capFile,'overridechnms',overridechnms);
clsfr2txt([],clsfr)
