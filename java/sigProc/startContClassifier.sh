#!/bin/bash 
clsfrfile="clsfr_theta_tpref.txt"
if [ $# -gt 0 ];
   clsfrfile=$1
fi
java -cp "../../dataAcq/buffer/java/BufferClient.jar:lib/commons-math3-3.4.jar:build/jar/MatrixAlgebra.jar:build/jar/ContinuousClassifier.jar" nl.dcc.buffer_bci.signalprocessing.ContinuousClassifier localhost:1972 $clsfrfile 1000 100
