#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
if [[ $matexe == *matlab ]]; then  args=-nodesktop; fi
cat <<EOF | $matexe $args
run ../utilities/initPaths.m;
erpViewer([],[],'trlen_ms',1000,'cuePrefix','stimulus.target','endType',{'startPhase.cmd' 'exit'});
quit;
EOF
