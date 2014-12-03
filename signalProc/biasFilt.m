function [x,s]=biasFilt(x,s,alpha)
% bias removing filter (high-pass) removes slow drifts from inputs
%
%   [x,s,mu,std]=stdFilt(x,s,alpha)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   alpha - [float] exponiential decay factor for the moving average
% Outputs:
%   x - [nd x 1] filtered data
%   s - [struct] updated filter state
if ( isempty(s) ) s=zeros(size(x)); end;
s=alpha*s + (1-alpha)*x; % exp-decay moving average
x=x-s;
return;
function testCase()
x=cumsum(randn(2,1000),2);
fs=[]; fx=[]; s=[]; for i=1:size(x,2); [fx(:,i),si]=biasFilt(x(:,i),s,exp(log(.5)/10)); fs(:,i)=si; s=si; end;
clf;for si=1:size(x,1); subplot(size(x,1),1,si); plot([x(si,:);fx(si,:);fs(si,:)]');legend('x','filt(x)','bias');end;
s=[]; for i=1:size(x,2); [fx(i),si]=biasFilt(x(:,i),s,exp(log(.5)/100)); fs(i)=si; s=si; end;
