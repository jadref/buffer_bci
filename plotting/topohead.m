function [hdls]=topohead(coords,varargin)
% plot the head of a topo-plot
%
% [h]=topohead(coords,layout)
% Inputs:
%  coords -- [N x 2] matrix of x,y electrode co-ords (used to scale head) (1)
opts=struct('ear2d',2*[.497  .510  .518  .5299 .5419  .54    .547   .532   .510   .489;...
                       .0555 .0775 .0783 .0746 .0555 -.0055 -.0932 -.1313 -.1384 -.1199],...
            'nose2d',[0.18 0 -0.18;1-.004,1.15,1-.004],'rmax',2,'head',2,'color',[0 0 0]);
[opts,varargin]=parseOpts(opts,varargin);

if ( nargin < 2 || isempty(coords) ) coords=1; end;
% scale electrodes to unit circle
rmax=opts.rmax; if ( isempty(rmax) ) rmax = max(sqrt(sum(coords.^2))); end;

% plot head, ears, nose
hdls(1)=plot(cos(linspace(0,2*pi,40)).*rmax,sin(linspace(0,2*pi,40)).*rmax, 'k-', 'LineWidth', opts.head,'Color',opts.color);
hold on;
hdls(2)=plot( opts.nose2d(1,:)*rmax, opts.nose2d(2,:)*rmax, 'k-', 'LineWidth', opts.head,'Color',opts.color);
hdls(3)=plot( opts.ear2d(1,:)*rmax, opts.ear2d(2,:)*rmax, 'k-', 'LineWidth', opts.head,'Color',opts.color);
hdls(4)=plot(-opts.ear2d(1,:)*rmax, opts.ear2d(2,:)*rmax, 'k-', 'LineWidth', opts.head,'Color',opts.color);
set(gca,'xlim',[-1.15 1.15]*rmax,'ylim',[-1.15 1.15]*rmax);
hold off;
return;
%-----------------------------------------------------------------
function testcase();
