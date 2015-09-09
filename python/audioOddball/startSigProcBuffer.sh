#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
if [[ $matexe == *matlab ]]; then  args=-nodesktop; fi
cat <<EOF | $matexe $args
run ../../utilties/initPaths.m;
startSigProcBuffer('epochEventType','stimulus.target','freqband',[.1 .3 20 25],...
                   'clsfr_type','erp','trlen_ms',trlen_ms);
EOF
