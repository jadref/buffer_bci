function [varargout]=packplots(varargin);
% pack a set of sub-plots to maximise the plot size
%
% [hdls]=packplots([hdls,varargin])
% Inputs:
%  hdls -- the set of sub-plot handles to pack, ( findobj(gcf,'type','axes'))
% Options:
%  interplotgap -- [4 x 1] vector of gaps to leave around [Left,Right,Bot,Top] 
%                  boundaries of each subplot (.003)
%  plotsposition-- [4 x 1] vector of the figure box to put the plots: [x,y,w,h]
%                  ([0.05 0.05 .93 .9])
%  scaling      -- {'square','any'} how we rescale positions to fit window 
%                  ('any')
%  sizes        -- {'equal','any'} do all the axes have the same size ('any')
%  postype      -- {'position','outerposition'} which type of plot position 
%                  to balance.  outerposition includes tick-labs/legends, 
%                  position does not. 
% Outputs:
%  hdls -- handles of the subplots
if ( nargin>0 && isnumeric(varargin{1}) ) hdls=varargin{1}; varargin(1)=[]; 
else hdls=[]; 
end;
opts = struct('interplotgap',.003,'plotsposition',[0.05 0.05 .93 .90],'scaling','any','sizes','any','postype','position','emptySize',.05);
[opts,varargin]=parseOpts(opts,varargin{:});
if ( nargin<1 || isempty(hdls) ) 
   hdls=findobj(gcf,'type','axes');
   hdls=hdls(strmatch('on',get(hdls,'Visible'))); % only visible considered
end
switch numel(opts.plotsposition);
 case 0; case 4;    % OK
 case 1;    opts.plotsposition(1:4)=opts.plotsposition;
 otherwise; error('Figure boundary gap should be 1 or 4 element vector');
end
switch numel(opts.interplotgap);
 case 0; case 4;    % OK
 case 1;    opts.interplotgap(1:4)=opts.interplotgap;
 otherwise; error('Interplot gap should be 1 or 4 element vector');
end


% Get the center of each plot.
pos= get(hdls,opts.postype); if ( iscell(pos) ) pos=cell2mat(pos); end;
Xs = pos(:,1)+.5*pos(:,3); 
Ys = pos(:,2)+.5*pos(:,4);

% Get maximal bounding box for each plot
[rX rY]=packBoxes(Xs,Ys);

if( isequal(opts.sizes,'equal') ) % all radii the same for all plots
   rX(:) = min(rX);  rY(:) = min(rY);
end

rX = [rX rX];  % allow different left/right radii
rY = [rY rY];  % allow different bot/top radii

% Get the tight inset
try
   ti =cell2mat(get(hdls,'tightinset'));
catch
   ti =[];
end
if ( ~isempty(ti) ) % use this to stop axes overlapping
   
end

% Now put the plots within the plots box
minX = min(Xs-rX(:,1)); maxX=max(Xs+rX(:,2));  % x-range (inc plot radius)
minY = min(Ys-rY(:,1)); maxY=max(Ys+rY(:,2));  % y-range (inc plot radius)
W    = maxX-minX; W = W / opts.plotsposition(3);
H    = maxY-minY; H = H / opts.plotsposition(4);
if ( isequal(opts.scaling,'square') ) W=max(W,H); H=max(W,H); end;
if ( W>0 ) Xs   = (Xs-(maxX+minX)/2)/W; rX = rX/W; end % 0 centered, -.5 -> +.5
Xs   = Xs + opts.plotsposition(1)+.5*opts.plotsposition(3);
if ( H>0 ) Ys   = (Ys-(maxY+minY)/2)/H; rY = rY/H; end % 0 centered, -.5 -> +.5
Ys   = Ys + opts.plotsposition(2)+.5*opts.plotsposition(4);

% subtract the inter-plot gap if necessary.
rX(:,1) = rX(:,1) - opts.interplotgap(1); % left
rX(:,2) = rX(:,2) - opts.interplotgap(2); % right
rY(:,1) = rY(:,1) - opts.interplotgap(3); % bottom
rY(:,2) = rY(:,2) - opts.interplotgap(4); % top

% Check if this is a reasonable layout
if( opts.emptySize>0 && (any(rX(:)<=0) | any(rY(:)<=0) | any(isnan(rY(:))) | any(isnan(rX(:)))) ) 
   warning('Not enough room between points to make plot');
   rX(rX<=0 | isnan(rX))=opts.emptySize(1); 
   rY(rY<=0 | isnan(rY))=opts.emptySize(min(end,2));
end

% Now that we've computed the new centers and widths set the new plot
% positions
pos = [Xs-rX(:,1) Ys-rY(:,1) sum(rX,2) sum(rY,2)];
set(hdls,{opts.postype},num2cell(pos,2));
if ( nargout>0 ) varargout{1}=hdls; end;
return

%----------------------------------------------------------------------------
function testCases()
