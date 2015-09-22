## %---------------------------------------------------------------------
## function testCase()
hdr=buffer('get_hdr');
sec=buffer('poll');
evts=buffer('get_evt',[sec.nEvents-100 sec.nEvents-1]);
mi=matchEvents(evts,{'stimulus.snd.bgn' 'stimulus.snd.fin'});
evts=evts(mi);
clear dat
for ei=1:numel(evts);
	 try
		dat(ei)=buffer('get_dat',[evts(ei).sample-hdr.fSample*.1 evts(ei).sample+hdr.fSample*.5]);
	 catch
		fprintf('%d) Bugger data not available',ei);
	 end
end
dat=cat(3,dat.buf);
clf;
subplot(211);imagesc('xdata',linspace(-hdr.fSample*.1,hdr.fSample*.5,size(dat,2)),'cdata',shiftdim(dat(1,:,matchEvents(evts,'stimulus.snd.bgn')))');
subplot(212);imagesc('xdata',linspace(-hdr.fSample*.1,hdr.fSample*.5,size(dat,2)),'cdata',shiftdim(dat(1,:,matchEvents(evts,'stimulus.snd.fin')))');
