function [coords]=loadPatchCoords(fname)
fid=fopen(fname);
if ( fid<0 ) error('cant open file'); return; end;
coords=fscanf(fid,'%g');
coords=reshape(coords,2,[]);
fclose(fid);