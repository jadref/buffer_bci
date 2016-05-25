#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../../utilities/findMatlab.sh
if [ $# -lt 1 ]; then 
  port=1972;
else
 port=$1;
  shift;
fi
if [[ $matexe == *matlab ]]; then  args=-nodesktop; fi
echo "sigViewer([],$port)" | $matexe $args
