classdef Cannon < handle
    % Cannon Class for a cannon.
    
    %% Properties:
    
    properties (Constant)
        
        % The following properties of fractions of the screen width or
        % height, these properties are used to generate the actual sized at
        % object instantiation:
        relCannonWidth  = 0.05;   % The width of the cannon.
        relCannonHeight = 0.1;    % The height of the cannon.
        relMoveStepSize = 0.02;   % The maximum cannon movement step size.
    end
    
    properties
        
        % The following properties hold data about the cannon object:
        cannonWidth;        % Actual cannon width.
        cannonHeight;       % Actual cannon height.
        moveStepSize;       % Actual max step size.
        Xbase;              % X position of bottom left of cannon.
        Ybase;              % Y position of bottom left of cannon.
        hGraphic;           % Handle to ball graphics object.
        hAxes;              % Handle to axes.
    end
    
    
    %% Methods:
    
    methods
        
        %==================================================================
        function obj = Cannon(hAxes)
            % Cannon constructor:
            
            % Calculate the cannon parameters:
            axesXLim     = get(hAxes,'XLim');
            axesYLim     = get(hAxes,'YLim');
            obj.cannonWidth  = range(axesXLim)*obj.relCannonWidth;
            obj.cannonHeight = range(axesYLim)*obj.relCannonHeight;
            obj.Xbase    = mean(axesYLim)-0.5*obj.cannonWidth;
            obj.Ybase    = axesYLim(1);
            
            % Make cannon:
            obj.hGraphic = rectangle('curvature',[0 0]...
                ,'position',[obj.Xbase,obj.Ybase...
                ,obj.cannonWidth,obj.cannonHeight],...
                'facecolor','w');
            
            % Save properties:
            obj.hAxes = hAxes;
            obj.moveStepSize = obj.relMoveStepSize*range(axesXLim);
            
        end
        
        %==================================================================
        function move(obj,whereTo,howMuch)
            % Method to move the cannon.
            %
            %   obj.move(whereTo,howMuch) The whereTo {'left' 'right'}
            %   argument determines the direction of movement, and the
            %   howMuch argument determines the fraction of the
            %   moveStepSize that is taken (ideally: 0<howMuch<=1).
            
            % Calculate the variable step size:
            curStepSize = howMuch*obj.moveStepSize;
            
            switch whereTo
                
                case 'left'
                    
                    % Move cannon left, but keep in in bounds.
                    obj.Xbase = max(obj.Xbase-curStepSize...
                        ,obj.hAxes.XLim(1));
                    obj.hGraphic.Position(1) = obj.Xbase;
                    
                case 'right'
                    % Move cannon right, but keep in in bounds.
                    obj.Xbase = min(obj.Xbase+curStepSize...
                        ,obj.hAxes.XLim(2)-obj.cannonWidth);
                    obj.hGraphic.Position(1) = obj.Xbase;
            end
            
        end
        
    end
    
end
