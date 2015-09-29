function [str]=clsfr2txt(str,clsfr)
% convert a clsfr object into the ascii interchange format
%
%  [str]=mat2txt(str,clsfr)
if ( nargin<2 || isempty(str) ) 
  str='';
else % add double new line if not there
  if ( ~isempty(str) && ~strcmp(str(end-1:end),sprintf('\n\n')) )
	  str=[str sprintf('\n\n')];
  end
end

% Type
str=sprintf('%s\n#Type:\n%s',str,clsfr.type);

% fs
str=sprintf('%s\n#fSample:\n%f',str,clsfr.fs);

%----------------------
% detrend
str=sprintf('%s\n#detrend:\n%d',str,clsfr.detrend);

% isbadch
str=sprintf('%s\n#isbadch: (1x%d)\n',str,numel(clsfr.isbad));
if( isempty(clsfr.isbad) ) str=[str sprintf('[]')];
else                       str=[str sprintf('%d ',clsfr.isbad)]; 
end;

% spatialfilter
str=sprintf('%s\n\n\n#spatialfilter: (%dx%d)\n',str,size(clsfr.spatialfilt,1),size(clsfr.spatialfilt,2));
str=[str mat2txt([],clsfr.spatialfilt)];

% spectral filter
str=sprintf('%s\n\n#spectralfilt: (1x%d)\n',str,numel(clsfr.filt));
if ( isempty(clsfr.filt) ) str=[str '[]'];
else str=[str sprintf('%g ',clsfr.filt)];
end

% outsz
str=sprintf('%s\n\n#outsz:\n',str);
if ( isempty(clsfr.outsz) ) str=[str '[]'];
else str=[str sprintf('%g ',clsfr.outsz)];
end

% timeIdx
str=sprintf('%s\n\n#timeIdx: (1x%d)\n',str,numel(clsfr.timeIdx));
if ( isempty(clsfr.timeIdx) ) str=[str '[]'];
else str=[str sprintf('%d ',clsfr.timeIdx)];
end

%-------------------
% welch window
str=sprintf('%s\n\n#welch_taper: (1x%d)\n',str,numel(clsfr.windowFn));
if ( isempty(clsfr.windowFn) ) str=[str '[]'];
else str=[str sprintf('%g ',clsfr.windowFn)];
end

% welch ave type
str=sprintf('%s\n\n#welchAveType:\n',str);
if( isempty(clsfr.welchAveType) ) str=[str '[]'];
else                              str=[str clsfr.welchAveType];
end

% freqIdx
str=sprintf('%s\n\n#freqIdx: (1x%d)\n%s',str,numel(clsfr.freqIdx));
if ( isempty(clsfr.freqIdx) ) str=[str '[]'];
else str=[str sprintf('%d ',clsfr.freqIdx)];
end

%--------------------
% subProbDesc
str=sprintf('%s\n\n#subProbDesc: (1x%d)\n%s',str,numel(clsfr.spDesc),sprintf('%s ',clsfr.spDesc{:}));

% W
str=sprintf('%s\n\n\n#W: (%dx%dx%d)\n',str,size(clsfr.W,1),size(clsfr.W,2),size(clsfr.W,3));
str=mat2txt(str,clsfr.W);

% b
str=sprintf('%s\n\n#b: (1x%d)\n',str,numel(clsfr.b));
if ( isempty(clsfr.b) ) str=[str '[]'];
else str=[str sprintf('%g ',clsfr.b)];
end

% finished!
return;
%---------------------------------------------------------------------------------
function []=testCase();
feedback = struct('label','alpha',...
                  'freqband',[8 12],...
                  'electrodes',[1 2]); % don't forget double cell for struct
capFile = 'sigproxy';
overridechnms=1;
clsfr = train_nf_clsfr((64*2*1000)/100,feedback,'fs',100,'spatialfilter','none','capFile',capFile,'overridechnms',overridechnms,'width_ms',[],'width_samp',64); % force a power2 welch window
fid=fopen('../java/sigProc/res/clsfr_alpha_sigprox.txt','w');fprintf(fid,'%s',clsfr2txt([],clsfr));fclose(fid);
str=clsfr2txt([],clsfr)
