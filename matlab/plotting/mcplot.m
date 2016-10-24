function [varargout]=mcplot(X,varargin)
% multi channel plot
% 
% hdl=mcplot(X,[options,varargin])
% OR
% hdl=mcplot(xs,X,[options,varargin])
%
% Inputs:
%  X  -- [nSamp x nCh] matrix of lines to plot
%  xs -- [nSamp x 1] vector of values for the x-axis
%  varargin -- options to pass to plot
% Options:
%  gap     -- [1x1] spacing between line centers
%  padding -- [1x1] amount of space to leave between plots
%  center  -- [bool] flag if we center each line first
%             [float] value about which to center the data
%  labels  -- {nCh x 1} string listing the names of the channels/lines
%  xlabel,ylabel,title -- info for the plot
%  minorTick -- [bool] flag if we put a scale/unit-bar "thing" on each line  (1)
%  equalspacing -- [bool] flag if we put equal space between lines (1)
%  ygrid     -- [bool] flag if we put a 0-line for each line.     (1)
opts=struct('gap',[],'padding',0,'equalspacing',1,'labels',[],'center',1,...
            'xlabel',[],'ylabel',[],'title',[],'minorTick',1,'ygrid',1);
% Identify the calling type
xs=1:size(X,1);
if( nargin>1 && isnumeric(varargin{1}) ) % X,xs form
   xs=X;X=varargin{1};varargin(1)=[]; 
end 
[opts,varargin]=parseOpts(opts,varargin);

% make X have the right shape -- it we work like plot
if ( numel(xs)~=size(X,1) ) X=X'; end; % swap X/Y if wanted

% compute min gap to leave between the orgin of the plots
mu =mean(X,1);
if ( ~opts.center ) 
   rng=[max(X,[],1);min(X,[],1)];
else
   if ( isequal(opts.center,1) )
      rng=[max(X,[],1)-mu;min(X,[],1)-mu];
   else
      rng=[max(X,[],1)-opts.center;min(X,[],1)-opts.center];
   end
end
npts=isinf(rng(:)) | isnan(rng(:));
if ( all(npts) )  rng(1,:)=1; rng(2,:)=0; 
elseif ( any(npts) ) % fix +/- inf ranges
   npts=isinf(rng) & rng<0; rng(npts)=min(rng(~npts(:))); 
   npts=isinf(rng) & rng>0; rng(npts)=max(rng(~npts(:))); 
   npts=isnan(rng);         rng(npts)=mean(rng(~npts(:)));
end;
if ( isempty(opts.gap) ) 
   if ( opts.center ) 
      gap = abs(max(abs(diff(X,[],2)),[],1) - max(abs(diff(mu,[],2)),[],1));
   else
      gap = max(abs(diff(X,[],2)),[],1);
   end
else % use the given spacing   
   gap = opts.gap;
   gap(end+1:size(X,2)-1)=gap(end);
end

if ( opts.equalspacing ) gap(:)=max(gap); end;
if ( opts.padding~=0 ) gap=gap+opts.padding; end;%*(diff(rng(:,2:end),[],1)+diff(rng(:,1:end-1),[],1))./2; 

gap(gap<eps)=1;
npts=isinf(gap(:)) | isnan(gap(:));
if( all(npts) ) gap(:)=1; 
elseif( any(npts) ) 
   npts=isinf(gap) & rng<0; gap(npts)=min(gap(~npts(:))); 
   npts=isinf(gap) & rng>0; gap(npts)=max(gap(~npts(:))); 
   npts=isnan(gap);         gap(npts)=mean(gap(~npts(:)));
end

% Now transform the data to make the plot.
dX = cumsum([0 gap]); 
lineY=dX;
if( opts.center ) % include shifting points to middle
   if ( isequal(opts.center,1) )
      dX=dX-mu; 
   else
      dX=dX-opts.center;
   end
end; 
pX = repop(X,'+',dX);

if ( isnumeric(xs) ) 
  hdl=plot(xs,pX,varargin{:});
else
  hdl=plot(pX,varargin{:});
  tickIdx=unique(floor(get(gca,'XTick')));
  tickIdx(tickIdx<1)=[]; tickIdx(tickIdx>numel(xs))=[];
  set(gca,'XTick',tickIdx,'XTickLabel',xs(tickIdx));
end

axis tight
if ( numel(gap)>0 ) % set y-range so covers the data
   set(gca,'Ylim',[lineY(1)+min(rng(2,1),-gap(1)/2) lineY(end)+max(rng(1,end),gap(end)/2)]);
end

if ( ~isempty(opts.xlabel) ) xlabel(opts.xlabel); end;
if ( ~isempty(opts.ylabel) ) ylabel(opts.ylabel); end;
if ( ~isempty(opts.title) ) title(opts.title); end;
if ( opts.ygrid ) set(gca,'ygrid','on'); end;

if ( ~isempty(opts.labels) ) % put tick marks at line orgins   
   set(gca,'YTick',cumsum([0 gap]),'YTickLabel',opts.labels);
elseif ( size(X,2)>1 )
   set(gca,'YTick',cumsum([0 gap]),'YTickLabel',1:size(X,2)); 
end

% set the minor ticks to indicate the scaling
if ( opts.minorTick && size(X,2)>1 ) 
   % get range of the data
   range = .5*gap; % .%*range
   if ( isempty(range) )    
      range = [max(X,[],1)-min(X,[],1)]; % range of each line
      range(range==0)=1;
   end
   % find a nice slicing for gap.
   % try powers of 10 with 1,2,4,5 divisions to give 2/3 marks per line
   expon = floor(log10(max(range)));
   irange = max(range)*10.^(-expon); % round up the gap, should now be ~O(10)
   switch( floor(irange) );
    case 1;     expon=expon-1; mark=[5 10]; 
    case {2,3}; mark=2; 
    case {4,5}; mark=[2 4];
    case {6,7}; mark=[4];
    case 8;     mark=[4 8];
    case 9;     mark=5;
    case 10;    mark=[5 10];
   end
   mark = mark*10.^(expon); % convert back to real units
   % now draw it
   xlim=get(gca,'xlim'); xpos   = xlim(1)+.05.*(xlim(2)-xlim(1));
   isheld = ishold;
   % only bottom line gets tick-marks
   hold on;plot(xpos*ones(2,size(X,2)),[-1 +1]'*mark(1),'k');%repop(cumsum([0 gap]),'+',[-1 +1]'*mark(1)),'k');
   for pi=1:numel(mark);
      text(xpos+.02.*(xlim(2)-xlim(1)),double(mark(pi)),num2str(mark(pi)),'FontSize',8,'HorizontalAlignment','left');      
   end
   if ( ~isheld ) hold('off'); end;
end

if ( nargout>0 ) varargout{1}=hdl; end;
return;
%------------------------------------------------------------------
function testCase()
nCh=12; nSamp=100;
X=randn(nCh,nSamp); X=cumsum(X,2);

mcplot(X,'padding',.5,'labels',1:nCh)
mcplot(wX(:,:,1),'padding',.5,'equalspacing',1,'labels',{'ch_wht 1','ch_wht 2'})

% plot with a given center location
mcplot(X,'padding',.5,'labels',1:nCh,'center',.5);grid on;
