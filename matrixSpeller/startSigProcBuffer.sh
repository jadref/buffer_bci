#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
cat <<EOF | $matexe -nodesktop -nosplash #> sigProc.log 
capFile='cap_tmsi_mobita_black';
overridechnms=1;
startSigProcBuffer();
%quit;
EOF
