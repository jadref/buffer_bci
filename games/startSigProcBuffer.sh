#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
cat <<EOF | \matlab -nodesktop -nosplash
capFile='cap_tmsi_mobita_p300';
startSigProcBuffer
quit;
EOF
