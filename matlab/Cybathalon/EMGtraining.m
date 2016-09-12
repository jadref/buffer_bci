% Made by Ceci Verbaarschot
%
% Collect EMG training data on rest, right hand movement, left hand movement
% and movement with both hands together for the cybathlon game. This data
% will be used to choose a good EMG threshold for movement detection. 

function [data,devents,hdr]=EMGtraining()

    % Add all necessary paths
    run ../utilities/initPaths.m
    
    % Set-up a connection with the buffer
    buffhost='localhost';buffport=1972;
    % wait for the buffer to return valid header information
    hdr=[];
    while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
        try 
            hdr=buffer('get_hdr',[],buffhost,buffport); 
        catch
            hdr=[];
            fprintf('Invalid header info... waiting.\n');
        end;
        pause(1);
    end;

    sz = [600 800]; % figure size
    txtColor=[.8 .8 .8];

    screensize = get(0,'ScreenSize');
    xpos = ceil((screensize(3)-sz(2))/2); % center the figure on the
                                          %Screen horizontally
    ypos = ceil((screensize(4)-sz(1))/2); % center the figure on the
                                          %Screen vertically
    fig=figure(2);
    set(fig,'units','pixels','MenuBar','none','color',[0 0 0]);

    welcome = sprintf(['Welkom \n\nTijdens dit oefenblok word je gevraagd om een beweging \nte maken met jouw' ...
                            ' rechter hand, linker hand, beiden handen \nof om te ontspannen. \n\nDruk op een toets om te beginnen...']);
                    
    text(0,6,welcome,'Color',txtColor,'FontSize',20);
    axis([0 10 0 10]);
    set(gca,'visible','off');
    waitforbuttonpress();
    clf;
    
    order = {'Rechter hand', 'Linker hand','Beide handen',...
             'Linker hand', 'Rechter hand', 'Linker hand',...
             'Beide handen', 'Beide handen', 'Rechter hand'};
    position = [8 0 4 ...
                0 8 0 ...
                4 4 8];
    right = imread(fullfile('images','Right.png'));
    left = imread(fullfile('images','Left.png'));
    both = imread(fullfile('images','Both.png'));
    relax = imread(fullfile('images','Relax.jpg'));
    relax = imresize(relax,0.5);
    
    fig=figure(2);clf;
    state=buffer('poll'); data=[]; devents=[];
    %    [traindata,traindevents,state]=buffer_waitData(buffhost,buffport,[],'startSet',{'move'},'exitSet',{0 'data'},0,'trlen_ms',3000);
    for t=1:3;%length(order)
       if ( ~ishandle(fig) ) break; end;
        instruction = sprintf([order{t}]);
        if strcmp(order{t},'Rechter hand')
            subimage(right);
        elseif strcmp(order{t},'Linker hand')
            subimage(left);
        else
            subimage(both);
        end
        sendEvent('move',order{t},-1);
        set(gca,'visible','off');
        drawnow;
        
        [traindata,traindevents,state]=buffer_waitData(buffhost,buffport,state,'startSet',{'move'},'exitSet',{'data'},'trlen_ms',3000);
        if ( isempty(data) ) 
           data=traindata; 
           devents=traindevents;
        else
           data=cat(1,data,traindata);
           devents=cat(1,devents,traindevents);
        end;
        clf;
        
        subimage(relax);
        sendEvent('move','relax',-1);
        set(gca,'visible','off');
        drawnow;
        [traindata,traindevents,state]=buffer_waitData(buffhost,buffport,state,'startSet',{'move'},'exitSet',{'data'},'trlen_ms',3000);
        if ( isempty(data) ) 
           data=traindata; 
           devents=traindevents;
        else
           data=cat(1,data,traindata);
           devents=cat(1,devents,traindevents);
        end;
        clf;
    end
end