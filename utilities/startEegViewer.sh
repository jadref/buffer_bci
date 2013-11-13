#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
cat <<EOF | \matlab -nodesktop  
run ../utilities/initPaths; 
%eegViewer();
eegViewer([],[],'capFile','cap_tmsi_mobita_black','overridechnms',1);
quit;
EOF
