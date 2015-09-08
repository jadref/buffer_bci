set batdir=%~dp0
call ..\..\utilities\findPython.bat
%pythonexe% mbrStimulus_portaudio.py
