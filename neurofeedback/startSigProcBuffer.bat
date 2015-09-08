call ..\utilities\findMatlab.bat
echo "configureNF;nfStartSigProcBuffer();quit;" | %matexe% %matopts%
