frm=javaObject('java.awt.Frame');%swing.JFrame');
javaMethod('setSize',frm,100,100);
javaMethod('setTitle',frm,'Hello there');
javaMethod('setVisible',frm,true)
%cp=javaMethod('getContentPane',frm);
%javaMethod('setDoubleBuffered',cp,true);
%aa=javaMethod('add',cp,); % add a component, like a button
g=javaMethod('getGraphics',frm)

tic,
for i=1:60*5;
  javaMethod('setColor',g,javaObject('java.awt.Color',0,0,0));% set(g,'color',[0 0 0]); % matlab wrapper
  javaMethod('fillRect',g,0,0,100,100);
  %javaMethod('update',frm,g);
  javaMethod('sleep','java.lang.Thread',1/30*1000);
  javaMethod('setColor',g,javaObject('java.awt.Color',1,1,1));
  javaMethod('fillRect',g,0,0,100,100);
  %javaMethod('update',frm,g);
  javaMethod('sleep','java.lang.Thread',1/30*1000);
end
toc
