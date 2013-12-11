#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
cat <<EOF | $matexe -nodesktop -nosplash
run ../utilities/initPaths; 
capFile='cap_tmsi_mobita_black';
% amplifier specific thresholds
if ( ~exist('capFile','var') ) capFile='1010'; end; %'cap_tmsi_mobita_num'; 
if ( ~isempty(strfind(capFile,'tmsi')) ) thresh=[.0 .1 .2 5]; badchThresh=1e-4; overridechnms=1;
else                                     thresh=[.5 3];  badchThresh=.5;   overridechnms=0;
end
% do the actual cap-fitting stuff
capFitting('capFile',capFile,'overridechnms',overridechnms,'noiseThresholds',thresh,'badChThreshold',badchThresh);
quit;
EOF
