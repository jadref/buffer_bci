#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
if [[ $matexe == *matlab ]]; then  args=-nodesktop; fi
cat <<EOF | $matexe $args
run ../utilities/initPaths.m;
buffhost='localhost';buffport=1972;
eventViewer;
quit;
EOF
