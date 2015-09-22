run ../../utilities/initPaths.m
javaaddpath(pwd)
lowf =1024;
sll=javaObject('nl.dcc.buffer_bci.SoundLine',lowf,lowf*10,1);

highf=1024*10;
slh=javaObject('nl.dcc.buffer_bci.SoundLine',highf,highf*10,1);

x=sin((1:(lowf*10))*2*pi*50/lowf);
x2=pvoc(x,lowf/highf,lowf);

clf;subplot(211);imagesc('cdata',shiftdim(spectrogram(x,[],'fs',lowf)));subplot(212);imagesc('cdata',shiftdim(spectrogram(x2,[],'fs',highf)))

sll.start(); sll.write(abs((x+1))*128), sll.drain(); sll.stop()

slh.start(); slh.write(abs((x2+1))*128), slh.drain(); slh.stop()
