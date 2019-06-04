set batdir=%~dp0
cd %batdir%
call ../../utilities/findPython.bat
%pythonexe% EventForwarder.py 131.174.104.48 1972
