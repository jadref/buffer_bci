configureIM;

PAD_COUNT = 16; % number of pads excluding starting pad

socket = udp(’localhost’, 6666, ’LocalPort’, 6666, ’InputBufferSize’, 8192, ’TimeOut’, 3600);
fopen(socket);

% wait for and consume the three starting zeroes count = 0;
count = 0;
while count < 3
   try
      data = fread(socket,1);
      if  ̃isempty(data)
         count = count + 1;
      end
   catch 
   end
end

sendEvent(’stimulus.training’,’start’);
count = 0; % amount of pads visited
while count <= PAD_COUNT+1
   cur_val=-1;
   try
      cur_val = fread(socket,1); % blocking read-wait for the game to send us something
   catch
   end
   if  ̃isempty(cur_val) %game sent us something
      if cur_val > 01 %this is a pad entry message
         count = count + 1;
         sendEvent(’stimulus.target’,sprintf(’%d’,cur_val));
      end
   end
end
fclose(socket);
sendEvent('stimulus.training','end');