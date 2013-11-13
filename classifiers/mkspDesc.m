function [spDesc]=mkspDesc(spMx,spKey)
% build a string describing the sub-problems
%
% [spDesc]=mkspDesc(spMx,spKey)
%
% Inputs:
%  spMx - [nSp x nCls] sub-problem encoding/decoding matrix
%  spKey- [nCls x 1] labels/markers for each of the classes
% Outputs:
%  spDesc- [nSp x 1] cell array of strings describing the problems
if ( nargin<2 || isempty(spKey) ) spKey=1:size(spMx,2); end;
%if ( isequal(size(spMx),[1 2]) ) spMx=spMx'; end; % bin special case
for isp=1:size(spMx,1);
   pCls=find(spMx(isp,:)>0); nCls=find(spMx(isp,:)<0); desc='';
   if ( isnumeric(spKey) )
      desc='';
      if ( numel(pCls)>0 )
         desc=sprintf('%d',spKey(pCls(1))); 
         if(numel(pCls)>1) desc=[desc sprintf('+%d',spKey(pCls(2:end)))]; end;
      end
      desc=[desc ' v '];
      if ( size(spMx,2)>2 && numel(pCls)==1 && numel(nCls)+numel(pCls)==size(spMx,2) )
         desc=[desc 'R']; % it's 1vR so use that name
      else
         if ( numel(nCls)>0 )
            desc=[desc sprintf('%d',spKey(nCls(1)))];
            if(numel(nCls)>1) desc=[desc sprintf('+%d',spKey(nCls(2:end)))]; end;
         end
      end
   elseif ( iscell(spKey) )
      if ( isnumeric(spKey{1}) ) % sets of numbers
         desc=ivec2str(',',spKey{pCls(1)}); 
         for j=2:(numel(pCls)); desc=[desc ivec2str(',',spKey{pCls(j)})]; end;
         desc=[desc ' v '];
         if ( size(spMx,2)>2 && numel(pCls)==1 && numel(nCls)+numel(pCls)==size(spMx,2) )
            desc=[desc 'R'];
         elseif( numel(nCls)>0 )
            desc=[desc ivec2str(',',spKey{nCls(1)})]; 
            for j=2:(numel(pCls)); desc=[desc ivec2str(',',spKey{nCls(j)})]; end;
         end
      elseif ( isstr(spKey{1}) )
         desc=sprintf('%s',spKey{pCls(1)}); 
         if(numel(pCls)>1) desc=[desc sprintf('+%s',spKey{pCls(2:end)})]; end;
         desc=[desc ' v '];
         if ( size(spMx,2)>2 && numel(pCls)==1 && numel(nCls)+numel(pCls)==size(spMx,2)  )
            desc=[desc 'R'];
         elseif( numel(nCls)>0 )
            desc=[desc sprintf('%s',spKey{nCls(1)})];
            if(numel(nCls)>1) desc=[desc sprintf('+%s',spKey{nCls(2:end)})]; end;
         end
      end
   end
   spDesc{isp}=desc;
end
return;
function [str]=ivec2str(chr,vec); % pretty print vector of ints
if ( nargin < 2 ) vec=chr; chr=' '; end;
str='';
if(numel(vec)>1) 
   str=sprintf(['%d' chr],vec(1:end-1));
   str=['[' str sprintf('%d',vec(end)) ']'];
else
   str=sprintf('%d',vec);
end;
return;

%----------------------------------------------------------------
function testCases()
spDesc([1 -1;-1 1],{'LH' 'FT'})
