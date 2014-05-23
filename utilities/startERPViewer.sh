#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
if [[ $matexe == *matlab ]]; then  args=-nodesktop; fi
cat <<EOF | $matexe $args
run ../utilities/initPaths;
[X,Y,key]=erpViewer([],[],'cuePrefix',{'keyboard' 'stimulus'});
save('erpViewerDat','X','Y','key');
quit;
EOF
