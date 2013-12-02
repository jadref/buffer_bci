function [ev,state]=drawStim(ftime,state,dxy,restart)
if ( nargin<4 || isempty(restart) ) restart=false; end;
ev=[];
if ( any(dxy~=0) ) % move to track hero!
  ncursorPos=state.cursorPos+dxy;
  % ax bounding box check for cursor
  xlim=get(state.ax,'xlim'); 
  if ( ncursorPos(1)>xlim(2) )    dxy(1)=xlim(2)-state.cursorPos(1); 
  elseif( ncursorPos(1)<xlim(1) ) dxy(1)=xlim(1)-state.cursorPos(1);
  end
  ylim=get(state.ax,'ylim');
  if ( ncursorPos(2)>ylim(2) )    dxy(2)=ylim(2)-state.cursorPos(2); 
  elseif( ncursorPos(2)<ylim(1) ) dxy(2)=ylim(1)-state.cursorPos(2);
  end
  for hi=1:numel(state.hdls);
    state.stimPos(:,hi)=state.stimPos(:,hi)+dxy;
    xdat=get(state.hdls(hi),'xdata'); ydat=get(state.hdls(hi),'ydata');
    set(state.hdls(hi),'xdata',xdat+dxy(1),'ydata',ydat+dxy(2));
  end
  state.cursorPos=state.cursorPos+dxy;
end

if ( restart || isempty(state.startTime) )
  state.startTime=ftime; 
  state.curStim =1;
end


% play stimulus
if ( (ftime-state.startTime) >= state.stimTime(state.curStim)  || restart ) % new stim
  ostimState=state.curstimState;
  curstimState = state.stimSeq(:,state.curStim);
  if ( isfield(state,'visibleStim') ) % make some stim invisible
    set(state.hdls(ostimState<0),'visible','on'); % make invisible visible
    curstimState(~state.visibleStim)=-1; 
    set(state.hdls(~state.visibleStim),'visible','off'); % make visible invisible
  end; 
  if ( state.sizeStim>0 )  % zoom highlighted symbol
    si=find(ostimState>0);
    if ( ~isempty(si) )
      for j=si; % change stim size
        set(state.hdls(j),'xdat',state.stimPos(1,j)+state.stimPCoords(1,:,j),...
                          'ydat',state.stimPos(2,j)+state.stimPCoords(2,:,j));
      end
    end
    si=find(curstimState>0);
    if ( ~isempty(si) )
      for j=si; % change stim size
        set(state.hdls(j),'xdat',state.stimPos(1,j)+state.stimPCoords(1,:,j)*state.sizeStim,...
                          'ydat',state.stimPos(2,j)+state.stimPCoords(2,:,j)*state.sizeStim);
      end
    end
  end
  % change highlighted symbol color
  set(state.hdls(curstimState>0),'facecolor',state.tgtColor);
  set(state.hdls(curstimState==0),'facecolor',state.bgColor);
  set(state.hdls(curstimState>1),'facecolor',state.tgt2Color);
  % event if something changed & something stimulated
  if ( any(state.curstimState~=curstimState) && any(curstimState>0) ) 
    ev=mkEvent('stimulus.arrows',curstimState,-1);
  end
  state.curstimState=curstimState;
  state.curStim=state.curStim+1; 
  if( state.curStim>size(state.stimSeq,2) ) 
      state.curStim=1; 
      state.startTime=ftime; % reset start time!
  end
end