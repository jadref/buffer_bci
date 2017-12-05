function [x,s,b]=percentialFilt(x,s,alpha,pr)
% percential bias removing filter removes slow drifts from inputs
%
%   [x,s,b]=biasFilt(x,s,alpha,pr)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   alpha - [1 x 1] number of previous inputs to store to compute the percential
%   pr    - [1 x 1] target output percential
% Outputs:
%   x - [nd x 1] filtered data,  x(t) = x(t) - {b: Pr(x<b)=pr}
%   s - [struct] updated filter state
%   b - [nd x 1] estimated threshold at pr percential
if ( nargin<4 || isempty(pr) ) pr=.5; end;
if ( isempty(s) ) s=struct('x',0,'i',0); end;

if ( isscalar(s.x) ) s.x = zeros(numel(x),ceil(alpha)); s.i=0; end;
s.x(:,mod(s.i,size(s.x,2))+1) = x(:); % insert in ring buffer
s.i = s.i+1;
nf  = min(s.i,size(s.x,2)); % num valid entries in window

% sort and extract the target percential
sx = sort(s.x(:,1:nf),2,'ascend');
b  = sx(:,ceil(pr*nf)); 
% bias adapt
x  = x-b; 

return;
function testCase()
x=cumsum(randn(2,1000),2);

% simple test
s=[];fs=[];fx=[];for i=1:size(x,2); [fx(:,i),si,fs(:,i)]=percFilt(x(:,i),s,500); s=si; textprogressbar(i,size(x,2)); end;
s=[];fs=[];fx=[];for i=1:size(x,2); [fx(:,i),si,fs(:,i)]=percFilt(x(:,i),s,500,.9); s=si; textprogressbar(i,size(x,2)); end;

sum(fx>0,2)./size(fx,2), % compute the actually percental

clf;for si=1:size(x,1); subplot(size(x,1),1,si); plot([x(si,:);fx(si,:);fs(si,:)]');legend('x','filt(x)','bias');end;set(gca,'ylim',median(x(:))+[-4 4]);