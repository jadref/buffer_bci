function [Z]=repopm(varargin)
% Replicating arithemetical and logical operators -- MATLAB fallback code
%
% [Z]=repop(X,operator,Y [,options])
%
% N.B. Fallback raw matlab based implement of the repop-mex code.  This version 
% is generally slower and more memory intensive and is provided as a fallback method if
% the compilied version is not available.
%
% Does element by element operations on X and Y where non-same sized
% dimensions are implicity wrapped round to match the size of the larger
% to give a result matrix Z with size max(size(X),size(Y));
%
% What this means is that if you give a [Nx1] and a [1xM] input you get 
% a [NxM] output, or if you give it a [Nx1xQ] and a [NxMx1xP] you get 
% [NxMxQxP] output etc..  
% Note that the size of the input *completely and uniquely* determines the 
% size of the output.
%
% In general this is at least 2x faster than the equivalent matlab code
% using repmats and has the advantage of requiring no additional memory.
%
% Example Usage:
%     X = randn(10000,10);                  % example signal with data in rows
%     stdX = repop(X,'-',mean(X,1));        % subtract the mean vector
%     stdX = repop(stdX,'/',std(stdX,0,1)); % divide by std-deviation
%
% Operator can be one of:
%
% Arthemetical -- returns a double matrix
%   '+','.+',plus   - Implicitly repmatted elementwise addition
%   '-','.-',minus  - Implicitly repmatted elementwise addition
%   '*','.*',times  - Implicitly repmatted elementwise multiplication
%   '^','.^',power  - Implicitly repmatted elementwise raise X to power Y
%   '\','.\',ldivide- Implicitly repmatted elementwise divide Y by X
%   '/','./',rdivide- Implicitly repmatted elementwise divide X by Y
%   'min'           - Implicitly repmatted elementwise min of X by Y
%   'max'           - Implicitly repmatted elementwise max of X by Y
%
% Relational -- returns a logical matrix
% N.B. for complex inputs the <,>,<=,>= operators are based upon abs(x) 
% (not real(x) as in matlab)
%   '==',eq         - Implicitly repmatted elementwise equality
%   '~=',ne         - Implicitly repmatted elementwise dis-equality
%   '<' ,lt         - Implicitly repmatted elementwise less than
%   '>' ,gt         - Implicitly repmatted elementwise greater than
%   '<=',le         - Implicitly repmatted elementwise less than equal
%   '>=',ge         - Implicitly repmatted elementwise greater than equal
%
% N.B. the operator can go in any of the 3 argument positions, i.e.
% these are all valid: repop(X,'-',Y), repop(X,Y,'-'), repop('-',X,Y)
%
% The optional final argument is a string of single letter switches
% consisting off
%  'm'  -- allows replication of non-unit dimensions if the larger
%          dimensions size is an integer multiple of the smaller ones
%  'n'  -- allow replication of non-unit dimensions in *all* cases
%  'i'  -- perform "inplace" operation.  This means that we use a
%          *dangerous* matlab *hack* to perform the operation *without*
%          allocating new memory for the output, but by simply overwriting
%          the memory used for X in the input.  Thus the following code is
%          a memory (and time) efficient way to increment X.
%              X = repop(X,'+',1,'i');
%
%
% Class support of input P:
%     float: double, single
% 
% SEE ALSO:   repop_testcases 
%             bsxfun -- matlab builtin equivalent function R2008 and later

if ( nargin<3 ) error('Insufficient Arguments'); end;
Z=[];
if ( ischar(varargin{1}) || isa(varargin{1},'function_handle') )
  op=varargin{1}; A=varargin{2}; B=varargin{3};
else
  A =varargin{1}; op=varargin{2};B=varargin{3};
end
if ( ischar(op) ) 
   if ( any(strcmp(op,{'*','/','^'})) ) op=['.' op]; end; % ensure elementwise version is used
   op=str2func(op); 
end;

% use the matlab based builtin equivalent if available
if ( numel(A)==1 || numel(B)==1 ) % scalar case
  Z=feval(op,A,B);
elseif ( exist('bsxfun','builtin') && ~exist('OCTAVE_VERSION','builtin') ) % matlab R2008 or later
  Z=bsxfun(op,A,B);
else % older matlabs
  szA=size(A);
  szB=size(B);
  nd =max(numel(szA),numel(szB));
  szA(end+1:nd)=1; szB(end+1:nd)=1;
  if ( (any(szA(szB>szA)>1) || any(szB(szA>szB)>1)) && ~(nargin>3 && strcmp(varargin{3},'m')) )
    warning('REPOP:Replicating a non-unit dimension! -- if you *really* meant this use the ''m'' or ''n'' options');
    return;
  end
  repA=max(1,szB./szA); 
  repB=max(1,szA./szB);
  Z = op(repmat(A,repA),repmat(B,repB));
end
return;

%--------------------------------------------------------- test code ----------------------
function testCases()
sz=101;
X=randn(sz,sz+1,sz+2);Y=randn(size(X));
tic,Z=repop(X,'-',Y(:,1));toc=t;
tic,Zm=repopm(X,'-',Y(:,1));toc=tm;
fprintf('err=%g,mex=%g mat=%g\n',mad(Z,Zm),t,tm)

% test error for non-unit replication
tic,Z=repop(X,'-',Y(1,:));toc=t;
tic,Zm=repopm(X,'-',Y(1,:));toc=tm;
fprintf('err=%g,mex=%g mat=%g\n',mad(Z,Zm),t,tm)
