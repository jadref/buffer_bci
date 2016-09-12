function cybathlon_keyboard_control
cybathalon = struct('host','localhost','port',5555,'player',1,...
                    'cmdlabels',{{'jump' 'slide' 'speed' 'rest'}},'cmddict',[2 3 1 99],...
						  'cmdColors',[.6 0 .6;.6 .6 0;0 .5 0;.3 .3 .3]',...
                    'socket',[],'socketaddress',[]);
% open socket to the cybathalon game
[cybathalon.socket]=javaObject('java.net.DatagramSocket'); % create a UDP socket
cybathalon.socketaddress=javaObject('java.net.InetSocketAddress',cybathalon.host,cybathalon.port);
cybathalon.socket.connect(cybathalon.socketaddress); % connect to host/port
connectionWarned=0;

winColor     =[0 0 0]; % window background color


% make the stimulus display
fig=figure(2);
clf;
set(fig,'Name','Keyboard Input','color',winColor,'menubar','none','toolbar','none','doublebuffer','on');
set(fig,'keypressfcn',@keyListener);
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
    'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
    'color',winColor,'DrawMode','fast','nextplot','replacechildren',...
    'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');

set(gca,'visible','off');

%Create a text object with no text in it, center it, set font and color
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
    'fontunits','pixel','fontsize',.05*wSize(4),...
    'color',[0.75 0.75 0.75],'visible','off');

string = []; start = 0;
set(txthdl,'string', 'Click to start when ready', 'visible', 'on'); drawnow;
waitforbuttonpress;
start = 1;
set(txthdl,'visible', 'off'); drawnow;

% loop to wait for the window to be closed
while ( ishandle(fig) ) 
   pause(1);
end



    function []=keyListener(src,event)
        if ~start
            return
        end
        string = [string event.Character];
        set(txthdl,'string',string,'visible','on');
        
        command=[];
        if strcmp(string, 'jumpjumpjump')
            command =  strcmp(cybathalon.cmdlabels,'jump');
            string=[];
            set(txthdl,'string', 'jump', 'visible', 'on');
        elseif strcmp(string, 'restrestrest')
            command =  strcmp(cybathalon.cmdlabels,'rest');
            string=[];
            set(txthdl,'string', 'rest', 'visible', 'on');
        elseif strcmp(string, 'speedspeedspeed')
            command =  strcmp(cybathalon.cmdlabels,'speed');
            string=[];
            set(txthdl,'string', 'speed', 'visible', 'on');
        elseif strcmp(string, 'kickkickkick')
            command =  strcmp(cybathalon.cmdlabels,'kick');
            string=[];
            set(txthdl,'string', 'kick', 'visible', 'on');
        end
        drawnow;
        if ( ~isempty(command) ) 
try;
		cybathalon.socket.send(javaObject('java.net.DatagramPacket',uint8([10*cybathalon.player+cybathalon.cmddict(command) 0]),1));
	 catch;
		if ( connectionWarned<10 )
		  connectionWarned=connectionWarned+1;
		  warning('Error sending to the Cybathalon game.  Is it running?\n');
		end
end
        end
        fprintf('%s\n',string);
        
        if strcmp(event.Key,'space')
            string = [];
            set(txthdl,'visible', 'off'); drawnow;
        end
        
    end


end
