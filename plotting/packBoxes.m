function [rX,rY]=packBoxes(Xs,Ys)
% Give a set of X,Y positions pack non-overlapping rectangular boxes 
%
% [rX rY]=packBoxes(Xs,Ys)
% Inputs:
% Xs - [N x 1] x positions
% Ys - [N x 1] y positions
% Outputs:
% rX - [N x 1] x radius
% rY - [N x 1] y radius
Xs=Xs(:); Ys=Ys(:); % ensure col vecs
N=size(Xs,1);

% Now, Find the all plots pairwise distance matrix, w.r.t. this scaling
Dx = abs(repop(Xs,'-',Xs')); 
Dy = abs(repop(Ys,'-',Ys')); 

for i=1:N;  % radius limit is when x dis is less than y dis
   Dx(i,i)=inf; Dy(i,i)=inf; % exclude the self distance
   rX(i,1) = min( Dx(Dx(:,i)>=Dy(:,i),i) )/2;
   rY(i,1) = min( Dy(Dx(:,i)<=Dy(:,i),i) )/2;
end

% Unconstrained boundaries are limited by the max/min of the constrained ones
% or .5 if nothing else...
if( any(isinf(rX)) ) % any unconstrained?
   if( all(isinf(rX)) ) rX(:)=.5; % all unconstrained?
   else % some unconstrained, use constrained bits to set sizes
      consX=~isinf(rX);
      rX(~consX) = 0; minX = min(Xs-rX); maxX = max(Xs+rX);   
      rX(~consX) = min(maxX-Xs(~consX),Xs(~consX)-minX); 
   end;
end
if( any(isinf(rY)) ) % any unconstrained?
   if( all(isinf(rY)) ) rY(:)=.5; % all unconstrained?
   else % some unconstrained, use constrained bits to set sizes
      consY=~isinf(rY);
      rY(~consY) = 0; minY = min(Ys-rY); maxY=max(Ys+rY);   
      rY(~consY) = min(maxY-Ys(~consY),Ys(~consY)-minY);
   end;
end

 
return;
%---------------------------------------------------------------------------
function testCase()
Xs=randn(10,1); Ys=randn(10,1); [rX rY]=packBoxes(Xs,Ys);

Xs=1:10; Ys=1:10; [rX rY]=packBoxes(Xs,Ys);

Xs=repmat(1:4,1,3); Ys=repmat(1:4,3,1); [rX rY]=packBoxes(Xs,Ys);

% Plot the result
for i=1:numel(Xs); 
   rectangle('position',[Xs(i)-rX(i) Ys(i)-rY(i) 2*rX(i) 2*rY(i)], 'EdgeColor',linecol(i));hold on; 
end;
