function [coords]=mkPacman()
theta=linspace(1/8,1-1/8,12);
coords=[0 0;cos(theta(:)*2*pi) sin(theta(:)*2*pi);0 0]';