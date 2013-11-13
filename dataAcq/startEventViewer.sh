#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
cat <<EOF | matlab -nodesktop -nodisplay
if ( exist('initPaths') ) initPaths; else run ../utilities/initPaths; end;
buffhost='localhost';buffport=1972;
eventViewer;
quit;
EOF
