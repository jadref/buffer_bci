#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
if [[ $matexe == *matlab ]]; then  args=-nodesktop; fi
cat <<EOF | $matexe $args
capFile='cap_tmsi_mobita_black';
overridechnms=1;
startSigProcBuffer();
%quit;
EOF
