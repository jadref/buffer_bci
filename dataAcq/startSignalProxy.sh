#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
cat <<EOF | $matexe -nodesktop  -nosplash
run ../utilities/initPaths; 
buffer_signalproxy('localhost',1972,'stimEventRate',0,'queueEventRate',0);
quit;
EOF
