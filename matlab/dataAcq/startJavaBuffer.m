% add the buffer server .jar to the java class path
dataAcq_dir=fileparts(mfilename('fullpath')); % parent directory
if ( exist(fullfile(dataAcq_dir,'buffer','java'),'dir') ) % use java buffer if it's there
  bufferjavaclassdir=fullfile(dataAcq_dir,'buffer','java');
  bufferjar = fullfile(bufferjavaclassdir,'BufferServer.jar');
  if ( exist(bufferjar,'file') ) 
      javaaddpath(bufferjar); % N.B. this will clear all variables!
  end
end
										  % start the buffer server in the java thread
port=1972;
subject='test';
datv = datevec(now);
session=sprintf('%02d%02d%02d',datv(1)-2000,datv(2:3));
block  =sprintf('%02d%02d',datv(4:5));
if ispc
   rootdir = fullfile(getenv('HOMEDRIVE'),getenv('HOMEPATH'));
else
   rootdir = fullfile(getenv('HOME'));
end
savepath=fullfile(rootdir,'output',subject,session,block);
if ( ~exist(savepath,'dir') ) 
   diri=find(savepath==filesep | savepath=='/');
   if(diri(1)==1);diri=diri(2:end);end;
   if(diri(end)~=numel(savepath))diri=[diri numel(savepath)+1];end;
   for di=1:numel(diri);
      if ( ~exist(savepath(1:diri(di)-1),'dir') ) mkdir(savepath(1:diri(di)-1)); end;
   end
end;

% create the object, saving to the given location
svr=javaObject('nl.fcdonders.fieldtrip.bufferserver.BufferServer',savepath,port);
% run the server
svr.start();
