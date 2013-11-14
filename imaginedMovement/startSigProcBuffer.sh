#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
cat <<EOF | $matexe -nodesktop -nosplash #> sigProc.log 
startSigProcBuffer;
%quit;
EOF
