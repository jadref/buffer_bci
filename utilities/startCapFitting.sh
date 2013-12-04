#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
cat <<EOF | $matexe -nodesktop -nosplash
run ../utilities/initPaths; 
capFitting('capFile','cap_tmsi_mobita_black','overridechnms',1);
quit;
EOF
