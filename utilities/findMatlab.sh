#!/bin/bash
export matexe=`which matlab`
if [ -z "$matexe" ]; then
    if [ `uname -s` == 'Darwin' ]; then # MAC
        mdirs=`\ls -dt /Applications/MATLAB*`;
        matexe=${mdirs%%$'\n'*}/bin/matlab;
	 else # see if Octave is installed, use it as fall-back
		  export matexe=`which octave`
    fi
fi
export matexe
