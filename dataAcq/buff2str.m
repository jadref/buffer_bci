function str=buff2str(str)
% convert from buffer string back to cell array of strings
if ( ischar(str) )
  nulls=find(str==char(9));
  if ( ~isempty(nulls) ) 
    tmp=str;nulls=[0 nulls];
    str={}; for i=1:numel(nulls)-1; str{i}=tmp(nulls(i)+1:nulls(i+1)-1);end;
    if ( numel(str)==1 ) str=str{:}; end; % single target is simple string?
  end
end
