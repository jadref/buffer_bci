function [hs,Xs,Ys,rX,rY]=posplot(Xs,Ys,Idx,varargin)
% Function to generate sub-plots at given 2-d positions
%
% [hs]=posPlot(Xs,Ys,Idx[,options])
% OR
% [hs]=posPlot(XYs,Idx[,options])
% Inputs:
%  Xs -- X (horz) positions of the plots [1 x N]
%  Ys -- Y (vert) positions of the plots [1 x N]
% XYs -- X,Y positions of the plots      [2 x N]
% Idx -- subplot to make current         [1 x 1] or []
% Options
%  scaling -- do we preserve the relative scaling of x y axes?
%             'none': don't preserver, 'square' : do preserve
%  sizes   -- do we constrain the plots to be the same size?
%             'none': no size constraint, 'equal': all plots have same x/y size
%          -- Everything else is treated as an option for axes
%  plotsposition-- [4 x 1] vector of the figure box to put the plots: [x,y,w,h]
%                  ([0 0 1 1])
% Outputs:
%  hs -- if output is requested this is the set of sub-plot handles, 
%        [N x 1] if Idx==[] or the [1x1] handle of the Idx'th plot if specified
%  Xs,Ys,Rx,Ry -- position of the plots
opts = struct('sizes','none','scaling','none','plotsposition',[0 0 1 1],'postype','outerposition',...
              'emptySize',.05,'sizeOnly',0,'interplotgap',.003);

% Argument processing
if( nargin < 3 ) if ( nargout > 0 ) Idx=[]; else Idx=1; end; end;
if( nargin < 2 ) Ys =1; end;
if( (isscalar(Ys) || isempty(Ys)) && any(size(Xs)==2) ) % convert XYs form to Xs Ys form
   varargin={Idx,varargin{:}};
   Idx=Ys; 
   if(size(Xs,2)~=2) Xs=Xs'; end; Ys=Xs(:,2);Xs=Xs(:,1); % split into X,Y
end;
if( numel(Ys) ~= numel(Xs) ) 
   error('Xs and Ys *must* have same number of elements');
end
if( ~isempty(Idx) && ( Idx < 0 || Idx > numel(Xs) ) ) 
   error('Idx greater than the number of sub-plots');
end
Xs=Xs(:); Ys=Ys(:); % ensure col vecs
N=size(Xs,1);

% remove our options, leave rest for subplot
[opts,varargin]=parseOpts(opts,varargin); 
opts.interplotgap(end+1:4)=opts.interplotgap(1);

% Compute the radius between the points
[rX,rY]=packBoxes(Xs,Ys);

if( isequal(opts.sizes,'equal') ) % all radii the same for all plots
   rX(:) = min(rX);  rY(:) = min(rY);
end

rX = [rX rX];  % allow different left/right radii
rY = [rY rY];  % allow different bot/top radii

% Next compute scaling for the input to the unit 0-1 square, centered on .5
minX = min(Xs-rX(:,1)); maxX=max(Xs+rX(:,2));  % x-range (inc plot radius)
minY = min(Ys-rY(:,1)); maxY=max(Ys+rY(:,2));  % y-range (inc plot radius)
W    = maxX-minX; W = W / opts.plotsposition(3); if(W<=0) W=1; end;
H    = maxY-minY; H = H / opts.plotsposition(4); if(H<=0) H=1; end;
if ( isequal(opts.scaling,'square') ) W=max(W,H); H=max(W,H); end;
Xs   = (Xs-(maxX+minX)/2)/W; rX = rX/W;
Xs   = Xs + opts.plotsposition(1)+.5*opts.plotsposition(3);
Ys   = (Ys-(maxY+minY)/2)/H; rY = rY/H;
Ys   = Ys + opts.plotsposition(2)+.5*opts.plotsposition(4);

% subtract the inter-plot gap if necessary.
rX(:,1) = rX(:,1) - opts.interplotgap(1); % left
rX(:,2) = rX(:,2) - opts.interplotgap(2); % right
rY(:,1) = rY(:,1) - opts.interplotgap(3); % bottom
rY(:,2) = rY(:,2) - opts.interplotgap(4); % top

% Check if this is a reasonable layout
if( opts.emptySize>0 && (any(rX(:)<=0) || any(rY(:)<=0) || any(isnan(rY(:))) || any(isnan(rX(:)))) ) 
   warning('Not enough room between points to make plot');
   rX(rX<=0 | isnan(rX))=opts.emptySize(1); 
   rY(rY<=0 | isnan(rY))=opts.emptySize(min(end,2));
end

% generate all subplots if handles wanted
hs=[];
if ( nargout > 0 && isempty(Idx) ) 
  if ( ~opts.sizeOnly ) 
    for i=1:N;
      hs(i) = axes(opts.postype,[Xs(i)-rX(i,1) Ys(i)-rY(i,1) sum(rX(i,:)) sum(rY(i,:))],varargin{:});
    end
  end
else % just make and return the Idx wanted
  if ( ~opts.sizeOnly ) 
    hs = axes(opts.postype,[Xs(Idx)-rX(Idx) Ys(Idx)-rY(Idx) 2*rX(Idx) 2*rY(Idx)],varargin{:});
  end
  Xs=Xs(Idx);Ys=Ys(Idx);rX=sum(rX(Idx,:));rY=sum(rY(Idx,:));
end
return;

%----------------------------------------------------------------------------
function testCase();
hs=posplot([1 2 3],[2 2 2]);
posplot([1 2 3;2 2 2])
clf;h=posplot([1 2 3],[1 2 3]);
clf;h=posplot(rand(10,1),rand(10,1));
clf;h=posplot(rand(10,1),rand(10,1),[],'sizes','any');
clf;h=posplot([1 2 3],[1 1.5 2],[],'sizes','any');

clf;h=posplot([.2 .6 .7],[.5 .4 .45],[],'sizes','any');

clf;h=posplot([0 sin(0:2*pi/10:2*pi*.99)],[0 cos(0:2*pi/10:2*pi*.99)],[], ...
              'sizes','any');

for i=1:11;
   posplot([0 sin(0:2*pi/10:2*pi*.99)],[0 cos(0:2*pi/10:2*pi*.99)],i,'sizes','any');
   plot(sin(0:2*pi/10:2*pi))
end
