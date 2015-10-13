set batdir=%~dp0
call ../../utilities/findPython.bat
%pythonexe% streamBCIStimulus_portaudio.py
