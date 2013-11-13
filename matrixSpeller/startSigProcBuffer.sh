#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
cat <<EOF | \matlab -nodesktop -nosplash #> sigProc.log 
capFile='cap_tmsi_mobita_black';
overridechnms=1;
startSigProcBuffer();
%quit;
EOF
