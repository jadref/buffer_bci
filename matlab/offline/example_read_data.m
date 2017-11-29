datadir='example_data/raw_buffer/0001';
% first you need to read the header information
hdr=read_buffer_offline_header(fullfile(datadir,'header'));
% then you can read all the events
data=read_buffer_offline_data(fullfile(datadir,'samples'),hdr);
% data now contains all the data from the file in [channels x samples] matrix
