mdir=fileparts(mfilename('fullpath'));
addpath(fullfile(mdir,'..','utilities'));
% make the raw noise-tag stimuli sequences
if( 0 )
  type='gold';
  [stimSeq,stimTime]=mkStimSeqNoise(65,255/60,1/60,'gold'); % [ nSymb x nSamp ]
else
  type='mgold_65_6532';
  v=load('mgold_65_6532.mat');
  stimSeq = v.codes'; % [ nSymb x nSamp ] 
end

% for each frequency write text file with the stim-sequence
freqs=[60 40 30 20 10];
for fi=1:numel(freqs);
  str=sprintf('# gold @ %dhz\n',freqs(fi));
  str=sprintf('%s#stimTime: (%d,%d)\n',str,1,size(stimSeq,2));
  str=mat2txt(str,round((0:size(stimSeq,2)-1)*1000/freqs(fi)));
  str=sprintf('%s#stimSeq : (%d,%d)\n',str,size(stimSeq,1),size(stimSeq,2));
  str=mat2txt(str,stimSeq); % N.B. write in col-first order as this is what the java expects
  fname = fullfile(mdir,sprintf('%s_%2dhz.txt',type,freqs(fi)));
  fprintf('Writing to : %s\n',fname);
  fid=fopen(fname,'w');fprintf(fid,'%s',str);fclose(fid);
end
