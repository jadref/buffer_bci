function [ind,key,spMx]=lab2ind(Y,key,spMx,zeroLab,compBinp)
% Convert vector of labels to matrix of indicator functions.
%
% function [ind,key,spMx]=lab2ind(Y,key,subProb,zeroLab,compBinp)
%
% Inputs:
% Y       -- [N x 1] vector of labels
% key     -- [nClass x 1] set of column labels for spMx ([unique(Y)])
% subProb -- indicates which label used for each output column.
%            [N x 1] matrix of labels which are used in "1 vs Rest" style
%                    to indicate the positive class
%            OR
%            [nSp x nClass] sub-problem encodeing/decoding matrix of -1/0/+1 values.
%                      with 1 for when the corrospending class should be positive case, -1
%                      for when negative and 0 for when not used in this sub-prob
%                      e.g. Yi=lab2ind(Y,[1 -1 0;1 0 -1;0 1 -1]);
%            OR 
%            [nSp x 1] cell array of 2x1 numeric cell arrays 
%                      holding the negative then positive class label sets.
%                      e.g. Yi=lab2ind(Y,{{1 0} {2 0} {[1 2] [3 4]})
% zeroLab -- [bool], do we treat 0 as a valid label instead of indicate this
%            trial is excluded from consideration. (false)
% compBinp-- [bool], do we compress binary labels into 1 sub-problem? (true)
% Outputs:
% ind  -- [N x nSp] matrix of sub-problem +/-1 indicator functions
% key  -- [nClass x 1] list of class labels in order used in spMx 
%         (N.B. ascending sorted in label value for integer labels)
% spMx -- [nSubProb x nClass] -1/0/+1 matrix encoding the subProb->classLabel mapping
%           +1/-1 indicates class is positive/negative set for this sub-prob
%           0     indicates class is ignored for this sub-prob
%           N.B. to decode binary predictions use:
%                  dv([1 x nSubProb])*decMx -> [1 x nClass]
%            set of decision values which indicate the confidence in each
%            class.
%          OR
%            {nSp x 1} cell array of 2x1 cell arrays for each sub-problem, e.g. {sp1 sp2 sp3} 
%                      Each sub-problem cell array holds the negative then positive class label 
%                      sets, either as numbers which match the numbers in classIDs or as 
%                      strings which match the labels in classNms
if ( nargin < 5 || isempty(compBinp) ) compBinp=true; end;
if ( nargin < 4 || isempty(zeroLab) ) zeroLab=false; end;
if ( nargin < 3 || isempty(spMx) ) spMx='1vR'; end;
if ( nargin < 2 || isempty(key) ) % default key
   key=unique(Y(:)); key=key(:)'; 
   if( iscell(key) ) key=sort(key); else key=sort(key,1,'ascend'); end % ascending label order
   % if( ~isempty(spMx) && ~ischar(spMx) && ((iscell(spMx) && numel(spMx)~=numel(key)) || (size(spMx,2)~=numel(key))) )
   %    warning(sprintf('subProb matrix and unique in Y dont agree -- using key=1:%d',size(spMx,2)));
   %    key=1:size(spMx,2);
   % end
   if ( numel(key) > 50 ) warning('More than 50 labels!'); end
   % treat [1,-1], [1,0] as special case so Y is unchanged
   if ( isequal(key,[-1 1]) || ...
        (~zeroLab && isequal(key,[-1 0 1])) ||...
        ((zeroLab && isequal(key,[0 1])) || islogical(Y)) ) key=key(end:-1:1); 
   end; 
   if( ~zeroLab && isnumeric(key) ) key(key==0) = []; end % treat 0 label ignored
else
  zeroLab=true;
end
if ( ischar(Y) )    Y =single(Y); end;
if ( islogical(Y)) Y =single(Y); key=single(key); zeroLab=1; end;
if ( ischar(key) ) key=single(key); end;
key=key(:); % ensure key is col vector

% BODGE: deal with class limits of repop, i.e. it's unhappy with int32 etc...
if ( isnumeric(Y) && strncmp('int',class(Y),3) ) Y=single(Y); key=single(key); end
if ( isnumeric(key) && strncmp('int',class(key),3) ) key=single(Y); end; 

% decode the subProb spec 
nClass=numel(key); nSp=nClass;

% convert spMx into the correct spMx format if needed
if ( ~isnumeric(spMx) || ndims(spMx)~=2 || size(spMx,2)==1 )
  spMx=mkspMx(key,spMx,compBinp); 
end
nSp=size(spMx,1);
%deal with bin special case
if ( compBinp && nClass==2 ) nSp=1; end;

% special case for the no class distinction case
if ( nClass<2 && nSp==1 && (isnumeric(Y) && all(Y==Y(1))) ) ind=ones(size(Y)); return; end;

% build the actual sub-problem indicator matrix
ind=single(zeros(numel(Y),nSp));
if ( isnumeric(Y) )
  for spi=1:size(spMx,1);
    if ( isnumeric(key) )
      ind(any(repop(Y(:),'==',key(spMx(spi,:)>0)'),2),spi)=1;      
      ind(any(repop(Y(:),'==',key(spMx(spi,:)<0)'),2),spi)=-1;
    elseif ( iscell(key) )
      for ci=find(spMx(spi,:)>0); ind(any(repop(Y(:),'==',key{ci}(:)'),2),spi)=1; end;      
      for ci=find(spMx(spi,:)<0); ind(any(repop(Y(:),'==',key{ci}(:)'),2),spi)=-1; end;      
    end
  end
else % deal with cell inputs
  for i=1:numel(Y);
    for ikey=1:numel(key);
      if ( isequal(Y{i},key{ikey}) ) ind(i,:)=spMx(:,ikey); end;
    end;
  end
end
if( ~zeroLab && isnumeric(Y) ) ind(Y(:)==0,:) = 0; end % treat 0 label as special case
szY=size(Y); if( ndims(Y)==2 && size(Y,2)==1) szY=szY(1); end;
ind=reshape(ind,[szY nSp]);
return;
%-----------------------------------------------------------------------------
function testCase();
Y=ceil(rand(100,1)*9.9); % 1-10 labels
clf;plot(Y); hold on;
Yi=lab2ind(Y); [a b]=max(Yi,[],2); plot(b,'r')
prm=randperm(10); [Yi,key,spMx]=lab2ind(Y,prm); [a b]=max(Yi,[],2); plot(prm(b),'g')

% test with spec subprob
for i=1:10; subProb{i}={i [1:i-1 i+1:10]}; end;
[Yi,key,spMx]=lab2ind(Y,subProb); [a b]=max(Yi,[],2); plot(b,'c');

% test with spMx spec subProb
spMx=-ones(10,10); spMx(1:size(spMx,1)+1:end)=1;
[Yi,key,spMx]=lab2ind(Y,spMx); [a b]=max(Yi,[],2); plot(b,'m');

% test with matrix inputs
Y=ceil(rand(100,2)*9.9); % 1-10 labels
[Yi,key,spMx]=lab2ind(Y);

% test with 0-1 inputs
Y=floor(rand(100,1)*1.9); % 0-1 labels
[Yi,key,spMx]=lab2ind(Y,[],1);

% test with binary as special case
Y=floor(rand(100,1)*1.9)*2-1;
[Yi,key,spMx]=lab2ind(Y);

% test with int as inputs
[Yi,key,spMx]=lab2ind(int8(Y));

% test with cell array of strings as input
Y={'left' 'left' 'right' 'right'};
[Yi,key,spMx]=lab2ind(Y);

% test with strings as input and spType spect
Y={'left' 'left' 'right' 'right' 'rest' 'rest'}';
[Yi,key,spMx]=lab2ind(Y,{'left' 'right' 'rest'},{{'left' 'right'} {{'left' 'right'} {'rest'}}});

% test with binary input and non-compression of output
Yi=lab2ind(sign(randn(100,1)),[],[],[],0); size(Yi,2)==2
