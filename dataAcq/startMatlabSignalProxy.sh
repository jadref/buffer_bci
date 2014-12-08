#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
if [[ $matexe == *matlab ]]; then  args=-nodesktop; fi
cat <<EOF | $matexe $args
run ../utilities/initPaths.m; 
buffer_signalproxy('localhost',1972,'stimEventRate',0,'queueEventRate',0);
quit;
EOF
