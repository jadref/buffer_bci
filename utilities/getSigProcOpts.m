function [sigprocopts,damage]=getSigProcOpts(optsFighandles,oldopts)
% get the current options from the sig-proc-opts figure
sigprocopts.badchrm=get(optsFighandles.badchrm,'value');
sigprocopts.badchthresh=str2num(get(optsFighandles.badchthresh,'string'));
sigprocopts.spatfilttype=get(get(optsFighandles.spatfilt,'SelectedObject'),'String');
sigprocopts.preproctype=get(get(optsFighandles.preproc,'SelectedObject'),'String');
sigprocopts.freqbands=[str2num(get(optsFighandles.lowcutoff,'string')) ...
                    str2num(get(optsFighandles.highcutoff,'string'))];  
if ( numel(sigprocopts.freqbands)>4 ) sigprocopts.freqbands=sigprocopts.freqbands(1:min(end,4));
elseif ( numel(sigprocopts.freqbands)<2 ) sigprocopts.freqbands=[];
end;
damage=false(5,1);
if( nargout>1 && nargin>1) 
  if ( isstruct(oldopts) )
    damage(1)= ~isequal(oldopts.badchrm,sigprocopts.badchrm);
    damage(2)= ~isequal(oldopts.spatfilttype,sigprocopts.spatfilttype);
    damage(3)= ~isequal(oldopts.preproctype,sigprocopts.preproctype);
    damage(4)= ~isequal(oldopts.freqbands,sigprocopts.freqbands);
    damage(5)= ~isequal(oldopts.badchthresh,sigprocopts.badchthresh);
  end
end
