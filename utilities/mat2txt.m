function [str]=mat2txt(str,mat)
% convert a matlab matrix into the java ascii format
%
%  [str]=mat2java(str,mat)
if ( nargin<2 ) 
  str=[];
else % add double new line if not there
  if ( ~isempty(str) && ~strcmp(str(end-1:end),sprintf('\n\n')) )
	  str=[str sprintf('\n\n')];
  end
end
if ( isempty(mat) ) str=[str sprintf('[]')]; return; end;
for zi=1:size(mat(:,:,:),3);
	 for j=1:size(mat,1); % each row on it's own line
		str=[str sprintf('%g\t',mat(j,1:end-1,zi)) sprintf('%g',mat(j,end,zi)) sprintf('\n')];
	 end
	 if ( zi<size(mat(:,:,:),3) )
		str=[str sprintf('\n\n')]; % two empty lines between 2d slices
	 end
end
return;
function testCase()
str=mat2java(randn(10,3));
str=mat2java(randn(1,2,3));
fid=fopen(fullfile('res','sigproxy_alphaW.csv'),'w');fprintf(fid,str);fclose(fid);
