#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
cat <<EOF | $matexe -nodesktop  
run ../utilities/initPaths;
erpViewer([],[],'cuePrefix',{'keyboard' 'stimulus'});
quit;
EOF
