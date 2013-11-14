#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
cat <<EOF | $matexe -nodesktop  
if ( exist('initPaths') ) initPaths; else run ../utilities/initPaths; end;
buffhost='localhost';buffport=1972;
eventViewer;
quit;
EOF
