function [varargout]=jplot(coords,sf,varargin)
% Plot a set of random 2d points using the trisurf method
%
% [h]=jplot(coords,sf,layout)
% Inputs:
%  coords -- [N x 2] matrix of x,y point coordinates
%  vals   -- [N x d] vector of intensities at each point
% Options:
%  xs     -- [1x1] number of x points to interpolate
%            OR
%            [Nx x 1] actual x interpolation points
%  ys     -- [1x1] number of x points to interpolate
%            OR
%            [Ny x 1] actual x interpolation points
%  interpMethod -- [str] method to pass to griddata when performing the  ('invdist')
%                  interpolation, see GRIDDATA for details
%  layout -- [handles] set of axes handles to plot on,
%             OR
%            [w h] width,height in terms of number of sub-plots
%  clim   -- 'minmax' or [cmin,cmax] or 'cent0' - symetric about 0
%  colorbar -- [bool] put a colorbar on the plot                     (1)
%  labels -- {str} labels for each of the plots -- used for plot title
%  xlabel -- {str} label for x-axis
%  ylabel -- {str} label for y-axis
%  electrodes -- [int] size of the electrodes to plot, OR
%                {str} electrode names to plot
%  head   -- [bool] plot the head
%  contour -- [int] number of contour lines to plot
%  alphaMask -- bool
%  maskVal   -- [float] value to set masked out values to
%  rmax      -- radius of the head, max(coords)
opts=struct('xs',[],'ys',[],'layout',[],'clim','minmax','electrodes',4,'colorbar',1,'interpMethod','invdist',...
            'xlabel',[],'ylabel',[],'labels',[],'alphaMask',0,'maskVal',0,'padfactor',1.1,'head',2,'contour',2,...
            'rmax',[]);
[opts,varargin]=parseOpts(opts,varargin);
if(~isempty(opts.labels) && ~iscell(opts.labels) && isstr(opts.labels)) opts.labels={opts.labels}; end;
if(~isempty(opts.xlabel) && ~iscell(opts.xlabel) && isstr(opts.labels)) opts.xlabel={opts.xlabel}; end
if(~isempty(opts.ylabel) && ~iscell(opts.ylabel) && isstr(opts.labels)) opts.ylabel={opts.ylabel}; end

[nCh nfilt]=size(sf);
if ( size(coords,2)==2 && size(coords,1)~=2 || ...
     size(coords,2)==3 && size(coords,1)~=3 ) 
   coords=coords'; 
end;
if ( size(coords,2)<nCh ) 
   error('data and mesh must have same number pts');
end;

% setup the plot layout
if ( ~isempty(opts.layout) && all(ishandle(opts.layout)) ) w=[]; h=[]; hdls=opts.layout;
elseif ( numel(opts.layout)==2 )  h=opts.layout(1); w=opts.layout(2); hdls=[];
elseif ( nfilt > 1 )              h=floor(sqrt(nfilt+1)); w=ceil(nfilt/h); hdls=[]; % N.B. +1 for the colorbar
else                              h=[]; w=[]; hdls=gca; 
end

if ( size(coords,2)>nCh ) coords=coords(:,1:nCh); end;
%if ( size(coords,1)==2 )  coords=[coords;zeros(1,nCh)]; end; % make 3d

% scale electrodes to unit circle
rmax=opts.rmax; 
if ( isempty(rmax) )
  if ( all(sqrt(sum(coords.^2))<=1) ) %assume in unit sphere
    rmax=1;
   elseif ( all(sqrt(sum(coords.^2))<2) ) % assume input is already in std layout locations
      rmax = 2;
   else % estimate from the input co-ords
      rmax = .95*max(sqrt(sum(coords.^2))); 
   end
end;

xs=opts.xs; nx=numel(xs);
if ( isscalar(xs) || nx==0 ) 
   nx=opts.xs; if ( isempty(nx) ) nx=max(100,ceil(5*sqrt(nCh))); end;   
   xs = linspace(min(coords(1,:)*opts.padfactor),max(coords(1,:)*opts.padfactor),nx*opts.padfactor);
end;
ys=opts.ys; ny=numel(ys);
if ( isscalar(ys) || ny==0 ) 
   ny=opts.ys; if ( isempty(ny) ) ny=nx; end;
   ys = linspace(min(coords(2,:)*opts.padfactor),max(coords(2,:)*opts.padfactor),ny*opts.padfactor);
