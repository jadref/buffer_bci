#!/bin/bash
scriptDir=`dirname ${BASH_SOURCE[0]}`
cd $scriptDir
source ../../utilities/findMatlab.sh
if [[ $matexe == *matlab ]]; then  args=-nodesktop; fi
cat <<EOF | $matexe $args
cd $scriptDir
runIM;
quit;
EOF
