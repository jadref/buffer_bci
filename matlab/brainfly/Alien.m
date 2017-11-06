classdef Alien < handle
                                % Class for generating an alien.
  
  
  %% Properties:
  
  properties (Constant)
    
          % 'rel' indicates that a the properties is a fractions of the
          % screen width or height, these properties are used to generate the
          % actual sized at object instantiation:
    relStartLine      = 0.9;
    fallDuration      = 9; % 9s to fall down the screen
    relAlienStartSize = 0.05;  % The start size of the alien.
    alienGrowExp      = 1.5;   % The time exponent of the growth rate.
    %relAlienGrowRate  = (.5-Alien.relAlienStartSize)./(Alien.fallDuration.^Alien.alienGrowExp); % The growth rate of the alien, should be size .5 by end fall
    relAlienGrowRate  = (.5-0.05)./(9.^1.5); % The growth rate of the alien, should be size .5 by end fall
    relSpawnDelta     = .3;   % fraction of screen to spawn the new alien
           % NOTE: Aliens sometimes grow exponentially, so their sizes are
           % calculated as:
           %
           % alienSize = (startSize + alienAge^alienGrowExp)*relAlienGrowRate
    minuid = 256;
  end  
  
  properties
    x;                   % X pos of *center* of the alien.
    y;                   % Y pos of *center* of the alien.
    alienSize;           % Alien size.
    hGraphic;            % handle to alien graphics object.
    hLineGraphic;
    hAxes;               % handle to axes.
    alienSpawnTime;      % logs the alien spawn time.
    % linear equation for moving the aliens
    relstartx;           % starting x/y postion
    relstarty;
    relvelx;             % relative movement velocity
    relvely;
    shotsToKill;
    hCannon;
    flash;
    uid; % unique identifier for this alien
  end
  
  %% Methods:
  
  methods
        
          %==================================================================
    function obj = Alien(hAxes,hCannon)
                                % Constructs an alien.
      
                                % Save properties:
      Ylim=get(hAxes,'Ylim');
      obj.relstarty = obj.relStartLine;
      obj.relvely   = (0-obj.relStartLine)/obj.fallDuration;
      obj.y         = Ylim(1) + (obj.relstarty + obj.relvely*0)*range(Ylim);
      obj.hAxes = hAxes;
      obj.hCannon = hCannon;
      obj.flash = 3;
                                % Draw alien and forcefield:
      genLine = @() line([NaN NaN],[NaN NaN],'Color','r'...
                         ,'LineStyle',':'...
                         ,'LineWidth',3); 
      obj.hLineGraphic = genLine();
      obj.hGraphic = rectangle(...
                                'curvature',[0.9 0.9]...
                                ,'facecolor','g'...
                                ,'parent',hAxes...
                                ,'position',[10,10,1,1]...
                                ,'visible','on');
      obj.uid = Alien.getuid();
      obj.randomlyPlaceAlien;
    end
    
    
          %==================================================================
    function hit(obj)
      obj.deleteAlien();            
    end
    
    
          %==================================================================
    function randomlyPlaceAlien(obj)
                % randomly respawns the alien somwehere within the axes lims.
      
                                       % Set random size and position:
      spawnSeq= Alien.getsetSpawnSeq();
      if( ~isempty(spawnSeq) ) % use given sequence
                               % get next one from the sequence
        relxloc = spawnSeq(mod(obj.uid(),numel(spawnSeq)-1)+1);
      else % randomly spawn loc
        relxloc=Alien.getsetLastSpawnLoc();
        if ( isempty(relxloc) ) relxloc=rand(1); end;
        relxloc= relxloc + ((rand(1)>.5)*2-1)*obj.relSpawnDelta; 
      end
      
      relxloc= min(max(0,relxloc),1);
      Alien.getsetLastSpawnLoc(relxloc);
      obj.relstartx = relxloc;

                          % compute the ending location and movement velocity
      relxend=.25; if( obj.relstartx>=.5 ) relxend = .75; end; % .25 or .75 end-pos
      obj.relvelx   = (relxend-obj.relstartx)./obj.fallDuration;
      
      
      obj.alienSize = obj.relAlienStartSize*range(get(obj.hAxes,'Ylim'));
      XLims      = get(obj.hAxes,'Xlim');
      obj.x      = XLims(1) + (obj.relstartx + obj.relvelx*0)*range(XLims);
      
      set(obj.hLineGraphic,'XData',get(obj.hAxes,'Xlim'));
      waistY = obj.y;
      
                                % update alien graphic, and spawn time:
      set(obj.hLineGraphic(1),'YData',[waistY waistY]);
      set(obj.hGraphic,'position',[obj.x-obj.alienSize/2,obj.y-obj.alienSize/2,obj.alienSize,obj.alienSize]);
      obj.alienSpawnTime = tic;
      
    end
    
    
  %==================================================================        
    function deleteAlien(obj)
                       % Deletes the ball graphic, and the CannonBall object.
      
      delete(obj.hGraphic);
      delete(obj.hLineGraphic);
                                %delete(obj);
      
    end

    
    
  end

  methods(Static)
    function ss=getsetSpawnSeq(ss)
      % Yuck! horrible MATLAB hacks to get static values in a function...
      persistent spawnSeq;
      if(nargin>0) spawnSeq=ss; end;
      ss=spawnSeq;
    end
    
    function outxloc=getsetLastSpawnLoc(inxloc)
      persistent xloc; 
      if( nargin>0 ) xloc=inxloc; end; 
      outxloc=xloc;
    end
    
    function flashAlien(hAliensIn,objFlashes)
       obj = hAliensIn(1) 
       set(obj.hGraphic,'facecolor','y');
       obj.flash = objFlashes;
    end
          %==================================================================
    function [hAliensOut, cannonKills] = updateAliens(hAliensIn)
      
      cannonKills = 0;
      if isempty(hAliensIn);
        hAliensOut = [];%Alien.empty;
      end
      
                                % Loop through aliens:
      for ai=1:numel(hAliensIn);
        obj = hAliensIn(ai);
        
        if~ishandle(obj.hGraphic)
          continue
        end
        Ylim = get(obj.hAxes,'Ylim');
        Xlim = get(obj.hAxes,'Xlim');
                                % update the alien position and size
        obj.alienSize = (obj.relAlienStartSize...
                         +(toc(obj.alienSpawnTime)^obj.alienGrowExp)...
                          *obj.relAlienGrowRate)...
                        *range(Xlim);
        obj.y      = Ylim(1) + (obj.relstarty + obj.relvely*toc(obj.alienSpawnTime))*range(Ylim);
        %obj.x      = Xlim(1) + (obj.relstartx + obj.relvelx*toc(obj.alienSpawnTime))*range(Xlim);        
        waistY = obj.y;
        
                                % kill alien if hit cannon.....
        if obj.x+obj.alienSize>obj.hCannon.Xbase...
           && obj.x<obj.hCannon.Xbase+obj.hCannon.cannonWidth
          if obj.y<obj.hCannon.Ybase+obj.hCannon.cannonHeight
                                %obj.deleteAlien();
                                %cannonKills = cannonKills+1;
                                %continue
          end
        end
                                % kill cannon if pass the middle of the alien
        if waistY<obj.hCannon.Ybase+obj.hCannon.cannonHeight
          obj.deleteAlien();
          cannonKills = cannonKills+1;
          continue
        end

                                % update alien graphic, and spawn time:
        set(obj.hLineGraphic(1),'YData',[obj.y obj.y]);
        set(obj.hGraphic,'position',[obj.x-obj.alienSize/2,obj.y-obj.alienSize/2,obj.alienSize,obj.alienSize]);
        if obj.flash == 3                               %nr of flashes
            set(obj.hGraphic,'facecolor','g');
        end
      end
                                % remove deleted objects
      keep=true(1,numel(hAliensIn)); for bi=1:numel(hAliensIn); if( ~ishandle(hAliensIn(bi).hGraphic) ) keep(bi)=false; end; end; hAliensOut = hAliensIn(keep);
    end

                          % get a unique idenification number for this object
    function nuid=getuid()
      % Yuck! horrible MATLAB hacks to get static values in a function...
      persistent uid;
      if(isempty(uid))uid=256;end; % Aliens always >256 (bit 8 set)
      uid=uid+1;
      nuid=uid;
    end

  end
end

