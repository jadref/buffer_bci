set batdir=%~dp0
cd %batdir%
call ../../utilities/findPython.bat
%pythonexe% CybathlonAdapter.py
