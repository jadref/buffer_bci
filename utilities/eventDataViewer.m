function [dat,key,state]=eventDataViewer(host,port,varargin);
opts=struct('endTraining','end','verb',0,'plotCh',[],'keyFn',@isequal,'drawInterval',0);
[opts,varargin]=parseOpts(opts,varargin);
if ( nargin<1 || isempty(host) ) host='localhost'; end;
if ( nargin<2 || isempty(port) ) port=1972; end;

% get channel info for plotting
hdr = buffer('get_hdr',[],host,port);
di = addPosInfo(hdr.channel_names,'1010'); % get 3d-coords
ch_pos=cat(2,di.extra.pos2d); ch_names=di.vals; % extract pos and channels names
iseeg=[di.extra.iseeg];
if( ~any(iseeg) ) iseeg(:)=true; end
plotCh=opts.plotCh; if ( ~isempty(plotCh) && isstr(plotCh) ) plotCh={plotCh}; end;
if( ~isempty(plotCh) && iscell(plotCh) )
  tmp=plotCh; plotCh=[];
  for i=1:numel(tmp); tt=strmatch(tmp{i},ch_names); plotCh(i)=tt(1); end;
end
if( isempty(plotCh) ) plotCh=iseeg; end


endTraining=false; state=[]; key={}; dat={}; hdls={}; newData=0;
while ( ~endTraining )

  [datai,deventsi,state]=buffer_waitData(host,port,state,'startSet',{{'stimulus'}},'trlen_ms',1000,'exitSet','data','verb',opts.verb,varargin{:}); % return as soon as have some data to process
  
  for ei=1:numel(deventsi);
    event=deventsi(ei);
    if( strmatch(opts.endTraining,event.value) ) % end-training event
      endTraining=true; % mark to finish
      fprintf('Discarding all subsequent events: exit\n');
    else
      v = event.value;      
      mi=[]; 
      if ( ~isempty(key) ) % group with similar events
        for ki=1:numel(key) 
          if ( feval(opts.keyFn,v,key{ki}) ) 
            mi=ki; break; 
          end; 
        end; 
      end
      newData=newData+1;
      if ( isempty(mi) ) % new class to average
        key{end+1}=v;
        dat{end+1}=datai(ei).buf;
      else
        dat{mi}(:,:,end+1)=datai(ei).buf;
      end
    end
  end
  % plot the updated data
  if ( newData>opts.drawInterval || (endTraining && newData>0) )
    newfig=false;
    for ci=1:numel(key);
      if(numel(hdls)<ci) figure(ci); clf; hdls{ci}=[]; newfig=true; end
      hdls{ci}=image3d(dat{ci}(plotCh,:,:),1,'plotPos',ch_pos(:,plotCh),'Xvals',hdr.channel_names(plotCh),'handles',hdls{ci});
    end
    if ( newfig || isempty(deventsi) ) drawnow; else drawnow expose; end
    newData=0;
  end
end
return;
%-----------------------
function testCase();
%Add necessary paths
addpath(exGenPath(fullfile(pwd,'ft_buffer','buffer','matlab')));
getwTime=@(x) now()*86400; % HACK: in seconds

[dat,key,state]=eventDataViewer([],[],'trlen_ms',600,'plotCh','T8')
% all arrows stim events on same plot
[dat,key,state]=eventDataViewer([],[],'trlen_ms',400,'plotCh','T8','startSet',{{'stimulus.arrows'} []},'keyFn',@(x,y) true);