function [dat,hdr] = read_buffer_offline_data(datafile, hdr, range)
% function [dat,hdr] = read_buffer_offline_data(datafile, header, range)
%
% This function reads FCDC buffer-type data from a binary file.

% (C) 2010 S. Klanke
if ( nargin<2 || isempty(hdr))
   hdr=read_buffer_offline_header(fullfile(fileparts(datafile),'header'));
end
if ( nargin<3 || isempty(range)) 
  range=[1 hdr.nSamples];
end
type2type = [hdr.orig.data_type '=>' hdr.orig.data_type];
nStart = int32(range(1)-1); % 0-based offset in samples
bStart = int32(nStart * hdr.orig.wordsize * hdr.nChans);
nRead = int32(range(2)+1-range(1));
bRead = int32(nRead * hdr.orig.wordsize * hdr.nChans);

endianness='native';  
if ( ~isempty(hdr) && isfield(hdr,'orig') && isfield(hdr.orig,'endianness') )
  endianess=hdr.orig.endianness;
end

bReadRemain = 0;
k = 0;
sizeSoFar = 0;
dat=[];
% start with name_k = datafile (= '.../samples' )
name_k = datafile;
while true
  F = fopen(name_k,'rb',endianness);
  if ( F<0 ) % couldn't read file
    warning('Couldnt open data file: %s',name_k);
    break;
  end
  status = fseek(F, 0, 'eof');
  if status < 0 ; error('Cant read the file: %s',name_k); end;
  size_k = ftell(F);
   
  if bStart >= sizeSoFar && bStart < sizeSoFar + size_k
    status = fseek(F, bStart - sizeSoFar, 'bof');
    if status < 0 ; error('Cant read the file: %s',name_k); end;
    if bStart + bRead <= sizeSoFar + size_k
      % desired region is completely contained in this file
	  dat = fread(F,[hdr.nChans nRead], type2type);
	  bReadRemain = 0;
	else
	  % desired region starts in this file, but then goes on
	  bRead_k = sizeSoFar + size_k - bStart;
	  nRead_k = bRead_k / (hdr.orig.wordsize * hdr.nChans);
	  
	  dat = fread(F,[hdr.nChans nRead_k], type2type);
	  bReadRemain = nRead - nRead_k;
	end
  else
    fseek(F, 0, 'bof');
	if bReadRemain <= size_k
	  % this is the last file we need
	  bRead_k = bReadRemain;
	  bReadRemain = 0;
	else 
	  bRead_k = size_k;
	  bReadRemain = bReadRemain - size_k;
	end
	nRead_k = bRead_k / (hdr.orig.wordsize * hdr.nChans);
	dat = [dat fread(F,[hdr.nChans nRead_k], type2type)];
  end	  
  fclose(F);		 
  if bReadRemain == 0
     break;
  end
  % update name_k for next iteration
  k=k+1;
  name_k = sprintf('%s%i', datafile, k);
end
