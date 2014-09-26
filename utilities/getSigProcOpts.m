function sigprocopts=getSigProcOpts(optsFighandles)
% get the current options from the sig-proc-opts figure
sigprocopts.badchrm=get(optsFighandles.badchrm,'value');
sigprocopts.spatfilttype=get(get(optsFighandles.spatfilt,'SelectedObject'),'String');
sigprocopts.preproctype=get(get(optsFighandles.preproc,'SelectedObject'),'String');
sigprocopts.freqbands=[str2num(get(optsFighandles.lowcutoff,'string')) ...
                    str2num(get(optsFighandles.highcutoff,'string'))];  
if ( numel(sigprocopts.freqbands)>4 ) sigprocopts.freqbands=sigprocopts.freqbands(1:min(end,4));
elseif ( numel(sigprocopts.freqbands)<2 ) sigprocopts.freqbands=[];
end;