end
[xi,yi]=meshgrid(xs,ys); % points to plot at
% ID points outside the convex hull of the trodes
hulli = convhull(coords(1,:),coords(2,:)); % get the hull
mask  = inpolygon(xi,yi,coords(1,hulli)*opts.padfactor,coords(2,hulli)*opts.padfactor); % get mask
interp= zeros(size(xi)); interp(:)=NaN;
for i=1:nfilt;
   % make the correct axes current
   if ( nfilt>1 || ~isempty(hdls) ) if ( numel(hdls)<i ) hdls(i)=subplot(h,w,i); else axes(hdls(i)); end; end;

   % Interpolate the data
   if ( 1 ) % slightly faster as less points evaluated
      interpm=griddata(coords(1,:),coords(2,:)',double(real(sf(:,i))),...
                       xi(mask),yi(mask),opts.interpMethod);
      interp(mask)=interpm; 
   else
      interp=griddata(coords(1,:),coords(2,:)',double(real(sf(:,i))),xi,yi,opts.interpMethod);
      interp(~mask)=opts.maskVal; % mask out outside
   end
  
   plotImg=interp; plotImg(~mask)=opts.maskVal;
   if ( opts.alphaMask ) % plot with alpha-Mask if wanted
      imagesc(xi(1,:),yi(:,2),plotImg,'AlphaData',mask,varargin{:});
      set(gca,'YDir','normal'); 
      set(gca,'xtick',[],'ytick',[],'box','off','xcolor',[1 1 1],'ycolor',[1 1 1],'visible','off');
   else
      imagesc(xi(1,:),yi(:,2),plotImg,varargin{:});
      set(gca,'YDir','normal'); 
      set(gca,'xtick',[],'ytick',[],'box','off','xcolor',[1 1 1],'ycolor',[1 1 1],'visible','off');
   end

   % contour over the surface
   if ( ~isempty(opts.contour) ) % contours
      hold on; contour(xi(1,:),yi(:,2),interp,opts.contour,'k'); 
   end 
   
   % electrode indicators
   if ( ~isempty(opts.electrodes) && ~isequal(opts.electrodes,0) ) 
      if ( isnumeric(opts.electrodes) ) linW=opts.electrodes; else linW=5; end;
      apos=get(gca,'position'); asize=min(apos(3:4)); linW=asize*300./sqrt(size(coords,2))/5;
      hold on; plot(coords(1,:),coords(2,:),'ok','MarkerSize',linW,'lineWidth',linW/3,'MarkerEdgeColor','k');
      if( isstr(opts.electrodes) || (iscell(opts.electrodes) && isstr(opts.electrodes{1})) ) % electrode names
         text(coords(1,:),coords(2,:),opts.electrodes,'HorizontalAlignment','left','VerticalAlignment','bottom');
      end
   end

   % plot head, ears, nose
   if ( opts.head ) hold on; topohead([],'rmax',rmax); end

   % title, xlabel, ylabel
   if ( ~isempty(opts.labels) ) 
      if ( iscell(opts.labels) )  title(opts.labels{min(end,i)});  
      elseif ( isnumeric(opts.labels) ) title(sprintf('%g',opts.labels(min(end,i))));
      end
   end;
   if ( ~isempty(opts.xlabel) ) xlabel(opts.xlabel{min(end,i)}); end;
   if ( ~isempty(opts.ylabel) ) ylabel(opts.ylabel{min(end,i)}); end;
   set(get(gca,'Title'),'Visible','on'); % needed because we made the box invisible!

end

% setup the color limits
clim=[min(sf(:)) max(sf(:))];
if ( ~isempty(opts.clim) )
   if ( isstr(opts.clim) )
      switch (opts.clim)
       case 'minmax'; clim=[min(sf(:)) max(sf(:))];
       case 'cent0'; clim=max(abs(sf(:)))*[-1 1];
       otherwise; error('Unrecognised clim type');
     end
   elseif ( isnumeric(opts.clim) ) clim=opts.clim;
   else error('Unrecognised clim type');
  end
  if ( diff(clim)<eps ) clim=clim(1)+[-1 1]; end;
  set(hdls,'Clim',clim);
end

% setup the colorbar
if ( opts.colorbar )
  if ( nfilt > 1 ) 
    if ( numel(hdls)>i ) pos=get(hdls(i+1),'position'); else pos=[.94 .1 .03 .8]; end;
    hdls(i+1)=colorbar('peer',hdls(i),'position',pos);
  else
    colorbar('peer',hdls(i));
  end
end

if ( nargout>0 ) varargout{1}=hdls; end;

return;
%-----------------------------------------------------------------
function testcase();
