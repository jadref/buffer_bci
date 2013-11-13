#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
cat <<EOF | matlab -nodesktop 
runEvokedDemo;
quit;
EOF
