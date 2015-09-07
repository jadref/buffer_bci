% make the raw noise-tag stimuli sequences
[stimSeq,stimTime]=mkStimSeqNoise(8,255/60,1/60,'gold');

% for each frequency write text file with the stim-sequence
freqs=[60 40 20 10];
for fi=1:numel(freqs);
  str=sprintf('# gold @ %dhz\n',freqs(fi));
  str=mat2java(str,round((0:size(stimSeq,2)-1)*1000/freqs(fi)));
  str=mat2java(str,stimSeq'); % N.B. write in col-first order as this is what the java expects
  fid=fopen(sprintf('stimSeq/gold_%2dhz.txt',freqs(fi)),'w');fprintf(fid,'%s',str);fclose(fid);	 
end
