function [di]=mkDimInfo(sz,varargin)
% Make a dimension info struct from the input information
%
% di = mkDimInfo(sz,name1,units1,vals1,name2,units2,vals2,...)
%  OR
% di = mkDimInfo(sz,{name1,name2,name3,...})
%  OR
% di = mkDimInfo(len,1,name1,units1,vals1)
%  to make the entry for just 1 dimension, i.e. without the element info
%
% N.B. we have nd+1 info structures as the nd+1th entry describes what the
%      *values* of each entry in the matrix contain
% Inputs:
%  sz     -- [nd x 1], size of the object to be described
%  name1  -- string, the name for dimension 1, ('')
%  units1 -- string, the units of dimension 1, ('')
%  vals1  -- matrix/cellarray etc, the list of values for each entry of
%            this dims matrix, ([1:sz(1)])
%  ...
% Outputs:
%  di      -- [ nd+1 x 1 ] structure array with the input info as a struct
%   |         array X's dimension info.  Containing:
%   |.name -- string name for this dimension
%   |.units-- units that dim is measured in
%   |.vals -- value in units of the corrospeding element of this
%   |         dimension of X
%   |.info -- extra useful information about this dimension
%   |.extra-- for each element along this dimension of X a struct
%             containing other useful information.
nd=numel(sz)+1; 
% no elem dim if not wanted
if( ~isempty(varargin) && isnumeric(varargin{1}) && isequal(varargin{1},1) ) 
   nd=numel(sz); varargin=varargin(2:end); % remove elem dim, and option
end; 
if ( numel(varargin)==1 && iscell(varargin{1}) && numel(varargin{1})>=nd-1 ) % set dimension names
   varargin((0:numel(varargin{1})-1)*3+1)=varargin{1}; % expand up to set of name/units/vals stuff
end
nd=max(ceil(numel(varargin)/3),nd); % varargin over-rides
sz(end+1:nd)=-1;

di=repmat(struct('name',[],'units',[],'vals',[],'info',[],'extra',[]),[nd,1]);
for i=1:nd;
   argIdx=(i-1)*3+1;
   if ( argIdx <= numel(varargin) && ~isempty(varargin{argIdx}) )
      di(i).name = varargin{argIdx};
   else
      di(i).name = '';
   end
   argIdx=(i-1)*3+2;
   if ( argIdx <= numel(varargin) && ~isempty(varargin{argIdx}) )
      di(i).units= varargin{argIdx};
   else
      di(i).units=''; 
   end;
   argIdx=(i-1)*3+3;
   if ( argIdx <= numel(varargin) && ~isempty(varargin{argIdx}) )
      if ( sz(i)>0 && (numel(varargin{argIdx})~=sz(i) && size(varargin{argIdx},2)~=sz(i)) )
         warning('%dth dimensions size info (%d) and vals size (%d) dont match',i,sz(i),numel(varargin{argIdx}));
      end
      di(i).vals = varargin{argIdx};
   else
      if ( i>numel(sz) || sz(i)==0 ) % values are real and hence have no vals
         di(i).vals=[];
      else
         di(i).vals=int32(1:max(1,sz(i)));  % default to row vectors
      end
   end;
   if( size(di(i).vals,1)>1 ) di(i).vals = di(i).vals'; end; % ensure row vector
   di(i).extra = repmat(struct(),1,numel(di(i).vals));
   if ( i <= numel(sz) ) di(i).extra = repmat(struct(),1,sz(i)); end;
end

if ( nargout > 1 ) % compute a summary string also
   szstr=sprintf('%d %ss',numel(di(d).vals),di(d).name);
   for d=2:numel(di);
      szstr=sprintf('%s x %d %ss',szstr,numel(di(d).vals),di(d).name); 
   end
   szstr=sprintf('[%s]\n',szstr);
end
return;
%------------------------------------------------------------------------
function testCase()
di=mkDimInfo([10 10 10],'ch','',[]);

% 1-d special case to make a single dimensions entry
di=mkDimInfo(10,1,'ch',[],{'h','e','l','l','o','t','h','e','r','e'});

% more dim names than size info
di=mkDimInfo([10 1],'ch',[],[],'time',[],[],'epoch',[],[],[],'mV');

% with a set of dim names only
di=mkDimInfo([10 1],{'ch' 'time' 'epoch' 'mV'});