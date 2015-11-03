function [Cname latlong xy xyz capFile]=readCapInf(cap,capRoots)
% read a cap file
% 
% [Cname latlong xy xyz]=readCapInf(cap,capDir)
%
% Inputs:
%  cap     -- file name of the cap-file
%  capRoot -- directory(s) to look for caps in ({'.',mfiledir'/positions'})
if ( nargin<2 || isempty(capRoots) ) 
   capRoots = {'.',fileparts(mfilename('fullpath')),fullfile(fileparts(mfilename('fullpath')),'./positions'),fullfile(fileparts(mfilename('fullpath')),'./caps'),''};
 end
 if ( ischar(capRoots) ); capRoots={capRoots}; end;
[capDir capFn capExt]=fileparts(cap);
% search given directories for the capfile
for cr=1:numel(capRoots);
  capRoot=capRoots{cr};
  if ( ~isempty(capExt) )
    capFile=fullfile(capRoot,capDir,[capFn,'.txt']);
    if(exist(capFile,'file') ); break; end;
  else
    capFile=fullfile(capRoot,capDir,[capFn,'.txt']);
    if(exist(capFile,'file') ); capExt='txt'; break; end;
    capFile=fullfile(capRoot,capDir,[capFn,'.lay']);
    if(exist(capFile,'file') ); capExt='lay'; break; end;
  end
end
if ( ~exist(capFile,'file') ) 
  capFile=which([capFn '.txt']);
end
if ( ~exist(capFile,'file') ) 
  error('Couldnt find the capFile: %s',cap)
end

if ( strfind(cap,'xyz') ) % contains xyz coords
   [Cname x y z]=textread(capFile,'%s %f %f %f');
   xyz     = [x y z]';
   xy      = xyz2xy(xyz);
   latlong = xy2latlong(xy);
elseif ( strfind(cap,'xy') ) % contains xy coords
   [Cname x y]=textread(capFile,'%s %f %f');
   xy     = [x y]';
   latlong= xy2latlong(xy);
   xyz    = latlong2xyz(latlong);
elseif ( isequal(capExt,'.lay') ) % fieldtrip layout file
   [ans x y w h Cname]=textread(capFile,'%d %f %f %f %f %s');
   xy     = [x y]'; 
   xy     = repop(xy,'-',mean(xy,2)); 
   xy     = repop(xy,'./',sqrt(mean(xy.^2,2))); % map to unit circle and center
   latlong= xy2latlong(xy);
   xyz    = latlong2xyz(latlong);   
else % contains lat/long co-ords
   [Cname lat long]=textread(capFile,'%s %f %f');
   latlong = [lat long]';
   if( max(abs(latlong(:)))>2*pi ); latlong=latlong/180*pi; end;
   xyz     = latlong2xyz(latlong);
   xy      = latlong2xy(latlong);
end

return;

function xy=xyz2xy(xyz)
%if ( all(xyz(3,:)>=0) && all(xyz(3,:)<=2) && all(abs(xyz(1,:))<2) && all(abs(xyz(2,:))<2) ) % good co-ords
%  cz=0;
%else 
   cz= mean(xyz(3,:)); % center
%end
r = abs(max(abs(xyz(3,:)-cz))*1.1); if( r<eps ); r=1; end;  % radius
h = xyz(3,:)-cz;  % height
rr=sqrt(2*(r.^2-r*h)./(r.^2-h.^2)); % arc-length to radial length ratio
xy = [xyz(1,:).*rr; xyz(2,:).*rr];
return

function latlong=xy2latlong(xy);
% convert xy to lat-long, taking care to prevent division by 0
latlong= [sqrt(sum(xy.^2,1)); atan2(xy(2,:),xy(1,:))];
return

function xyz=latlong2xyz(latlong)
xyz= [sin(latlong(1,:)).*cos(latlong(2,:)); sin(latlong(1,:)).*sin(latlong(2,:)); cos(latlong(1,:))]; %3d
return

function xy=latlong2xy(latlong)
xy = [latlong(1,:).*cos(latlong(2,:));latlong(1,:).*sin(latlong(2,:))]; % 2d
return

%---------------------------------------------------------------------
function testCase;
[Cname ra xy xyz]=readCapInf('cap256');

subplot(211);plot(xy(:,1),xy(:,2),'.');text(xy(:,1),xy(:,2),Cname)
subplot(212);plot3(xyz(:,1),xyz(:,2),xyz(:,3),'.');text(xyz(:,1),xyz(:,2),xyz(:,3),Cname)

[Cname ra xy xyz]=readCapInf('electrocap124_xy');


% align 2 caps
[cap64.cnames cap64.ll cap64.xy cap64.xyz]=readCapInf('cap64');
[easycap.cnames easycap.ll easycap.xy easycap.xyz]=readCapInf('easycap_74_xyz');
[ans cap64.mi]=intersect(cap64.cnames,{'T7' 'T8' 'Oz'});
[ans easycap.mi]=intersect(easycap.cnames,{'T7' 'T8' 'Oz'});
[R,t]=rigidAlign(easycap.xyz(:,easycap.mi),cap64.xyz(:,cap64.mi));

[R,t]=rigidAlign(cap64.xyz(:,cap64.mi),easycap.xyz(:,easycap.mi));
cap64.xyz=repop(R*cap64.xyz,'+',t);
clf;scatPlot(easycap.xyz,'b.');hold on; scatPlot(cap64.xyz,'g.');
[fids.cname fids.ll fids.xy fids.xyz]=readCapInf('fids');
fids.xyz =repop(R*fids.xyz,'+',t);

