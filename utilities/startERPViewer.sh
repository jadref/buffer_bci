#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
cat <<EOF | $matexe -nodesktop  
run ../utilities/initPaths;
[X,Y,key]=erpViewer([],[],'cuePrefix',{'keyboard' 'stimulus'});
save('erpViewerDat','X','Y','key');
quit;
EOF
