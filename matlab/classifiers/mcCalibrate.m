function [Ab]=mcCalibrate(Y,dv,verb)
% scale the outputs of multi-class classifier to representative of it's confidence
  
dv = repop(dv,'-',max(dv,2)); %pre-fix the numerical issues
				  % BODGE: simple grid search.....
sf=[-3.5:.5:.5];
% track the best solution found
sbesti=0; Edbest=inf;
for si=1:numel(sf);
  sfi =2.^sf(si);
  dvAb=dv*sfi;
  p   =exp(dvAb); p=repop(p,'./',sum(p,2));
  % log-entropy loss
  Ed  =0; for i=1:size(p,1); Ed = Ed+ -log(p(i,Y(i,:)>0)); end;
  if ( Ed<Edbest )
	 Edbest = Ed;
	 sbesti = si;
  end  
  fprintf('%2d) sf=%6.4f\t Ed=%g\n',si,sfi,Ed);
end
Ab=[exp(sf(sbesti));0];
