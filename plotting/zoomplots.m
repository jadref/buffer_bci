function []=zoomplots(varargin)
% zoom in on a specified set of sub-plots, left-mouse=zoom-in, right-mouse=reset zoom
%
%  zoomplots(fig,...)
%
% N.B. left-mouse = select bounding box of sub-plots to zoom
%      right-mouse= zoom back out to the orginal figure settings
%
% Inputs:
%   fig - [handel] handle to the figure to zoom in on.         (gcf)
% Options:
%   bbox - [4x1] bounding box in figure relative co-ordinates containing the 
%      subplots to zoom in on
%   
opts=struct('bbox',[],'plotsposition',[.05 .05 .9 .9],'interplotgap',0,'postype','position');
fighdl = [];
if( ~isempty(varargin) )
	if( isnumeric(varargin{1}) ) fighdl = varargin{1}; varargin(1) = []; end
end
if( isempty(fighdl) ) fighdl = get(0, 'currentfigure'); end
[opts,varargin]=parseOpts(opts,varargin);
if ( ~isempty(opts.interplotgap) && numel(opts.interplotgap)<4 ) 
   opts.interplotgap(end+1:4)=opts.interplotgap(end); 
end;

%fighdl = fighdl(ishandle(abs(fighdl)));
if isempty(fighdl), return, end


if ( isempty(gcbo) ) % not executing call-back so just install required callbacks..
  set(fighdl,'units','normalized');
  %set(gcf,'buttondownfcn',@(gcb,varargin) zoomplots(gcb,'bbox',rbbox));
  set(fighdl,'windowbuttondownfcn',@(gcb,varargin) zoomplots(gcb,'bbox',rbbox,varargin{:}));
  
elseif ( fighdl>0 && strcmp(get(fighdl,'SelectionType'),'normal') ) % zoom in
   bbox=opts.bbox;
   
  % find all axes completely within the bounding box
  hdls = findobj(fighdl,'type','axes','visible','on'); % *visible* sub-axes of the current figure
  if ( isempty(hdls) ) return; end;
  pos=get(hdls,opts.postype); if(iscell(pos)) pos=cell2mat(pos)'; else pos=pos(:); end;
  idx = pos(1,:)>=bbox(1) & pos(2,:)>=bbox(2) & ...
        pos(1,:)+pos(3,:)<=bbox(1)+bbox(3) & pos(2,:)+pos(4,:)<=bbox(2)+bbox(4);

  if ( sum(idx)==0 ) return; end; % do nothing if no plots to zoom
  
  % compute the transformation from the orginal viewport to the new one
  c = [-(bbox(1)+bbox(3)/2) -(bbox(2)+bbox(4)/2)]; % translate
  w = [opts.plotsposition(3)./bbox(3) opts.plotsposition(3)./bbox(4)]; % rescale
  c2= [.5 .5];

  hiddenhdls=hdls(~idx); 
  for hi=1:numel(hiddenhdls);
     h=hiddenhdls(hi);
     udata=get(h,'userdata');
     saveprops={'zoomplots' 'visible' get(h,'visible')};
     if ( isempty(udata) )
        set(h,'userdata',{saveprops});
     elseif ( ~iscell(udata) || ~iscell(udata{1}) || ~isequal(udata{1}{1},'zoomplots') )
        set(h,'userdata',{saveprops udata});
     end
     set(h,'visible','off');
     set(findobj(h),'visible','off','hittest','off'); % and children
  end
  visiblehdls=hdls(idx);
  % move the position of the visible handles
  for hi=1:numel(visiblehdls);
    h=visiblehdls(hi);
    %if ( strcmp(get(h,'visible'),'off') ) continue; end;
    poshi=get(h,opts.postype);
    udata=get(h,'userdata');
    saveprops={'zoomplots' opts.postype poshi 'visible' get(h,'visible')};
    if ( isempty(udata) )
       set(h,'userdata',{saveprops});
    elseif ( ~iscell(udata) || ~iscell(udata{1}) || ~isequal(udata{1}{1},'zoomplots') )
       set(h,'userdata',{saveprops udata});
    end
    set(h,opts.postype,[(poshi(1:2)+c).*w+c2+opts.interplotgap(1:2) poshi(3:4).*w-opts.interplotgap(3:4)]); % scale and translate
 end
 
  % modify the callbacks to zoom out next time
  %set(fighdl,'windowbuttondownfcn',@(gcb,varargin) zoomplots(-gcb,varargin{:})); % on release undo the zoom
  
elseif ( fighdl<0 || ~strcmp(get(fighdl,'selectiontype'),'normal') ) % zoom back
  fighdl=abs(-fighdl);
  hdls = findobj(fighdl,'type','axes'); % sub-axes of the current figure
  for hi=1:numel(hdls);
    h=hdls(hi);
    udata = get(h, 'userdata');
    if ( iscell(udata) && iscell(udata{1}) && isequal(udata{1}{1},'zoomplots') )
       set(h, udata{1}{2:end});
       % restore previous user data
       if( numel(udata)>1 ) set(h,'userdata',udata{2}); else set(h,'userdata',[]); end;
    end
    set(findobj(get(h,'children')),'visible','on','hittest','on');
 end  
  % modify callback to zoom in the next time
  set(fighdl,'windowbuttondownfcn',@(gcb,varargin) zoomplots(gcb,'bbox',rbbox,varargin{:}));
end
return;

function testcase()
clf;subplot(3,3,1);subplot(3,3,2);subplot(3,3,4);