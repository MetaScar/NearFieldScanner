clc; clear; close all
import motorControl.*

grbl = motorControl;

grbl = connectGRBL(grbl);

fig = uifigure;
connect = uibutton(fig, ...
    "Text", "Connect Serial", ...
    "Tooltip", "if this doesn't work, blame the dev", ...
    "Position", [0, 0, 100, 100], ... % x position, y position, width, height
    "ButtonPushedFcn", @(src,event) connectBoi(grbl));
unlock = uibutton(fig, ...
    "Text", "Unlock Operation", ...
    "Position", [200, 0, 100, 100], ... % x position, y position, width, height
    "ButtonPushedFcn", @(src,event) unlockGRBL(grbl));
moveX = uibutton(fig, ...
    "Text", "moveX", ...
    "Position", [300, 0, 100, 100], ... % x position, y position, width, height
    "ButtonPushedFcn", @(src,event) moveXFunc(grbl));

function connectBoi(obj)
    obj = connectGRBL(obj);
end