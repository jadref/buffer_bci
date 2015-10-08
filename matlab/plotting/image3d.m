function [varargout]=image3d(varargin)
% plot 3d matrix in the image style
% 
% [h]=image3d(A,dim,varargin)
% or
% [h]=image3d(Xvals,Yvals,Zvals,A,dim,varargin)
%
% Inputs:
%  A   -- the matrix to plot
%  dim -- the dimension of A along which to slice for plotting
%  Xvals -- values for each element of A along 1st (X) dimension
%  Yvals -- values for each element of A along 2st (Y) dimension
%  Zvals -- values for each element of A along 3st (Z) dimension
% Options:
%  plotPos  -- [size(A,dim) x 4] set of [x,y] positions to plot the slices
%  handles  -- [size(A,dim) x 1] set of axes handles to plot the slices
%  layout   -- [2 x 1] width x height in subplots
%  Xvals    -- [size(A,1) x 1] label for each element of the 1st dim of A (1:size(A,1))
%  Yvals    -- [size(A,2) x 1] label for each element of the 2nd dim of A (1:size(A,2))
%  Zvals    -- [size(A,3) x 1] label for each element of the 3rd dim of A (1:size(A,3))
%  xlabel   -- str with the label (i.e. dimension name, e.g. 'ch') for the x (dim 1) bin values ('')
%  ylabel   -- str with the label (i.e. dimension name, e.g. 'time') for the y (dim 2) bin values ('')
%  zlabel   -- str with the label (i.e. dimension name, e.g. 'epoch')for the z (dim 3) bin values ('')
%  colorbar -- [1x1] logical, put on a colorbar/legend (true for image dispType)
%  legend   -- [1x1] logical, put a legend on the plot (true for plot dispType)
%                {'se','sw','ne','nw'} -- where to put the legend
%  clim     -- type of axis limits to use, [2x1] limits, 'cent%f' centered on %f, 'minmax' data range
%               empty clim means let each plot have it's own color scaling
%  showtitle-- [bool] show title on each plot                      (true)
%  clabel   -- str with the label for the colors
%  ticklabs -- {'all','none','SW','SE','NW','NE'} put tick labels on plots
%              at these locations ('all')
%  varargin -- addition properties of the plot to set
%  disptype -- type of plot to draw, {'image','imaget','plot'}
%                image  -- normal image
%                imaget -- image with x/y axes swapped
%                plot   -- line plot
%                mcplot -- multi-channel plot
%                mcplott-- multi-channel plot, with x/y axes swapped
%                function_name -- call user supplied function to draw the
%                      plot. Call mode is:
%                      function_name(xvals,yvals,data_matrix,...
%                                    xticklabs,yticklabs,xlabel,ylabel,clabel)
%  plotopts -- options to pass to the display function ([])
%  plotPosOpts -- options to pass to posPlots (if used)
%                 (struct('sizes','equal','plotsposition',[.05 .08 .91 .88],'postype','position'))
%  titlepos -- [x y width] title position relative to the plot  ([.5 1 1])
% Outputs:
%  h   -- the handles of the generated plots
%

% Not Implementated yet!
%  xmask    -- set of x (dim 1) bins to plot ([] == all bins)
%  ymask    -- set of y (dim 2) bins to plot ([] == all bins)
%  zmask    -- set of z (dim 3) bins to plot ([] == all bins)

% check for (X,Y,Z,dim,varargin) calling format
opts = struct('plotPos',[],'handles',[],'layout',[],...
              'X',[],'Y',[],'Z',[],...
              'Xvals',[],'Yvals',[],'Zvals',[],'xVals',[],'yVals',[],'zVals',[],'xvals',[],'yvals',[],'zvals',[],...
              'xlabel','','ylabel','','zlabel','',...
              'xmask',[],'ymask',[],'zmask',[],...
              'colorbar',[],'legend',[],'clim','minmax','clabel','',...
              'disptype','image','plotopts',{{}},...
              'ticklabs','all','titlepos',[.98 .98 1],'showtitle',1,...
              'plotPosOpts',struct('sizes','equal','plotsposition',[.05 .08 .91 .88],'postype','position'));

