#! /usr/bin/env bash
cd `dirname "${BASH_SOURCE[0]}"`
buffdir="$( pwd )"
exedir=linux/arm32bit
buffexe=eego2ft
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${exedir}

#identify the config file to use
if [ -r ${buffdir}/${buffexe%2ft}.cfg ]; then
    configFile=${buffdir}/${buffexe%2ft}.cfg
else
    configFile=-
fi
${exedir}/${buffexe} ${configFile} $*
