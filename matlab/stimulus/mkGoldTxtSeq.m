mdir=fileparts(mfilename('fullpath'));
% make the raw noise-tag stimuli sequences
[stimSeq,stimTime]=mkStimSeqNoise(8,255/60,1/60,'gold');

% for each frequency write text file with the stim-sequence
freqs=[60 40 20 10];
for fi=1:numel(freqs);
  str=sprintf('# gold @ %dhz\n',freqs(fi));
  str=sprintf('%s#stimTime: (%d,%d)\n',str,1,size(stimSeq,2));
  str=mat2txt(str,round((0:size(stimSeq,2)-1)*1000/freqs(fi)));
  str=sprintf('%s#stimSeq : (%d,%d)\n',str,size(stimSeq,1),size(stimSeq,2));
  str=mat2txt(str,stimSeq); % N.B. write in col-first order as this is what the java expects
  fid=fopen(fullfile(mdir,sprintf('gold_%2dhz.txt',freqs(fi))),'w');fprintf(fid,'%s',str);fclose(fid);
end
