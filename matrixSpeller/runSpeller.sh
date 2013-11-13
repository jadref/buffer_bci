#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
cat <<EOF | matlab -nodesktop 
runSpeller;
quit;
EOF
