classdef CannonBall < handle
    
    %% Properties:
    
    properties (Constant)
        verticalSpeed = 0.8;   % rising speed of ball.
        relSizeBall   = 0.03; % ball size
        minuid=1024;
    end
    
    
    properties
        shotX;               % X where ball was shot.
        shotY;               % Y where ball was shot.
        shotClock;           % time when ball was shot.
        sizeBall;
        hGraphic;            % handle to ball graphics object.
        hAxes;               % handle to axes.
        uid;                 % unique identifier for this cannonball
        hCannon;
    end
    
    %% Methods:
    
    methods
        
        
        %==================================================================
        function obj = CannonBall(hAxes,hCannon)
            % Constructs a cannonball.
          %disp('now a ball')
            
            % Save properties:
            obj.sizeBall = obj.relSizeBall*range(get(hAxes,'YLim'));
            obj.shotX = hCannon.Xbase+0.5*hCannon.cannonWidth...
                -0.5* obj.sizeBall;
            obj.shotY = hCannon.Ybase+hCannon.cannonHeight;
            obj.hAxes = hAxes;
            obj.hCannon  = hCannon;
            
            % Draw cannonball:
            obj.hGraphic = rectangle(...
                'curvature',[1 1]...
                ,'facecolor','w'...
                ,'parent',hAxes...
                ,'position',[obj.shotX,obj.shotY...
                ,obj.sizeBall,obj.sizeBall]...
                ,'visible','on');
            
            % Save the time that the ball was shot:
            obj.shotClock = tic;
            obj.uid = CannonBall.getuid();
        end       
        
         %==================================================================
        function deleteBall(obj)
            % Deletes the ball graphic, and the CannonBall object.
            
            delete(obj.hGraphic)
            %delete(obj);
            
        end
    end
    methods(Static)
        %==================================================================
        function [ballsOut, hits] = updateBalls(ballsIn,hAlien)
        % Processes cannonballs.
            
        % Only use the first (lowest) alien:
           if ~isempty(hAlien)
              hAlien = hAlien(1);
           else
              hAlien = [];
           end
            
           hits = [];
           % Skip if there are no balls, return an empy object:
           if isempty(ballsIn);
              ballsOut = CannonBall.empty;
              return
           end
            
           % Otherwise, loop through balls:
           for bi=1:numel(ballsIn);
              obj = ballsIn(bi);
              if( ~ishandle(obj.hGraphic) ) continue; end; % already deleted?

              % Update current cannonball (NewY  = shotY + elapsedTime *
              % speed):
              yLims = get(obj.hAxes,'YLim');
              curY = obj.shotY + toc(obj.shotClock)...
                     *obj.verticalSpeed*range(yLims);
                
              % Check out of bounds of current ball:
              if curY>yLims(2)
                 obj.deleteBall;
                 continue
              end
                
              % Check collision with alien:
              if ~isempty(hAlien) && ishandle(hAlien.hGraphic)
                 allowableBallOverlap = 0.8;
                 if curY >= hAlien.y - allowableBallOverlap*obj.sizeBall
                    if obj.shotX + obj.sizeBall >= hAlien.x - 0.5*hAlien.alienSize ...
                           && obj.shotX <= hAlien.x + hAlien.alienSize - 0.5*hAlien.alienSize
                       disp('You got it!');
                       hAlien.hit;
                       hits = [hits; hAlien.y];
                       obj.deleteBall;
                       continue
                    end
                 end
                    
                 % Check collision with forcefield
                 if curY>hAlien.y-allowableBallOverlap*obj.sizeBall
                    obj.deleteBall;
                    continue
                 end
              end
                
              % Update the ball graphic if the ball is still alive:
              if( ishandle(obj.hGraphic) )
              set(obj.hGraphic...
                  ,'position',[obj.shotX,curY...
                               ,obj.sizeBall,obj.sizeBall]);
              end
           end
            
            % Only return the balls that were not deleted:
            keep=true(1,numel(ballsIn)); for bi=1:numel(ballsIn); if( ~ishandle(ballsIn(bi).hGraphic) ) keep(bi)=false; end; end;ballsOut = ballsIn(keep);
            
        end

        % get a unique idenification number for this object
        function nuid=getuid()
          persistent uid;
          if(isempty(uid))uid=Alien.minuid;end;%Cannonball > 1024 (bit 10 set)
          uid=uid+1;
          nuid=uid;
        end
    end       
end
