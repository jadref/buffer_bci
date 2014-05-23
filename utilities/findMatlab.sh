#!/bin/bash
export matexe=`which matlab`
if [ -z "$matexe" ]; then
    if [ `uname -s` == 'Darwin' ]; then # MAC
        mdirs=`\ls -dt /Applications/MATLAB*`;
	if [ ! -z "$mdirs" ]; then
        matexe=${mdirs%%$'\n'*}/bin/matlab;
	fi
fi
if [ -z "$matexe" ]; then  # see if Octave is installed, use it as fall-back
		  export matexe=`which octave`
    echo $matexe
    fi
fi
export matexe
