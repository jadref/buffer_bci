#!/bin/bash
cd `dirname $0`
mcs -debug /target:library /out:Buffer.dll *.cs
