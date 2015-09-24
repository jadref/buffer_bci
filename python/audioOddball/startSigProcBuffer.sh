#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../../utilities/findMatlab.sh
if [[ $matexe == *matlab ]]; then  args=-nodesktop; fi
cat <<EOF | $matexe $args
run ../../utilities/initPaths.m;
startSigProcBuffer('epochEventType','stimulus.target','freqband',[.1 .3 20 25],...
                   'clsfr_type','erp','trlen_ms',1000,'maxEvents',30*3,'erpOpts',{'closeFig',0});
quit();
EOF