used=false(numel(varargin));
Xvals=[];Yvals=[];Zvals=[];
if ( nargin>=4 && ...
     (isempty(varargin{1}) || ...
      (ndims(varargin{1})==2 && min(size(varargin{1}))==1 && ...
       (isnumeric(varargin{1}) || iscell(varargin{1})))) && ...
     (isempty(varargin{2}) || ...
      (ndims(varargin{2})==2 && min(size(varargin{2}))==1 && ...
       (isnumeric(varargin{2}) || iscell(varargin{2})))) && ...
     (isempty(varargin{3}) || ...
      (ndims(varargin{3})==2 && min(size(varargin{3}))==1 && ...
       (isnumeric(varargin{3}) || iscell(varargin{3})))) )
   if ( nargin<5 ) dim=1; 
   elseif ( isscalar(varargin{5}) ) dim=varargin{5}; used(5)=true;
   else dim=1;
   end
   Xvals=varargin{1}; Yvals=varargin{2}; Zvals=varargin{3}; A=varargin{4};
   sizeA=size(A); sizeA(end+1:3)=1; % fill in with defaults unspecified info
   used(1:4)=true;
   if( ~((numel(varargin{1})==sizeA(1) || numel(varargin{1})==0 ) && ...
         (numel(varargin{2})==sizeA(2) || numel(varargin{2})==0 ) && ...
         (numel(varargin{3})>=sizeA(3) || numel(varargin{3})==0 )) ) 
      warning('Inputs sizes didnt match a (xs,ys,zs,A) style call');
      %used(:)=false; % mark no arguments as consumed
   end
end

% Check for A,dim,... callng format
if ( ~any(used) ) 
   if ( nargin < 2 ) dim =1; 
   elseif ( isscalar(varargin{2}) ) dim=varargin{2}; used(2)=true;
   else dim=1;
   end
   A=varargin{1}; used(1)=true;
end

% remove arguments we've used.
varargin(used)=[];

% Parse out other options we want.
[opts,varargin]=parseOpts(opts,varargin);
if ( ~isempty(opts.plotPos) && size(opts.plotPos,2)==2 ) % ensure right shape
   opts.plotPos=opts.plotPos';
end
if ( ~iscell(opts.plotopts) ) opts.plotopts={opts.plotopts}; end;
% BODGE: keep the legacy names working
if( ~isempty(opts.X) && isempty(opts.Xvals) ) opts.Xvals=opts.X; end
if( ~isempty(opts.Y) && isempty(opts.Yvals) ) opts.Yvals=opts.Y; end
if( ~isempty(opts.Z) && isempty(opts.Zvals) ) opts.Zvals=opts.Z; end

if ( dim > 3 ) warning('Only for 3d inputs'); dim=3; end;

sizeA=size(A); sizeA(end+1:3)=1;
N=sizeA(dim);
if(~isempty(opts.Xvals)) Xvals=opts.Xvals; end;
if(isempty(Xvals) && ~isempty(opts.xVals)) Xvals=opts.xVals; end 
if(isempty(Xvals) && ~isempty(opts.xvals)) Xvals=opts.xvals; end 
if( isempty(Xvals) ) Xvals=1:sizeA(1); end; 
if(~isempty(opts.Yvals)) Yvals=opts.Yvals; end;
if(isempty(Yvals) && ~isempty(opts.yVals)) Yvals=opts.yVals; end;
if(isempty(Yvals) && ~isempty(opts.yvals)) Yvals=opts.yvals; end;
if( isempty(Yvals) ) Yvals=1:sizeA(2); end;
if(~isempty(opts.Zvals)) Zvals=opts.Zvals; end;
if(isempty(Zvals) && ~isempty(opts.zVals)) Zvals=opts.zVals; end; 
if(isempty(Zvals) && ~isempty(opts.zvals)) Zvals=opts.zvals; end; 
if( isempty(Zvals) ) Zvals=1:sizeA(3); end;
if( isempty(opts.xmask) ) opts.xmask=true(1,sizeA(1)); end;
if( isempty(opts.ymask) ) opts.ymask=true(1,sizeA(2)); end;
if ( isempty(opts.zmask) ) opts.zmask=true(1,sizeA(3)); end;

% setup the type of colorbar/legend to use
if ( isempty(opts.colorbar) && isempty(opts.legend) ) % set the default based on plot type
   switch ( opts.disptype ); % identify type of colorbar to use
    case {'image','imaget','imagesc'};        opts.colorbar=1; opts.legend=[];
    case {'plot','plott','mcplot','mcplott'}; opts.colorbar=[]; opts.legend=1;
    otherwise; 
  end
end

