function [x,s]=biasFilt(x,s,alpha)
% bias removing filter (high-pass) removes slow drifts from inputs
%
%   [x,s,mu,std]=stdFilt(x,s,alpha)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   alpha - [1 x 1] OR [nd x 1] exponiential decay factor for the moving average for 
%                   all [1x1] or each [ndx1] input feature
%           fx(t) = (\sum_0^inf x(t-i)*alpha^i)/(\sum_0^inf alpha^i)
%           fx(t) = (1-alpha) x(t) + alpha fx(t)
% Outputs:
%   x - [nd x 1] filtered data,  x(t) = x(t) - fx(t)
%   s - [struct] updated filter state
if ( isempty(s) ) s=zeros(size(x)); end;
s=alpha(:).*s + (1-alpha(:)).*x; % exp-decay moving average
x=x-s;
return;
function testCase()
x=cumsum(randn(2,1000),2);

% simple test
s=[];for i=1:size(x,2); [fx(:,i),si]=biasFilt(x(:,i),s,exp(log(.5)/100)); fs(:,i)=si; s=si; end;
% feature specific smoothers
s=[];for i=1:size(x,2); [fx(:,i),si]=biasFilt(x(:,i),s,[exp(log(.5)/100);exp(log(.5)/1000)]); fs(:,i)=si; s=si; end;

clf;for si=1:size(x,1); subplot(size(x,1),1,si); plot([x(si,:);fx(si,:);fs(si,:)]');legend('x','filt(x)','bias');end;
