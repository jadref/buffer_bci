function rgb =trafficlight(n);
% RAINBOW(n) creates a colormap, ranging from green via orange to red.
if nargin == 0, n = size(get(gcf,'colormap'),1); end
m = fix(n/2);
step = 1/m;
ltop = ones(m+1,1);
stop = ones(m,1);
lbot = zeros(m+1,1);
sbot = zeros(m,1);
lup = (0:step:1)';
sup = (step/2:step:1)';
ldown = (1:-step:0)';
sdown = (1-step/2:-step:0)';
if n-2*m == 1
   rgb = ([lup ltop lbot;stop sdown sbot]);
else
   rgb = ([sup stop sbot;stop sdown sbot]);
end