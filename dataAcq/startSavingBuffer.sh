#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
savedir="$HOME/output/RacingGame/$$"
echo SavingDir: $savedir
if [ `uname -s`=='Linux' ]; then
	./glnx86/recording $savedir 1972 
else
	./glnx86/recording $savedir 1972
fi
