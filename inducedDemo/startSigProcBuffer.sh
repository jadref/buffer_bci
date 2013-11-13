#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
cat <<EOF | \matlab -nodesktop -nosplash #> sigProc.log 
startSigProcBuffer();
%quit;
EOF
