function [sigprocopts,damage]=getSigProcOpts(optsFighandles,oldopts)
% get the current options from the sig-proc-opts figure
%sigprocopts.badchrm=get(optsFighandles.badchrm,'value');
%sigprocopts.badchthresh=str2num(get(optsFighandles.badchthresh,'string'));
%if( isfield(optsFighandles,'whiten') ) sigprocopts.whiten=get(optsFighandles.whiten,'value'); end
%if( isfield(optsFighandles,'rmartch') ) sigprocopts.rmartch=get(optsFighandles.rmartch,'value'); end
%if( isfield(optsFighandles,'rmemg') ) sigprocopts.rmemg=get(optsFighandles.rmemg,'value'); end

%sigprocopts.spatfilttype=get(get(optsFighandles.spatfilt,'SelectedObject'),'String');
%sigprocopts.preproctype=get(get(optsFighandles.preproc,'SelectedObject'),'String');

% get all the controls
cld=findobj(optsFighandles,'type','uicontrol');
                                % convert values into struct fields
for ci=1:numel(cld);
  switch get(cld(ci),'style');
    case {'checkbox','radiobutton'};
      sigprocopts.(get(cld(ci),'tag'))=get(cld(ci),'value');
    case 'edit';
      sigprocopts.(get(cld(ci),'tag'))=get(cld(ci),'string');
    case 'text'; % do nothing
  end
end

sigprocopts.badchthresh=str2num(sigprocopts.badchthresh);

sigprocopts.freqbands=[str2num(sigprocopts.lowcutoff) str2num(sigprocopts.highcutoff)];  
% sigprocopts.freqbands=[str2num(get(optsFighandles.lowcutoff,'string')) ...
%                               str2num(get(optsFighandles.highcutoff,'string'))];  
if ( numel(sigprocopts.freqbands)>4 ) sigprocopts.freqbands=sigprocopts.freqbands(1:min(end,4));
elseif ( numel(sigprocopts.freqbands)<2 ) sigprocopts.freqbands=[];
end;
damage=false(5,1);
if( nargout>1 && nargin>1) 
  if ( isstruct(oldopts) )
    damage(1)= ~isequal(oldopts.badchrm,sigprocopts.badchrm);
    %damage(2)= ~isequal(oldopts.spatfilttype,sigprocopts.spatfilttype);
    %damage(3)= ~isequal(oldopts.preproctype,sigprocopts.preproctype);
    damage(4)= ~isequal(oldopts.freqbands,sigprocopts.freqbands);
    damage(5)= ~isequal(oldopts.badchthresh,sigprocopts.badchthresh);
  end
end
