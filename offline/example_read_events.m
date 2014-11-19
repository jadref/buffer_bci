% first you need to read the header information
hdr=read_buffer_offline_header(fullfile('~/output/test/140117/2145_20681/raw_buffer/0001','header'));
% then you can read all the events
events=read_buffer_offline_events(fullfile('~/output/test/140117/2145_20681/raw_buffer/0001','events'),hdr);
