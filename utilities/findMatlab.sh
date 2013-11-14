#!/bin/bash
export matexe=`which matlab`
if [ -z "$matexe" ]; then
    if [ `uname -s` == 'Darwin' ]; then # MAC
        mdirs=`\ls -dt /Applications/MATLAB*`;
        matexe=${mdirs%%$'\n'*}/bin/matlab;
    fi
fi
export matexe
