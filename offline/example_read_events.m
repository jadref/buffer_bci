datadir='example_data/raw_buffer/0001';
% first you need to read the header information
hdr=read_buffer_offline_header(fullfile(datadir,'header'));
% then you can read all the events
events=read_buffer_offline_events(fullfile(datadir,'events'),hdr);
