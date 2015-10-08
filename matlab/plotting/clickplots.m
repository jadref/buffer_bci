function clickplots(varargin)
% CLICKPLOTS    allow subplots of a figure to be zoomed and unzoomed
% 
%   CLICKPLOTS or CLICKPLOTS(FIGHANDLE) enables subplots on the current
%   figure, or the figure specified by FIGHANDLE, to be enlarged and
%   shrunk with a mouse click.
%   
%   Additional arguments specify AXES object properties that come into
%   effect when a subplot is enlarged, e.g.:
%     CLICKPLOTS('PlotBoxAspectRatio', [1.618 1 1])
%     
%   While enlarged, the 'UserData' property of an AXES object saves
%   the object's properties as they were before enlargement, in order
%   to allow them to be restored at the next click.
		
h = [];
if ~isempty(varargin)
	if isnumeric(varargin{1}), h = varargin{1}; varargin(1) = []; end
end
if isempty(h), h = get(0, 'currentfigure'); end
if length(varargin) == 1
	if iscell(varargin{1}), varargin = varargin{1}; end
end

h = h(ishandle(abs(h)));
if isempty(h), return, end
h = h(1);
up = (sign(h) > 0);
h = abs(h);

hideSetting = get(0, 'showhiddenhandles');

if strcmp(get(h, 'type'), 'figure')
	set(0, 'showhiddenhandles', 'off');
	set(findobj(get(h, 'children')), 'buttondownfcn', 'clickplots(gcbo)')
	setappdata(h, 'axsettings', varargin)
	set(0, 'showhiddenhandles', hideSetting);
	return
end

while ~strcmp(get(h, 'type'), 'axes')
	h = get(h, 'parent');
	if h == 0, return, end
end	

set(0, 'showhiddenhandles', 'on');
fig = get(h, 'parent');
keyHandle = findobj('tag', 'key', 'userdata', h);
otherAxes = setdiff(findobj(fig, 'type', 'axes'), [h;keyHandle(:)]);
set(0, 'showhiddenhandles', 'off');
if up
	props = getappdata(fig, 'axsettings'); if ~iscell(props), props = {}; end
	props = {'units', 'normalized', 'position', [0.1 0.1 0.8 0.8] props{:}'};
	saveProps = get(h, props(1:2:end));
	set(h, props{:})
	props(2:2:end) = saveProps;
	set(findobj(otherAxes), 'visible', 'off')
	set(findobj(h), 'visible', 'on', 'buttondownfcn', 'clickplots(-gcbo)')
   % make axes info appear when zoomed
   if( isempty(get(h,'XTickLabel')) ) 
      set(h,'XTickLabelMode','auto'); props={props{:} 'XTickLabel' []};
   end
   if( isempty(get(h,'YTickLabel')) ) 
      set(h,'YTickLabelMode','auto'); props={props{:} 'YTickLabel' []};
   end
   if ( iscell(props{2}) && ~isempty(props{2}{1}) ) set(h,props{2}{:}); end;
	set(h, 'userdata', props)
else
	props = get(h, 'userdata');
	if iscell(props) & ~isempty(props), set(h, props{:}), end
   set(findobj(findobj(get(gcf,'children'),'flat','type','axes')), 'visible', 'on')
	set(findobj(h), 'buttondownfcn', 'clickplots(gcbo)')
end
set(0, 'showhiddenhandles', hideSetting);