% FIXME: Need  to use the masks to correctly setup the ax info and idx
% N.B. axes order: [ x y sub-plots ]
for i=1:2; idx{i}=1:sizeA(i); end; idx{3}=1:prod(sizeA(3:end));% build index experssion
switch dim  % setup the axes labels and finish index expression
 case 1; 
  axsz   = sizeA([2 3 1]);
  axscale{3}= Xvals(1:axsz(3)); axlab{3}=opts.xlabel; axmask{3}=opts.xmask; 
  axscale{1}= Yvals(1:axsz(1)); axlab{1}=opts.ylabel; axmask{1}=opts.ymask; 
  if ( ndims(A)>3 && prod(sizeA(3:end))~=numel(Zvals) ) 
     warning('Extra dimensions after 3 compressed into 3rd');     
     axscale{2}=Zvals(1:axsz(2)); 
     if ( iscell(axscale{2}) ) % cell array of strings
       axscale{2}=axscale{2}(:); tmp=axscale{2};
       for i=1:prod(sizeA(4:end)); 
         for j=1:numel(tmp); axscale{2}{j,i}=[num2str(i) ' ' tmp{j}]; end;
       end
     elseif (isnumeric(axscale{2}) )
       tmp=axscale{2};
       for i=1:prod(sizeA(4:end)); 
         for j=1:numel(tmp); axscale{2}(j,i)=tmp(j) + 100*i; end;
       end
     end
     axscale{2}=axscale{2}(:)';
     zlab=opts.zlabel; if ( isempty(zlab) ) zlab=['d3']; end;
     axlab{2}  =sprintf('[extra,%s]',zlab); 
     axmask{2} =1:prod(sizeA(3:end)); 
  else
     axscale{2} = Zvals(1:axsz(2)); axmask{2}=opts.zmask; axlab{2}=opts.zlabel;
  end
  axsz(2) = prod(sizeA(3:end));
  
 case 2;
  axsz   = sizeA([1 3 2]);
  axscale{1}= Xvals(1:axsz(1)); axlab{1}=opts.xlabel; axmask{1}=opts.xmask; 
  axscale{3}= Yvals(1:axsz(3)); axlab{3}=opts.ylabel; axmask{3}=opts.ymask; 
  if ( ndims(A)>3 && prod(sizeA(3:end))~= numel(Zvals) ) 
     warning('Extra dimensions after 3 compressed into 3rd');     
     axscale{2}=Zvals(1:axsz(2)); 
     if ( iscell(axscale{2}) ) % cell array of strings
       axscale{2}=axscale{2}(:); tmp=axscale{2};
       for i=1:prod(sizeA(4:end)); 
         for j=1:numel(tmp); axscale{2}{j,i}=[num2str(i) ' ' tmp{j}]; end;
       end
     elseif (isnumeric(axscale{2}) )
       tmp=axscale{2};
       for i=1:prod(sizeA(4:end)); 
         for j=1:numel(tmp); axscale{2}(j,i)=tmp(j) + 100*i; end;
       end
     end
     axscale{2}=axscale{2}(:)';
     zlab=opts.zlabel; if ( isempty(zlab) ) zlab=['d3']; end;
     axlab{2}   = sprintf('[extra,%s]',zlab); 
  else
     axscale{2} = Zvals(1:axsz(2)); axlab{2}=opts.zlabel; axmask{2}=opts.zmask; 
  end 
  axsz(2) = prod(sizeA(3:end));
 
 case 3;
  axsz  = sizeA;
  axscale{1}= Xvals(1:axsz(1)); axlab{1}=opts.xlabel; axmask{1}=opts.xmask;
  axscale{2}= Yvals(1:axsz(2)); axlab{2}=opts.ylabel; axmask{2}=opts.ymask;
  if ( ndims(A)>3 && prod(sizeA(3:end))~= numel(Zvals) ) 
     warning('Extra dimensions after 3 compressed into 3rd'); 
     axscale{3}=Zvals(1:axsz(3)); 
     if ( iscell(axscale{3}) ) % cell array of strings
       axscale{3}=axscale{3}(:); tmp=axscale{3};
       for i=1:prod(sizeA(4:end)); 
         for j=1:numel(tmp); axscale{3}{j,i}=[num2str(i) ' ' tmp{j}]; end;
       end
     elseif (isnumeric(axscale{3}) )
       tmp=axscale{3};
       for i=1:prod(sizeA(4:end)); 
         for j=1:numel(tmp); axscale{3}(j,i)=tmp(j) + 100*i; end;
       end
     end
     axscale{3}=axscale{3}(:)';
     axsz(3)=prod(sizeA(3:end));
     zlab=opts.zlabel; if ( isempty(zlab) ) zlab=['d3']; end;
     axlab{3}   = sprintf('[extra,%s]',zlab); 
     N = prod(sizeA(3:end));
  else
     axscale{3}= Zvals(1:axsz(3)); axlab{3}=opts.zlabel; axmask{3}=opts.zmask;
  end 
end

% swap x/y info
if ( any(strcmp(opts.disptype,{'imaget','plott','mcplott'})) ) 
   tmp=axscale{1}; axscale{1}=axscale{2}; axscale{2}=tmp;
   tmp=axlab{1};   axlab{1}  =axlab{2};   axlab{2}  =tmp;
   tmp=axmask{1};  axmask{1} =axmask{2};  axmask{2} =tmp;
   tmp=axsz(1);    axsz(1)   =axsz(2);    axsz(2)   =tmp;   
end

