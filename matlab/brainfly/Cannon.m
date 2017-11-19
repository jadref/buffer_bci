classdef Cannon < handle
    % Cannon Class for a cannon.
    
    %% Properties:
    
    properties (Constant)
        
        % The following properties of fractions of the screen width or
        % height, these properties are used to generate the actual sized at
        % object instantiation:
        relCannonWidth  = 0.08;   % The width of the cannon.
        relCannonHeight = 0.1;    % The height of the cannon.
        relMoveStepSize = .5;     % The maximum cannon move in 1 second
        minuid=1;
        relcannonRange  = [.1 .9]; % min/max cannon position w.r.t. axes limits 
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
        lastDrawTime;       % logs when we last re-drew the cannon
        uid;                % unique identification number
    end
    
    
    %% Methods:
    
    methods
        
        %==================================================================
        function obj = Cannon(hAxes)
            % Cannon constructor:
            
            % Calculate the cannon parameters:
            axesXLim     = get(hAxes,'XLim');
            axesYLim     = get(hAxes,'YLim');
            obj.cannonWidth  = diff(axesXLim)*obj.relCannonWidth;
            obj.cannonHeight = diff(axesYLim)*obj.relCannonHeight;
            obj.Xbase    = mean(axesXLim)-0.5*obj.cannonWidth;
            obj.Ybase    = axesYLim(1);
            
            % Make cannon:
            obj.hGraphic = rectangle('curvature',[0 0]...
                ,'position',[obj.Xbase,obj.Ybase...
                ,obj.cannonWidth,obj.cannonHeight],...
                'facecolor','w');
            
            % Save properties:
            obj.hAxes = hAxes;
            obj.moveStepSize = obj.relMoveStepSize*diff(axesXLim);
            obj.lastDrawTime = [];
            obj.uid = Cannon.getuid();
        end
        
        %==================================================================
        function move(obj,whereTo,howMuch)
            % Method to move the cannon.
            %
            %   obj.move(whereTo,howMuch)
            % Inputs:
            %   whereTo: one-of {'left' 'right'}
            %           the direction of movement
            %     or
            %            [float] direction position on the screen to warp cannon
            %   howMuch: [float] fraction of the moveStepSize that is taken (ideally: 0<howMuch<=1).
            
            % Calculate the variable step size, taking account of draw lags
          curStepSize = obj.moveStepSize;
          if( ~isempty(howMuch) ) curStepSize=curStepSize*howMuch; end;
            if ( ~isempty(obj.lastDrawTime) ) curStepSize=curStepSize*toc(obj.lastDrawTime); end;
            axesXLim     = get(obj.hAxes,'XLim');
            cannonLim    = axesXLim(1)+(axesXLim(2)-obj.cannonWidth-axesXLim(1))*obj.relcannonRange;

            if isnumeric(whereTo) % warp mode, but limit step size
              whereTo   = cannonLim(1) + whereTo*(cannonLim(2)-cannonLim(1));
              obj.Xbase = max(min(whereTo,obj.Xbase+curStepSize),obj.Xbase-curStepSize); % step-size check
            else % string so step-size
              switch whereTo                
                case 'left'; % Move cannon left, but keep in in bounds.
                    obj.Xbase = obj.Xbase+curStepSize;
                    
                case 'right';  % Move cannon right, but keep in in bounds.
                    obj.Xbase = obj.Xbase-curStepSize;
              end
            end
                                % display bounds check
            obj.Xbase = min(max(obj.Xbase,cannonLim(1)),cannonLim(2));
            % update the object properties
            pos=get(obj.hGraphic,'position');
            pos(1)=obj.Xbase;
            set(obj.hGraphic,'position',pos);
            obj.lastDrawTime=tic; % record draw time
        end
        
    end

    methods(Static)
                            
      function nuid=getuid()% only 1 cannon, so always UID=1
        nuid=1;
      end

    end   
end
