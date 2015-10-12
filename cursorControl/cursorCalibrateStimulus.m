configureCursor;

% get a good initial clock sync
buffer('sync_clock',[0:.5:10]);

% make the stimulus
%figure;
clf;
fig=gcf;
set(fig,...%'units','normalized','position',[0 0 1 1],...
    'Name','BCI Cursor control','toolbar','none','menubar','none','color',[0 0 0],...
    'renderer','painters');
ax=axes('position',[0.025 0.05 .825 .85],'units','normalized','visible','off','box','off',...
         'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
         'color',[0 0 0],'drawmode','fast',...
         'xlim',axLim,'ylim',axLim,'Ydir','reverse');%,'DataAspectRatio',[1 1 1]);

stimRadius=diff(axLim)/(nSymbs/2+1);
% symbols in a circle
for hi=1:nSymbs; 
  theta=(hi-1)/nSymbs*2*pi; x=cos(theta)*(axLim(2)-stimRadius/2); y=sin(theta)*(axLim(2)-stimRadius/2);
  h(hi)=rectangle('curvature',[1 1],'visible','off',...
						'position',[x-stimRadius/2,y-stimRadius/2,stimRadius,stimRadius],...
						'linewidth',3); 
end;
% fixation point
hi=nSymbs+1;
h(hi)=rectangle('curvature',[1 1],'visible','off',...
					 'position',[0-stimRadius/4 0-stimRadius/4 stimRadius/2 stimRadius/2]);

% instructions object
instructh=text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),instructstr,'HorizontalAlignment','center','VerticalAlignment','middle','color',[0 1 0],'fontunits','normalized','FontSize',.05,'visible','on','interpreter','none');

% give the user time to get to the right screen
drawnow;
pause(5);
set(instructh,'visible','off');
drawnow;

%% play the stimulus
sendEvent('stimulus.training','start');

%% Block 1 - SSEP - LF @ 2Phase
isi      = 1/30;
stimType = 'ssep_2phase';
ssepFreq = [10 11+2/3 13+1/3 15 10 11+2/3 13+1/3 15];
ssepPhase= 2*pi*[0 0 0 0 .5 .5 .5 .5];
cursorCalibrationStimulusBlock;

%% Block 2 - SSEP - HF @ 2phase
isi      = 1/60;
stimType = 'ssep_2phase';
ssepFreq = [20 23+1/3 26+2/3 30 20 23+1/3 16+2/3 30];
ssepPhase= 2*pi*[0 0 0 0 .5 .5 .5 .5];
cursorCalibrationStimulusBlock;

%% Block 3 -- SSEP - LF+HF @ 1 phase
isi      = 1/60;
stimType = 'ssep';
ssepFreq = [8+2/3 10 11+2/3 13+1/3 15 16+2/3 18+1/3 20];
ssepPhase= 2*pi*[0 0 0 0 0 0 0 0];
cursorCalibrationStimulusBlock;

%% Block 4 -- P300 Radial @ 10hz
stimType = 'p3-radial';
isi      = 1/10;
cursorCalibrationStimulusBlock;

%% Block 5 -- P300 Radial @ 20hz
stimType = 'p3-radial';
isi      = 1/20;
cursorCalibrationStimulusBlock;

%% Block 6 -- P300-90 @ 10hz
stimType = 'p3-90';
isi      = 1/10;
cursorCalibrationStimulusBlock;

%% Block 7 -- P300-90 @ 20hz
stimType = 'p3-90';
isi      = 1/20;
cursorCalibrationStimulusBlock;

%% Block 8 -- P300 @ 10hz
stimType = 'p3';
isi      = 1/10;
cursorCalibrationStimulusBlock;

%% Block 9 -- P300 @ 20hz
stimType = 'p3';
isi      = 1/20;
cursorCalibrationStimulusBlock;

%% Block 10 -- noise @ 10hz
stimType = 'noise';
isi      = 1/10;
cursorCalibrationStimulusBlock;

%% Block 11 -- noise @ 20hz
stimType = 'noise';
isi      = 1/20;
cursorCalibrationStimulusBlock;

%% Block 12 -- noise @ 30hz
stimType = 'noise';
isi      = 1/30;
cursorCalibrationStimulusBlock;

%% Block 13 -- noise-psk @ 10hz
stimType = 'noise-psk';
isi      = 1/10;
cursorCalibrationStimulusBlock;

%% Block 14 -- noise-psk @ 20hz
stimType = 'noise-psk';
isi      = 1/20;
cursorCalibrationStimulusBlock;

%% end training marker
sendEvent('stimulus.training','end');
% show the end training message
if ( ishandle(fig) ) 
  pause(1);
  set(instructh,'string',{'That ends the training phase.','Thanks for your patience'});
  pause(3);
end