axmark=axscale;
if ( ~isnumeric(axscale{1}) || any(abs(diff(diff(axmark{1})))>1e-6) ) axscale{1}=1:numel(axscale{1}); end;
if ( ~isnumeric(axscale{2}) || any(abs(diff(diff(axmark{2})))>1e-6) ) axscale{2}=1:numel(axscale{2}); end;
if ( isnumeric(axscale{1}) ) axscale{1}=single(axscale{1}); end;
if ( isnumeric(axscale{2}) ) axscale{2}=single(axscale{2}); end;
if ( isnumeric(axscale{3}) ) axscale{3}=single(axscale{3}); end;

%------ the actual plotting routines
if ( isempty(opts.layout) )
   nPlots=N;
   if ( ~isempty(opts.legend) && ~isequal(opts.colorbar,0) ) nPlots=nPlots+1; end;
   w=max(1,floor(sqrt(nPlots))); h=ceil((nPlots)/w); 
else
   w=opts.layout(1); h=opts.layout(2);
end

hdls=[];
% pre-make the axes -- it's faster in MATLAB
if ( ~isempty(opts.handles) )
    hdls=opts.handles;
elseif ( ~isempty(opts.plotPos) ) % pre-build all the figure handles
    hdls=posplot(opts.plotPos(1,:),opts.plotPos(2,:),[],opts.plotPosOpts);
else
  % Manually place on a rectangular grid.  N.B. we don't use subplot as it fails in some situations
  for pi=1:N;
	 j=floor((pi-1)/w); i=(pi-1)-j*w;
	 hdls(pi)=axes('position',[i/w (h-j-1)/h .95/w .95/h]); 
  end;
end
legendpos=[];if ( numel(hdls)>N ) legendpos=get(hdls(N+1),'position'); end;

% pre-identify the axes which have tickmarks and/or axeslabels
% turn on/off the tick marks / axes labels as requested
pos = get(hdls(1:N),'position'); if ( iscell(pos) ) pos=cat(1,pos{:}); end;
if ( ischar(opts.ticklabs) )
   switch lower(opts.ticklabs);
    case 'sw'; [ans,tickIdxs] = min((pos(:,1)-0).^2+(pos(:,2)-0).^2);
    case 'se'; [ans,tickIdxs] = min((pos(:,1)-1).^2+(pos(:,2)-0).^2);
    case 'nw'; [ans,tickIdxs] = min((pos(:,1)-0).^2+(pos(:,2)-1).^2);
    case 'ne'; [ans,tickIdxs] = min((pos(:,1)-1).^2+(pos(:,2)-1).^2);
    case 'none'; tickIdxs=[];
    case 'all';  tickIdxs=1:N;
    otherwise; error('Unrecognised ticklabs type'); 
  end
elseif ( isnumeric(opts.ticklabs) )
   if ( max(size(opts.ticklabs)==1) )
      tickIdxs=opts.ticklabs;
   elseif ( max(size(opts.ticklabs)==2) )
      if ( size(opts.ticklabs,2)==2 ) opts.ticklabs=opts.ticklabs'; end;
      for i=1:size(opts.ticklabs,2); % find the nearest plots
         [ans,tickIdxs(i)] = min((pos(:,1)-opts.ticklabs(1,i)).^2+...
                                 (pos(:,1)-opts.ticklabs(2,i)).^2);
      end
   else
      error('Numeric ticklabs should be position or index');
   end
end
tickAxes=false(N,1); tickAxes(tickIdxs)=true;

% Ensure all sub-plots use the same color/Yrange axes
clim=[min(A(:)) max(A(:))];  cblim=clim;
if ( ~isempty(opts.clim) )
   if ( ischar(opts.clim) )    
      if ( strmatch('cent',opts.clim) ) 
         cpt=str2num(opts.clim(5:end)); 
         clim=max(abs(A(:)-cpt))*[-1 1]+cpt; 
         cblim=clim;
      elseif ( strmatch('minmax',opts.clim) )
         clim=[min(A(:)) max(A(:))];  
         cblim=clim;
      else error('Unrec clim spec: %s',opts.clim);
      end
   elseif ( isnumeric(opts.clim) )
      clim = opts.clim;
      dA   = [min(A(:)) max(A(:))];%max(abs(A(:)));%-mean(A(:));
      cblim= [min(dA(1),opts.clim(1)),max(dA(2),opts.clim(2))];  % full range
   end
   if ( ~all(isfinite(clim)) ) 
      warning('Color limits are ill specified -- reset to [0 1]'); clim=[0 1];
   end
   if ( all(diff(clim)==0) )
      warning('Clims are equal -- reset to clim+/- .5'); clim=clim(1)+[-.5 .5]; 
   end;
end

