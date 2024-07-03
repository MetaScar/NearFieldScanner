clc; clear; close all

% Connect to serial
x = serialport('COM6', 115200);

ZPosition(x)

% Prompt user to move to desired machine X position, code Z position. 
% User input will change the relative position of the machine X position. 
% Code uses recursion. 
% Escape condition is an input of 0.
% 2024-07-03: Untested
function ZPosition(x)
z_min = -898.8;
z_max = -446.8;

a = input("This code will move the probe closer or futher away from the AUT. Positive numbers will move it closer, negative further. Enter 0 to stop movement controls.\n" + ...
    "Please provide input (mm): ", "s");

inputNumCheck(a);

numInput = str2double(a);

if numInput == 0
    return
end

while (numInput > z_max) || (numInput < z_min)
    a = input("Input goes beyond machine limits! Please try again: ", "s");
    inputNumCheck(a);
    numInput = str2double(a);
end

command = "G91 X" + numInput;
writeline(x, command);
WaitMotionComplete(x);
ZPosition(x);

end

% input response (string), check whether string only has numbers. If it
% doesn't will prompt user until it is a number
% Note: requires original prompt for number to recieve string.
% Ex: input("...", "s") rather than input("...")
% 2024-07-03 Locally Tested, not Machine Tested
function a = inputNumCheck(response)
while isnan(str2double(response))
    response = input("Input is not a number!  Please try again: ", "s");
end
a = response;
end