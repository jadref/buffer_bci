run ../utilities/initPaths;
nevents=[];
while ( true )
  [events,nevents]=buffer_newevents([],[],nevents,buffhost,buffport);
  if ( ~isempty(events) ) 
    fprintf('%s\n',ev2str(events));
  end
  fprintf(1,'.');
  pause(1);
end