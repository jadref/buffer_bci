function [mb,record]=updateClocks(record,S,T)
% least squares 1d scale+offset tracking of 2 clocks, using rls method
%
%   [mb,record]=updateClocks(record,sample,time)
if ( nargin<2 ) record=[]; return; end;
if ( isempty(record) || ~isstruct(record) )
  if ( ~isempty(record) && isnumeric(record) ) % record is the half-life to use
    hl=record; clear record; % stop mlab complaining
    record.alpha = exp(-log(2)./hl);
  else
    % forgetting factor : .97=22 updates.99=70 updates, .999=700 updates
    record.alpha = .999;%exp(-log(2)/1000);
  end
  % init assuming everything before now was the same as the 1st example
  record.S0 =mean(S);record.T0=mean(T);
  record.N  =0;%1/(1-record.alpha);
  record.sS =0;   record.sT =0; 
  record.sS2=0;   record.sT2=0; 
  record.sST=0; 
  %S=S(2:end); T=T(2:end);
end
% remove bias for numerical stability
S          =S-record.S0;
T          =T-record.T0;
% update the statistics
for i=1:numel(S);
  record.N   =record.alpha*record.N  +1;
  record.sS  =record.alpha*record.sS +S(i);
  record.sT  =record.alpha*record.sT +T(i);
  record.sS2 =record.alpha*record.sS2+S(i)*S(i); % unused
  record.sT2 =record.alpha*record.sT2+T(i)*T(i);
  record.sST =record.alpha*record.sST+S(i)*T(i);
end
% compute the ls solution
%mb    = [record.sT2 record.sT; record.sT record.N]\[record.sST;record.sS];
%mb(2) = mb(2) + record.S0 - mb(1)*record.T0;
mb(1) = (record.sST - record.sS*record.sT/record.N)./(record.sT2 - record.sT*record.sT/record.N);
mb(2) = record.sS/record.N+record.S0 - mb(1)*(record.sT/record.N+record.T0);
return;
function testCase()
% test the validaty of the method
