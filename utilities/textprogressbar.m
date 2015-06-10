function [str]=textprogressbar(i,toti,nbits,chr)
% really simple text based progress bar
% 
% [str]=textprogressbar(i,toti,nbits,chr)
% Inputs:
%  i    -- current iteration number
%  toti -- total number of iterations
%  nbits-- number of times to update the screen (100)
%  chr  -- char to indicate 1 bit done ('.')
if ( nargin<3 ); nbits=100; end;
if ( nargin<4 ); chr='.'; end
si=round(i/(toti/nbits)); % nearest step indicator
%fprintf('\n%d %d %d',i,si,round(si*toti/nbits));
if ( toti>1 && i==round(si*toti/nbits) ) 
   str=chr;
   if( toti<nbits ); str=repmat(str,1,max(1,si-round((i-1)/(toti/nbits))));  end
   if ( nargout==0 ); fprintf(str); end
else
   str='';
end;
return;
%---------------------------------------------------------------
function testCase()
toti=7;  for i=1:toti; textprogressbar(i,toti); end; fprintf('\n');
toti=127;for i=1:toti; textprogressbar(i,toti); end; fprintf('\n');
toti=200;for i=1:toti; textprogressbar(i,toti); end; fprintf('\n');

