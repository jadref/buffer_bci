call ..\utilities\findMatlab.bat
start "matlab" %matexe% -nodesktop -nosplash -minimize -singleCompThread -r "runSpeller;quit;"
