classdef Alien < handle
    % Class for generating an alien.
    
    
    %% Properties:
    
    properties (Constant)
        
        % 'rel' indicates that a the properties is a fractions of the
        % screen width or height, these properties are used to generate the
        % actual sized at object instantiation:
        relStartLine      = 0.9;
        relFallSpeed      = 0.15;
        relAlienStartSize = 0.05;  % The start size of the alien.
        relAlienGrowRate  = 0.015; % The growth rate of the alien.
        alienGrowExp      = 1.5;   % The time exponent of the growth rate.
        
        % NOTE: Aliens sometimes grow exponentially, so their sizes are
        % calculated as:
        %
        % alienSize = (startSize + alienAge^alienGrowExp)*relAlienGrowRate
    end
    
    
    properties
        x;                   % X pos of alien.
        y;                   % Y pos of alien.
        alienSize;           % Alien size.
        hGraphic;            % handle to alien graphics object.
        hLineGraphic;
        hAxes;               % handle to axes.
        alienSpawnTime;      % logs the alien spawn time.
        shotsToKill;
        hCannon;
    end
    
    %% Methods:
    
    methods
        
        
        %==================================================================
        function obj = Alien(hAxes,hCannon)
            % Constructs an alien.
            
            % Save properties:
            obj.y = hAxes.YLim(1)+obj.relStartLine*range(hAxes.YLim);
            obj.hAxes = hAxes;
            obj.hCannon = hCannon;
            
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
            obj.randomlyPlaceAlien;
        end
        
        
        %==================================================================
        function hit(obj)
            obj.deleteAlien();
            
        end
        
        
        %==================================================================
        function [hAliensOut, cannonKills] = updateAliens(hAliensIn)
            
            cannonKills = 0;
            if isempty(hAliensIn);
                hAliensOut = Alien.empty;
                return
            end
            
            % Loop through aliens:
            for obj = hAliensIn;
                
                if~isvalid(obj)
                    continue
                end
                yLims = get(obj.hAxes,'YLim');
                obj.alienSize = (obj.relAlienStartSize...
                    +(toc(obj.alienSpawnTime)^obj.alienGrowExp)...
                    *obj.relAlienGrowRate)...
                    *range(obj.hAxes.YLim);
                obj.y = (obj.relStartLine - toc(obj.alienSpawnTime)...
                    *obj.relFallSpeed)*range(yLims);
                waistY = calcForceFieldY(obj);
                if obj.x+obj.alienSize>obj.hCannon.Xbase...
                        && obj.x<obj.hCannon.Xbase+obj.hCannon.cannonWidth
                    if obj.y<obj.hCannon.Ybase+obj.hCannon.cannonHeight
                    obj.deleteAlien();
                    cannonKills = cannonKills+1;
                    continue
                    end
                end
                if waistY<obj.hCannon.Ybase+obj.hCannon.cannonHeight
                    obj.deleteAlien();
                    cannonKills = cannonKills+1;
                    continue
                end

                % update alien graphic, and spawn time:
                set(obj.hLineGraphic(1),'YData',[waistY waistY]);
                set(obj.hGraphic...
                    ,'position',[obj.x,obj.y,obj.alienSize,obj.alienSize]);

            end
            hAliensOut = hAliensIn(isvalid(hAliensIn));
        end
        
        
        %==================================================================
        function randomlyPlaceAlien(obj)
            % randomly respawns the alien somwehere within the axes lims.
            
            % Set random size and position:
            obj.alienSize = obj.relAlienStartSize*range(obj.hAxes.YLim);
            alienXLims = get(obj.hAxes,'XLim')+obj.alienSize.*[1 -1];
            alienX = alienXLims(1) + rand(1)*range(alienXLims);
            obj.x = alienX;
            
            set(obj.hLineGraphic,'XData',obj.hAxes.XLim);
            waistY = calcForceFieldY(obj);
            set(obj.hLineGraphic(1),'YData',[waistY waistY]);
            
            % update alien graphic, and spawn time:
            set(obj.hGraphic...
                ,'position',[obj.x,obj.y,obj.alienSize,obj.alienSize]);
            obj.alienSpawnTime = tic;
            
        end
        
        
        %==================================================================
        function out = calcForceFieldY(obj)
            out = obj.y + 0.5*obj.alienSize;
        end
       
        
        %==================================================================        
        function deleteAlien(obj)
            % Deletes the ball graphic, and the CannonBall object.
            
            delete(obj.hGraphic);
            delete(obj.hLineGraphic);
            delete(obj);
            
        end
    end
end

