function [varargout]=parseOpts(opts,varargin)
% parse a (set of) options structures and return the (set of) filled in values
% and the set of unrecognised input options
% [opts1,opts2,...,rest]=parseOpts({opts1,opts2,...},varargin)
% Inputs:
%  opts1 -- a structure containing the parameters with their default values.
%  opts2 -- a second structure with more defaults to fill in
%  ...   -- more structures with defaults to fill in
%  varargin -- the stuff you want to parse.  This can be as:
%           name,value -- pairs of option names and new values
%           cell-array -- of pairs of names,values
%           struct     -- with fieldnames and values to use
% Outputs:
%  opts1 -- filled in default structures, where matched fields in opts1
%  opts2 -- filled in option structure, where matched fields in opts2
%  ....
%  rest  -- unrecognised name,value pairs for passing to other functions
%           N.B. if rest is not specified then,
%                      *Unrecognised options produce a warning*.
% Example Usage:
%    opts=struct('par1',10,'par2',20);
%    opts=parseOpts(opts,'par1',50); % parse, error if unrec options
%    [opts,unrecOpts]=parseOpts(opts,'par1',50,'par3',30); % return unused options
%    opts2=struct('par3',20);
%    [opts,opts2]=parseOpts({opts,opts2},'par1',50,'par3',30); % >1 default struture
%    opts=parseOpts(opts,{'par1' 20}); % cell-array of opts
%    opts=parseOpts(opts,struct('par1',20)); % struct of opts
%    opts=parseOpts(opts,{'par1' 20},'par1',50); % mixed-inputs and left->right assignment order
%
% Copyright 2006-     by Jason D.R. Farquhar (jdrf@zepler.org)

% Permission is granted for anyone to copy, use, or modify this
% software and accompanying documents for any uncommercial
% purposes, provided this copyright notice is retained, and note is
% made of any changes that have been made. This software and
% documents are distributed without any warranty, express or
% implied
if ( ~iscell(opts) ); opts={opts}; end;
subStruct=false; % in sub-structs we can create fields without penalty
if(iscell(varargin) && numel(varargin)>1 && islogical(varargin{1})); subStruct=varargin{1};varargin(1)=[];end;
if ( iscell(varargin) && numel(varargin)==1 && iscell(varargin{1})); varargin=varargin{1}; end; % expand single inputs
i=1; unrec=[];
%for i=1:numel(varargin);
while i<=numel(varargin);  % while still options to consume
   if ( iscell(varargin{i}) ) % flatten cells
      %varargin={varargin{1:i-1} varargin{i}{:} varargin{i+1:end}};
      [opts{:},varargin{i}]=parseOpts(opts,varargin{i}{:});
      if ( ~isempty(varargin{i}) );  unrec(end+1)=i; end
   elseif ( isstruct(varargin{i}) )% flatten structures
      cellver=[fieldnames(varargin{i}) struct2cell(varargin{i})]';
      %varargin={varargin{1:i-1} cellver{:} varargin{i+1:end} };
      [opts{:},tmp]=parseOpts(opts,cellver{:}); 
      varargin{i}=struct(tmp{:}); if ( ~isempty(tmp) );  unrec(end+1)=i; end
   elseif ( ischar(varargin{i}) )
      fn=varargin{i}(1:min([find(varargin{i}=='.',1)-1,end]));
      sfn=varargin{i}(numel(fn)+2:end); % deal with name.subname
      for j=1:numel(opts); % assign fields, opts
         if( isfield(opts{j},fn) ) 
            if ( isstruct(opts{j}.(fn)) ) % recurse into sub-structs
               if ( ~isempty(sfn) )
                  tmp=parseOpts(opts{j}.(fn),true,sfn,varargin{i+1});
               elseif( isstruct(varargin{i+1}) || iscell(varargin{i+1}) ) 
                  tmp=parseOpts(opts{j}.(fn),true,varargin{i+1});
               else
                 tmp=varargin{i+1};
               end
            elseif( ~isempty(sfn) ) % make a sub-struct
               tmp=varargin{i+1}; 
               if( iscell(tmp) ); tmp={tmp}; end;
               tmp=struct(sfn,tmp);
            else
               tmp=varargin{i+1};
            end
            opts{j}.(fn)=tmp; i=i+1; j=0; break;
         elseif ( subStruct && numel(opts)==1 ) % make new field in sub-structs
           if ( ~isempty(sfn) ) % make sub-struct
             tmp=varargin{i+1}; if( iscell(tmp) ); tmp={tmp}; end;             
             tmp=struct(sfn,tmp);
           else
             tmp=varargin{i+1};
           end;
           opts{j}.(fn)=tmp; i=i+1; j=0; break;
         end
      end      
      % record the unrec options
      if ( j>0 ); unrec(end+1)=i; if(i<numel(varargin)); i=i+1; unrec(end+1)=i;end; end 
   else
      unrec(end+1)=i;  % skip this unrecognised argument
   end
   i=i+1;
end
if ( nargout<=numel(opts) && ~isempty(unrec) )
   str='';
   for i=1:numel(unrec); % make a useful warning string
      if ( ischar(varargin{unrec(i)}) ); str=[str sprintf('#%d=''%s'',',unrec(i),varargin{unrec(i)})]; 
      else str=[str sprintf('#%d=<%s>,',unrec(i),class(varargin{unrec(i)}))];
      end
   end
   warning('Unrecognised Option(s) [%s] ignored! ',str);
end
varargout={opts{:} varargin(unrec)}; % return the unrecognised options
return;

%-------------------------------------------------------------------------
% testcases
function []=testCases()
s1=struct('help','me');s2=struct('test','me');
r1=parseOpts(s1,{'help','them'});
[r1 r2]=parseOpts({s1,s2},[])
[r1 r2]=parseOpts({s1,s2},'squared','bollocks')  % -- fails as pos only for first struct
[r1 r2]=parseOpts({s1,s2},'help','them')
[r1 r2]=parseOpts({s1,s2},'test','them')
[r1 r2]=parseOpts({s1,s2},'test','them')
[r1 r2]=parseOpts({s1,s2},'test',{'them'})
[r1 r2]=parseOpts({s1,s2},'test','them',struct('help','jason'))
[r1 r2]=parseOpts({s1,s2},'help','jason','test','anna')
[r1 r2]=parseOpts(struct('substruct',struct('hello','there')),'substruct',struct('hello','me'))
[r1 r2]=parseOpts(struct('substruct',struct('hello','there'),'subs',1),'substruct',[])
[r1 r2]=parseOpts(struct('substruct',struct('hello','there')),'substruct.hello','me')
[r1 r2]=parseOpts(struct('test','me'),struct('hi','there')), % unrec returned unchanged
[r1 r2]=parseOpts(struct('test','me'),{'hi','there'})        % unrec returned unchanged
[r1 r2]=parseOpts(struct('test','me'),struct('test','them','foo','bar')), % removal of recog options
[r1 r2]=parseOpts(struct('test','me'),{'test','them','foo','bar'}), % removal of recog options
[r1 r2]=parseOpts(struct('test','me'),'test.p1',1,'test.p2',2)
