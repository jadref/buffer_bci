classdef BonusAlien < handle
    % Class for generating an bonus alien.
    
    %% Properties:
    
  properties (Constant)
    relSpawnBox = [.1 .1 .8 .8]; % [l b w h] rectangle for the spawn box for the bonus alien
    relSpawnSize= .1;
    alienLifeTime = 3; % time-alien is on screen to be killed
    minuid = 128;
    color       = 'k'; 
  end
    
    
  properties
    x;                   % X pos of *center* of the alien.
    y;                   % Y pos of *center* of the alien.
    alienSize;           % Alien size.
    hGraphic;            % handle to alien graphics object.
    hAxes;               % handle to axes.
    alienSpawnTime;      % logs the alien spawn time.
    uid; % unique identifier for this alien
  end
    
  %% Methods:
  
  methods
            
          %==================================================================
    function obj = BonusAlien(hAxes,hCannon)
      Ylim=get(hAxes,'Ylim'); Xlim=get(hAxes,'Xlim');
      obj.y = Ylim(1)+(obj.relSpawnBox(2)+rand(1)*obj.relSpawnBox(4))*diff(Ylim);
      obj.x = Ylim(1)+(obj.relSpawnBox(1)+rand(1)*obj.relSpawnBox(3))*diff(Xlim);
      obj.alienSize=obj.relSpawnSize*min(diff(Ylim),diff(Xlim));
      obj.hAxes = hAxes;
      
                                % Draw alien 
      obj.hGraphic = rectangle('curvature',[0.9 0.9]...
                               ,'facecolor',obj.color...
                               ,'parent',hAxes...
                               ,'position',[obj.x-obj.alienSize/2,obj.y-obj.alienSize/2,obj.alienSize,obj.alienSize]...
                               ,'visible','off');
      obj.uid = Alien.getuid();
      obj.alienSpawnTime = tic;
    end
        
        
          %==================================================================
    function deleteAlien(obj)
      delete(obj.hGraphic);
    end                                       
  end

  methods(Static)

          %==================================================================
    function hAliensOut = update(hAliensIn)
      if isempty(hAliensIn);
        hAliensOut = [];%Alien.empty;
        return
      end
                                % Loop through aliens:
      for ai=1:numel(hAliensIn);
        obj = hAliensIn(ai);
        if~ishandle(obj.hGraphic)
          continue
        end
        if( toc(obj.alienSpawnTime) >= obj.alienLifeTime )
          obj.deleteAlien();
          continue;
        end
      end
                                % remove deleted objects
      keep=true(1,numel(hAliensIn)); for bi=1:numel(hAliensIn); if( ~ishandle(hAliensIn(bi).hGraphic) ) keep(bi)=false; end; end; hAliensOut = hAliensIn(keep);
    end
    
                          % get a unique idenification number for this object
    function nuid=getuid()
      persistent uid;
      if(isempty(uid))uid=BonusAlien.minuid;end; % Aliens always >128 (bit 8 set)
      uid=uid+1;
          nuid=uid;
    end
    
  end
end

