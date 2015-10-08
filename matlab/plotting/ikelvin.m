function c = ikelvin(m,w)

if( nargin<1 || isempty(m) ) m = size(get(gcf,'colormap'),1); end
if( nargin<2 || isempty(w) ) w = [.1 .3]; end;
if ( numel(w)==1 ) w = [.5*w w+.5*(.5-w)]; end;

%  pos     hue   sat   value
cu = [
	0.0     1/2   0     1.0
   w(1)    1/2   0.6   0.95
   w(2)    2/3   1.0   0.8
	0.5     2/3   1.0   0.3
];

cl = cu;
cl(:, 3:4) = cl(end:-1:1, 3:4);
cl(:, 2)   = cl(:, 2) - 0.5;
cu(:,1)    = 1-cu(end:-1:1,1);

x = linspace(0, 1, m)';
l = (x < 0.5); u = ~l;
for i = 1:3
	h(l, i) = interp1(cl(:, 1), cl(:, i+1), x(l));
	h(u, i) = interp1(cu(:, 1), cu(:, i+1), x(u));
end
h = flipud(h);
c = hsv2rgb(h);

return
