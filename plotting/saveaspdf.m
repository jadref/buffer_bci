function saveaspdf(fig, fname)
% save the selected figure as a same sized and boxed pdf file
%
% saveaspdf(fig, fname)
% OR
% saveaspdf(fname)
%
% Inputs:
%  fig   -- figure handle to save
%  fname -- file name to save the figure as. .pdf is appended if not given
%
if nargin < 1, fig = []; end
if nargin < 2
   if ( isnumeric(fig) ) fname='untitled'; else fname=fig; fig=[]; end
end
if isempty(fig), fig=gcf; end

% append the pdf if not given.
%if ( fname(max(end-3,1):end)~='.pdf' ) fname=[fname '.pdf']; end;

% get the stuff we need.
if ( fname(1)=='~' )
  if ( exist('glob','file') ) fname=glob(fname); if ( iscell(fname) ) fname=fname{:}; end;
  elseif ( ~ispc() )   fname=[getenv('HOME') fname(2:end)]; 
  end;
end

% store current state
fp.renderer         = get(fig,'renderer');
fp.Units            = get(fig,'Units');
fp.PaperOrientation = get(fig,'PaperOrientation');
fp.PaperPositionMode= get(fig,'PaperPositionMode');
fp.PaperType        = get(fig,'PaperType');
fp.paperUnits       = get(fig,'PaperUnits');
fp.PaperSize        = get(fig,'PaperSize');
fp.PaperPosition    = get(fig,'PaperPosition');

% Change so print works nicely
set(fig,'Units','inches'); pos=get(fig,'position'); % get size in inches
%tp=get(fig,'TightPosition'); pos
set(fig,'PaperPositionMode','manual',...  % set print size to screen size
        'PaperOrientation','portrait',...
        'PaperType','<custom>',...
        'PaperUnits','inches',...
        'PaperSize', pos(3:4),...
        'PaperPosition',[0 0 pos(3:4)]);
set(fig, 'renderer', 'painters');

% Do the print with matlab
if ( ispc() ) tfname='saveaspdf'; else tfname='/tmp/saveaspdf'; end;
if ( exist([tfname '.pdf'],'file') ) delete([tfname '.pdf']); end;
print(fig,'-dpdf','-r300',tfname);
if ( ispc() ) % hack round file-name limitation of ghostscript
  system(['move "' tfname '.pdf' '" "' fname '.pdf"']);
else
  system(['mv "' tfname '.pdf"' ' "' fname '.pdf"']);
end

% Restore the previous state
set(fig,fp);