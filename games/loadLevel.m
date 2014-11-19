function [map,agents,key]=loadLevel(fname,type)
if ( nargin<2 || isempty(type) ) type='pacman'; end;
switch(type);
 case 'pacman';
   key=struct('empty',0,'wall',2,'pellet',3,'powerpellet',4,'ghostbox',5,'ghostdoor',6,'pacman',7,'ghost',8);
 case 'sokoban';
  key=struct('empty',0,'wall',2,'block',3,'goal',4,'man',7);
 case 'snake';
  key=struct('empty',0,'wall',2,'pellet',3,'powerpellet',4,'snakehead',7,'snakebody',8);
 otherwise
  error(sprintf('unrec level type: %s',type));
end
map=[]; agents=[];
fid=fopen(fname,'r');
if (fid==-1)
  error('Cannot open source file :', fname);
end
char=fscanf(fid,'%c');   
fclose(fid);

maxx=[];
xi=0;yj=1; ci=0;
while ci<numel(char)
  ci=ci+1;
  if int32(char(ci))==10 || int32(char(ci))==13 % This occurs at the end of a line
    ci=ci+1; % Just read the next character
    if ( ci>numel(char) ) break; end; % check for eof
    if ( int32(char(ci))==10 ) ci=ci+1; end; %skip \l on windows
    if ( ci>numel(char) ) break; end; % check for eof
    if ( isempty(maxx) ) maxx=xi; 
    elseif ( xi~=maxx ) 
      warning('Unequal row lengths!');
      % pad out rest with empties
      if ( xi<maxx ) map(xi+1:end,yj)   =key.empty;
      else           map(maxx+1:xi,1:yj)=key.empty;
      end
    end
    % reset x/y indicator
    xi=1;
    yj=yj+1;
  else
    xi=xi+1; % next col to process
  end
  if ( strcmp(type,'sokoban') )
    switch char(ci);
     case {' ','V','N','0'}; map(xi,yj)=key.empty;       % empty track
     case {'-','|','W','1'}; map(xi,yj)=key.wall;        % wall
     case {'B'};             map(xi,yj)=key.empty;       agents(xi,yj)=key.block; % block
     case {'C'};             map(xi,yj)=key.empty;       agents(xi,yj)=key.man;   % pacman
     case {'G'};             map(xi,yj)=key.goal;        % ghost
     otherwise; error(sprintf('Level: %s:%d - Unrecog map spec: %c',fname,ci,char(ci)));
    end
  elseif ( strcmp(type,'snake') )
    switch char(ci);
     case {'.','T'};         map(xi,yj)=key.empty;       agents(xi,yj)=key.pellet;      % normal pellet
     case {' ','V','N','0'}; map(xi,yj)=key.empty;       % empty track
     case {'P','*'};         map(xi,yj)=key.empty;       agents(xi,yj)=key.powerpellet; % power pellet
     case {'-','|','W','1','B'}; map(xi,yj)=key.wall;    % wall
     case {'C'};             map(xi,yj)=key.empty;       agents(xi,yj)=key.snakehead; % snake-head
     case {'S'};             map(xi,yj)=key.empty;       agents(xi,yj)=key.snakebody; % snake-body
     otherwise; error(sprintf('Level: %s:%d - Unrecog map spec: %c',fname,ci,char(ci)));
    end    
  elseif ( isempty(type) || strcmp(type,'pacman') )
    switch char(ci);
     case {'.','T'};         map(xi,yj)=key.pellet;      % normal pellet
     case {' ','V','N','0'}; map(xi,yj)=key.empty;       % empty track
     case {'P','*'};         map(xi,yj)=key.powerpellet; % power pellet
     case {'-','|','W','1','B'}; map(xi,yj)=key.wall;        % wall
     case {'X'};             map(xi,yj)=key.ghostbox;    % ghostbox
     case {'D'};             map(xi,yj)=key.ghostdoor;   % ghostbox door
     case {'C'};             map(xi,yj)=key.empty;       agents(xi,yj)=key.pacman; % pacman
     case {'G'};             map(xi,yj)=key.empty;       agents(xi,yj)=key.ghost; % ghost
     otherwise; error(sprintf('Level: %s:%d - Unrecog map spec: %c',fname,ci,char(ci)));
    end
  end
end
if ( xi~=size(map,1) || yj~=size(map,2) )
  error('non-rectangular map detected');
end
if ( isnumeric(agents) && ~all(size(agents)==size(map)) ) agents(size(map,1),size(map,2))=0; end

%---------------------------------------------------------
function testCase()
[map,key]=loadmap('level1.lv');