for pi=1:N;
   idx{dim}=pi;
   % get the data to plot
   if ( any(strcmp(opts.disptype,{'imaget','mcplott','plott'})) )
      Ai = reshape(A(idx{:}),axsz([2 1]))'; % reversed x/y
   else
      Ai = reshape(A(idx{:}),axsz([1 2]));  % normal
   end;
   switch ( lower(opts.disptype) ) ;
    
    
    case {'plot','plott'}; %------------------------------------------------
     if ( ~isempty(varargin)) set(hdls(pi),varargin{:}); end;
     p=plot(hdls(pi),axscale{1},Ai,opts.plotopts{:});
     xlim=[min(axscale{1}) max(axscale{1})]; if(xlim(1)==xlim(2)) xlim=xlim(1)+[-.5 .5]; end;
     % set to nearest 1/100'th - needed to BODGE matlab tick-mark positioning bug...
     rng = 10.^(round(log10(xlim(2)-xlim(1)))-2); xlim = [floor(xlim(1)./rng) ceil(xlim(2)./rng)]*rng;
     axsettings={'color' 'none' 'XLim' xlim};
     if ( ~isnumeric(axmark{1}) ) 
        tickIdx=unique(floor(get(hdls(pi),'XTick')));
        tickIdx(tickIdx<1)=[]; tickIdx(tickIdx>numel(axmark{1}))=[];
        axsettings={axsettings{:} 'XTick',tickIdx,'XTickLabel',axmark{1}(tickIdx),...
                    'XTickMode','manual','XTickLabelMode','manual'};
     elseif( any(abs(diff(diff(axmark{1}(:)')))>1e-6) ) % non-uniform scaling
        tickIdx = [true abs(diff(diff(axmark{1})))>1e-6 true]; % locations of changes
        axsettings={axsettings{:} 'XTick' find(tickIdx) 'XTickLabel',axmark{1}(tickIdx) ...
                    'XTickMode','manual','XTickLabelMode','manual'};       
     else       
        axsettings={axsettings{:} 'XTickLabelMode' 'auto'};
     end
     if(~tickAxes(pi)) axsettings={axsettings{:} 'YTickLabel',[],'XTickLabel',[]};end;
     axsettings={axsettings{:} 'Ylim',clim};
     set(hdls(pi),axsettings{:}); 
     axsettings={axsettings{:} 'YTickLabelMode','auto'};
     set(hdls(pi),'userdata',axsettings);
     if ( ~tickAxes(pi) ) labvis='off'; else labvis='on'; end;
     if ( ~isempty(axlab{1}) ) xlabel(hdls(pi),axlab{1},'Visible',labvis); end;
     if ( ~isempty(opts.clabel) ) ylabel(hdls(pi),opts.clabel,'Visible',labvis); end;
     for j=1:numel(p); % setup the label for each line
        if(iscell(axmark{2})) ll=axmark{2}{j}; 
        else ll=num2str(axmark{2}(j));
        end
        dispNm=ll; if ( ~isempty(axlab{2}) )  dispNm=[axlab{2} ' ' dispNm]; end;
        set(p(j),'DisplayName',dispNm);
     end;      
    
    case {'image','imaget','imagesc','imagesct'}; %-------------------------------------
     if ( exist('OCTAVE_VERSION','builtin') ) % octave doesn't handle parent option well
       image('xdata',axscale{2}([1 end]),'ydata',axscale{1}([1 end]),'Cdata',Ai,'CDataMapping','scaled','Parent',hdls(pi),opts.plotopts{:});     
     else
       image(axscale{2},axscale{1},Ai,'CDataMapping','scaled','Parent',hdls(pi),opts.plotopts{:});
     end
     if ( ~isempty(varargin)) set(hdls(pi),varargin{:}); end;
     if ( ~isnumeric(axmark{1}) || any(sign(diff(axmark{1}))<0) ) 
        tickIdx=unique(max(1,floor(get(hdls(pi),'YTick')))); 
        axsettings={'YTick',tickIdx,'YTickLabel',axmark{1}(tickIdx),...
                    'YTickMode','manual','YTickLabelMode','manual'};
     else
        ylim=single([min(axscale{1}) max(axscale{1})]); if( ylim(1)==ylim(2) ) ylim=ylim+[-.5 .5]; end
        if ( exist('OCTAVE_VERSION','builtin') ) % add a slight buffer to outside
          ylim=ylim+diff(ylim)/size(Ai,1)*[-1 1];
        end
        axsettings={'YLim' ylim 'YTickLabelMode' 'auto'};        
     end
     if ( ~isnumeric(axmark{2}) ) 
        tickIdx=unique(max(1,floor(get(hdls(pi),'XTick')))); 
        axsettings={axsettings{:} 'XTick',tickIdx,'XTickLabel',axmark{2}(tickIdx),...
                    'XTickMode','manual','XTickLabelMode','manual'};
     elseif( any(abs(diff(diff(axmark{2})))>1e-6) ) % non-uniform scaling
        tickIdx = [true abs(diff(diff(axmark{2}(:)')))>1e-6 true]; % locations of changes
        axsettings={axsettings{:} 'XTick' find(tickIdx) 'XTickLabel',axmark{2}(tickIdx) ...
                    'XTickMode','manual','XTickLabelMode','manual'};       
     else
        xlim=single([min(axscale{2}) max(axscale{2})]); if( xlim(1)==xlim(2) ) xlim=xlim+[-.5 .5]; end
        if ( exist('OCTAVE_VERSION','builtin') ) % add a slight buffer to outside
          xlim=xlim+diff(xlim)/size(Ai,2)*[-1 1];
        end
        % set to nearest 1/100'th
        rng = 10.^(round(log10(xlim(2)-xlim(1)))-2); xlim=[floor(xlim(1)./rng) ceil(xlim(2)./rng)]*rng;
        axsettings={axsettings{:} 'XLim' xlim 'XTickLabelMode' 'auto'};
     end
     if(~tickAxes(pi)) axsettings={axsettings{:} 'YTickLabel',[],'XTickLabel',[]};end;
     axsettings={axsettings{:} 'clim' clim};
     set(hdls(pi),axsettings{:}); 
     set(hdls(pi),'userdata',axsettings);
     if ( ~tickAxes(pi) ) labvis='off'; else labvis='on'; end;
     if ( ~isempty(axlab{1}) ) ylabel(hdls(pi),axlab{1},'Visible',labvis); end
     if ( ~isempty(axlab{2}) ) xlabel(hdls(pi),axlab{2},'Visible',labvis); end;

     
    case {'mcplot','mcplott'}; %---------------------------------------------
     axes(hdls(pi));
     p=mcplot(axscale{1},Ai,'equalspacing',1,opts.plotopts{:});
     set(hdls(pi),'color','none');
     if ( ~isempty(varargin)) set(hdls(pi),varargin{:}); end;
     xlim=[min(axscale{1}) max(axscale{1})]; if(xlim(1)==xlim(2)) xlim=xlim(1)+[-.5 .5]; end;
     % set to nearest 1/100'th
     rng = 10.^(round(log10(xlim(2)-xlim(1)))-2); xlim = [floor(xlim(1)./rng) ceil(xlim(2)./rng)]*rng;
     axsettings={'XLim',xlim};
     if ( ~isnumeric(axmark{1}) ) 
        tickIdx=unique(floor(get(hdls(pi),'XTick'))); 
        axsettings={'XTickLabel',axmark{1}(tickIdx),...
                    'XTickMode','manual','XTickLabelMode','manual'};
     elseif( any(abs(diff(diff(axmark{1})))>1e-6) ) % non-uniform scaling
        tickIdx = [true abs(diff(diff(axmark{1}(:)')))>1e-6 true]; % locations of changes
        axsettings={axsettings{:} 'XTick' find(tickIdx) 'XTickLabel',axmark{1}(tickIdx) ...
                    'XTickMode','manual','XTickLabelMode','manual'};       
     else
        axsettings={axsettings{:} 'XTickLabelMode' 'auto'};
     end
     if ( ~isnumeric(axmark{2}) ) 
        axsettings={axsettings{:} 'YTickLabel' axmark{2} ...
                    'YTickMode' 'manual' 'YTickLabelMode' 'manual'};
     else
        axsettings={axsettings{:} 'YTickLabel' axmark{2} 'YTickMode' 'manual'};
     end
     set(hdls(pi),axsettings{:});      set(hdls(pi),'userdata',axsettings);
     if ( ~isempty(axlab{1}) ) xlabel(axlab{1},'Visible','off'); end;
     leg={};
     for j=1:numel(p); % setup the label for each line
        if( iscell(axmark{2}) ) leg{j}=axmark{2}{j}; 
        else leg{j}=num2str(axmark{2}(j));
        end
        leg{j}=[axlab{2} ' ' leg{j}];
        set(p(j),'DisplayName',leg{j});
      end;
     if ( ~isempty(axlab{1}) ) xlabel(axlab{1},'Visible','off'); end
     if ( ~isempty(axlab{2}) ) ylabel(axlab{2},'Visible','off'); end;
     
     
    otherwise; 
     if ( ~exist(opts.disptype) ) % isn't a function on the path
        error('Other disptypes arent implemented yet');
     else
        feval(opts.disptype,axscale{1},axscale{2},...
              Ai,axmark{1},axmark{2},axlab{1},axlab{2},opts.clabel,...
              opts.plotopts{:});
        if ( ~isempty(varargin)) set(hdls(pi),varargin{:}); end;
     end
   end
   
   %HACK! check for and fix overlapping tick labels caused by matlab bugs
   tmp=get(hdls(pi),'units');   set(hdls(pi),'units','pixels');   pos=get(hdls(pi),'position');      set(hdls(pi),'units',tmp);
   tmp=get(hdls(pi),'fontunit');set(hdls(pi),'fontunit','pixels');fontsize=get(hdls(pi),'fontsize'); set(hdls(pi),'fontunit',tmp);
   tickIdx=get(hdls(pi),'xtick'); ticks=get(hdls(pi),'xticklabel');
   % overlapping ticks
   if ( numel(ticks)*fontsize*.5   > pos(3) ) 
     if ( isnumeric(ticks) )
       % count number of leading/trailing 0's
       for i=1:numel(ticks);
         xl=ticks(i); 
         if ( max(xlim)<1 )
           for n0=0:-1:floor(log10(min(xlim))); if ( fix(xl*10)==0 ) xl=xl*10; else break; end; end;
           num0(i)=n0;
         elseif ( max(xlim)>1 )
           for n0=0:ceil(log10(max(xlim))); if ( mod(xl,10)==0 ) xl=xl/10; else break; end; end;
           num0(i)=n0;
         end
       end
       if ( all(num0>0) ) num0=min(num0); elseif( all(num0<0) ) num0=max(num0); else num0=0; end;
       if ( num0 )       
         set(hdls(pi),'xlabel',[get(hdls(pi),'xlabel') ' *' sprintf('%f',10.^num0)]);
         set(hdls(pi),'xtick',ticks*10.^-num0);
       else
         set(hdls(pi),'xtick',tickIdx([1,end]),'xticklabel',ticks([1,end]));  set(hdls(pi),'xminortick','on');
       end
     else
       keep = round(linspace(1,numel(tickIdx),pos(3)./(size(ticks,2)*fontsize*.5)));
       set(hdls(pi),'xtick',tickIdx(keep),'xticklabel',ticks(keep));  set(hdls(pi),'xminortick','on');
     end
   end
   tickIdx=get(hdls(pi),'ytick'); ticks=get(hdls(pi),'yticklabel');
   if ( (size(ticks,1)-1)*fontsize > pos(4) ) 
     set(hdls(pi),'ytick',tickIdx([1 end])); set(hdls(pi),'yminortick','on');
   end;

   if ( opts.showtitle && ~isempty(opts.titlepos) )
     if ( iscell(axscale{3}) ) % add the title
       t=title(hdls(pi),sprintf('%s %s',axlab{3},axscale{3}{pi}));
     else t=title(hdls(pi),sprintf('%s %g',axlab{3},axscale{3}(pi)));
     end
     set(t,'FontSize',14,'Units','Normalized','position',opts.titlepos,'FontWeight','bold'); % fix the position
     if ( opts.titlepos(1)<=.1 ) set(t,'HorizontalAlignment','left'); 
     elseif ( opts.titlepos(1)>=.9 ) set(t,'HorizontalAlignment','right');
     else set(t,'HorizontalAlignment','center'); 
     end
     if ( opts.titlepos(2)<=.1 ) set(t,'VerticalAlignment','bottom');
     elseif ( opts.titlepos(2)>=.9 ) set(t,'VerticalAlignment','top');
     else set(t,'VerticalAlignment','middle'); 
     end       
   end
   
end
% store axlimits in the figures userdata info, so works with clickplots
setappdata(gcf,'axsettings',axsettings);

if ( 0 )
% BODGE: change the drawing order to be from top to bottom so titles overlap the plot above
cld=get(gcf,'children');
axIdx=strcmp(get(cld,'type'),'axes'); nax=cld(~axIdx); cld=cld(axIdx); 
cpos=get(cld(axIdx),'outerposition'); if(iscell(cpos))cpos=cat(1,cpos{:});end;
[ans,si]=sort(cpos(:,2),'ascend');
set(gcf,'children',[nax;cld(si)]); % reorder drawing
% BODGE: stops some types of drawing bugs in matlab
% drawnow expose;
end;

if ( ~isempty(opts.legend) && ~isequal(opts.legend,0) )
  i=N+1;
  if ( numel(hdls)>N && ishandle(hdls(i)) )
    pos=get(hdls(i),'position');
  else % try to compute a good location
     % default to se position
     if ( isnumeric(opts.legend) && numel(opts.legend)==1 ) opts.legend='se'; end; 
      if ( ischar(opts.legend) ) 
          pos = get(hdls(1:N),'position'); if(iscell(pos)) pos=cat(1,pos{:}); end;
          %pos=pos(:,1:2)+pos(:,3:4)./2; % middle of the axes
          if( strfind(lower(opts.legend),'w') ) exPlot(1)=min(pos(:,1),[],1);
          else                                  exPlot(1)=max(pos(:,1),[],1);
          end
          if( strfind(lower(opts.legend),'s') ) exPlot(2)=min(pos(:,2),[],1);
          else                                  exPlot(2)=max(pos(:,2),[],1);
          end
          [rX,rY]=packBoxes([pos(:,1);exPlot(1)],[pos(:,2);exPlot(2)]);
          pos=[exPlot rX(end) rY(end)];
      elseif ( isnumeric(opts.legend) && numel(opts.legend)==2) % given pos
          pos = cell2mat(get(hdls,'position'));      
          [ans,pos]= posplot([pos(:,1);opts.legend(1)],[pos(:,2);opts.legend(2)],i,opts.plotPosOpts,'sizeOnly',1);
      else
          tmphdl  = subplot(w,h,w*h);
          pos=get(tmphdl,'position'); if( ~any(tmphdl==hdls) ) delete(tmphdl); end;
      end
      if ( 0 && pos(3)>0 && pos(4)>0 ) % only if could position it
          tpos = get(hdls(N),'position');
          if ( tpos(3)<pos(3) ) pos(1)=pos(1);           pos(3)=tpos(3); 
          else                  pos(1)=pos(1)+.1*pos(3); pos(3)=pos(3)*.8; 
          end;
          if ( tpos(4)<pos(4) ) pos(2)=pos(2)+pos(4)-.1*pos(4)-tpos(4);  pos(4)=tpos(4); 
          else                  pos(2)=pos(2)+.1*pos(4); pos(4)=pos(4)*.8; 
          end;
      end
  end
  % Only lines with DisplayName set earlier get legend entries!
  lines=findobj(get(hdls(N),'children'),'type','line');
  good=false(size(lines));for li=1:numel(lines);if(~isempty(get(lines(li),'DisplayName')))good(li)=true;end; end;
  legend(hdls(N),lines(good));
  leghdl=[]; try; leghdl=legend('show');catch;end;
  % get the size of the legend window and use it for the new window
  if ( ~isempty(leghdl) ) 
	 tpos=get(leghdl,'position'); 
	 pos(3:4)=tpos(3:4); 
	 if ( ischar(opts.legend) )
		if( strfind(lower(opts.legend),'e') ) pos(1)=min(pos(1),1-pos(3)); end; 
		if( strfind(lower(opts.legend),'n') ) pos(2)=min(pos(2),1-pos(4)); end;
	 end
	 if ( all(pos(3:4)>0) ) % only if possible
		set(leghdl,'position',[pos(1:2) pos(3:4)],'box','off');
	 end
	 hdls(N+1)=leghdl;
  end
end % if legend

if ( ~isempty(opts.colorbar) && opts.colorbar && ~isempty(opts.clim) )  % true colorbar  
  if ( isempty(legendpos) )
    pos = opts.plotPosOpts.plotsposition; pos(3)=pos(3)*.95;
    packplots(hdls,opts.plotPosOpts,'plotsposition',pos);
    pos=[.93 .0 .07 1];
  else
    pos=legendpos;
  end
  % add some room for the axes marks as we can't use outer-position any more...
  pos(3)=max(.1,pos(3)-.02); pos(2)=max(pos(2),.05); pos(3)=min(.07,1-pos(1)-.05); pos(4)=min(1-pos(2)-.05,pos(4));
  if ( exist('OCTAVE_VERSION','builtin') ) % in octave have to manually convert arrays..
    tmp=get(hdls(N),'position');
    hdls(N+1)=colorbar('peer',hdls(N),'position',pos); %BUG: octave resizes axes even if give colorbar size
    set(hdls(N),'position',tmp);
    set(hdls(N+1),'position',pos);
  else    
    % bug in Matlab 2014b -- colorbar doens't correctly accept arguments
    axes(hdls(N));
    hdls(N+1)=colorbar();
    set(hdls(N+1),'position',pos);
  end
  if ( ~isempty(opts.clabel) ) title(hdls(end),opts.clabel); end;
end % if colorbar

if ( nargout>0 ) varargout{1}=hdls; end;
return;

%--------------------------------------------------------------------------
function testcase()
X=randn(3,5,10);
image3d(X,1)
image3d(X,2)
image3d(X,3)
clf;image3d(X,3,'plotPos',[sin(2*pi.*[1:10]/10);cos(2*pi*[1:10]/10)]')
clf;image3d(X,3,'plotPos',[sin(2*pi.*[1:10]/10);cos(2*pi*[1:10]/10)]','disptype','plot')
clf;image3d(X,3,'plotPos',[sin(2*pi.*[1:10]/10);cos(2*pi*[1:10]/10)]','disptype','plot','colorbar',0,'legend',1)
