#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
cat <<EOF | $matexe -nodesktop -nosplash
run ../utilities/initPaths;
buffhost='localhost';buffport=1972;
eventViewer;
quit;
EOF
