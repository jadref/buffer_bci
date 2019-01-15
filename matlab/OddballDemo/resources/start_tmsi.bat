@echo off
set thisdir=%~dp0
set tmsiexec=%thisdir%tmsi2ft_v7.exe
set cfgfld=%thisdir%resources\
@echo on
%tmsiexec% u s 2 31 512 %cfgfld%tmsi_porti_cap16.cfg 1972 localhost 8000
