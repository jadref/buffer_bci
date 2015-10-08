function [h]=plotCapMontage(capFile,electrodes) 
% plot the electrode montages
%
%   [h]=plotCapMontage(capFile,electrodes)
%
% Inputs:
%  capFile -- [str] name of file to read the cap information from  ('1010')
%     OR
%             [2 x nCh] set of 2d positions for the cap electrodes
%  electrodes -- { electrode names } subset of electrode names to plot in the montage
%     OR
if (nargin<1 || isempty(capFile) ) capFile='1010'; end;
if (isstr(capFile) ) % file name to load
  [Cname,ll,xy,xyz]=readCapInf(capFile);
elseif ( isnumeric(capFile) && size(capFile,1)==2 ) % electrode positions
  xy=capFile; capFile=[];
elseif ( isstruct(capFile) && isfield(capFile,'vals') ) % dim-info
  iseeg=[capFile.extra.iseeg];
  Cname=capFile.vals(iseeg); xy=[capFile.extra(iseeg).pos2d]; xyz=[capFile.extra(iseeg).pos3d];
end

% which electrodes to plot
ploti=true(numel(Cname),1);
if ( nargin>1 && ~isempty(electrodes) )
  if ( isempty(capFile) ) 
    Cname=electrodes; 
  else    
    for si=1:numel(ploti); 
      if ( any(strcmp(electrodes{si},Cname)) ) ploti(si)=true; else ploti(si)=false; end; 
    end;
  end
end
     
% make the plot
topohead(xy); hold on; 
h1=plot(xy(1,ploti),xy(2,ploti),'ob','markersize',7,'linewidth',8,'color',[1 1 1]*.7); 
h2=text(xy(1,ploti),xy(2,ploti),Cname(ploti),'HorizontalAlignment','center','verticalalignment','middle','color',[0 0 0],'fontweight','bold');
set(gca,'visible','off');
hold off;
%saveaspdf('montages');
h=[h1(:);h2(:)]; % return handles to the bits
return;
function testCase()
plotCapMontage()