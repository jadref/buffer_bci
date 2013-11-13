% very big put-dat
run ../utilities/initPaths
host='localhost'; port=1972;
nCh=1000;
blockSize=10000;
Cnames={'Cz' 'CPz' 'Oz'};
for i=numel(Cnames)+1:nCh; Cnames{i}=sprintf('rand%02d',i); end;
hdr=struct('fsample',1000,'channel_names',{Cnames(1:nCh)},'nchans',100,'nsamples',0,'nsamplespre',0,'ntrials',1,'nevents',0,'data_type',10);
buffer('put_hdr',hdr,host,port);
dat=struct('nchans',hdr.nchans,'nsamples',blockSize,'data_type',hdr.data_type,'buf',[]);
t=clock;while(mod(floor(t(6)),10)~=0); t=clock; pause(.001); end; % sync start time
for i=1:100;
  dat.buf = randn(hdr.nchans,blockSize);  
  buffer('put_dat',dat,host,port);
  pause(.1);
  fprintf('.');
end
fprintf('\n');
return;

% very long wait-data
t=clock;while(mod(floor(t(6)),10)~=0); t=clock; pause(.001);  end; % sync start time
for i=1:100;
  [nsamp,nevt]=buffer('wait_dat',[-1 -1 5000]);
  fprintf('%d %d\n',nsamp,nevt);
  pause(.1)
end

