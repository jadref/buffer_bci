#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
if [[ $matexe == *matlab ]]; then  args=-nodesktop; fi
cat <<EOF | $matexe $args
startSigProcBuffer('epochEventType','stimulus.target','freqband',[.1 1 10 12],'clsfr_type','erp','trlen_ms',700);
%quit;
EOF
