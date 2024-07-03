clc; clear; close all

% Connect to serial
x = serialport('COM6', 115200);
% Pause for 5 seconds to allow for connection
pause(5);

Homing(x)
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

currentPos = getPos(x, "Z");

while (currentPos + numInput > z_max) || (currentPos + numInput < z_min)
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

% Get position of grbl. Axis input options are "X", "Y", and "Z"
function pos = getPos(x, axis)
flush(x);
% send command to check status
writeline(x, '?\n');
% get response
grbl_out = readline(x);
grbl_response = char(decode_unicode(strip(grbl_out)));

% make sure its the status rather than an ok
if strcmp(grbl_response(1), "<") & strcmp(grbl_response(end), ">")
    start_index = 0;
    end_index = 0;
    for i = 1:length(grbl_response)
        if strcmp(grbl_response(i), "|") & (start_index == 0)
            start_index = i + 1;
        elseif strcmp(grbl_response(i), "|") & (start_index ~= 0) & (end_index == 0)
            end_index = i - 1;
            break;
        end
    end
    positions = grbl_response(start_index:end_index);
    % give the position the user asked for
    start_index = 0;
    end_index = 0;
    if strcmp(axis, "X") % note: code X (which is what will be returned) is machine y
        for i = 1:length(positions)
            if strcmp(positions(i), ",") & (start_index == 0)
                start_index = i + 1;
            elseif strcmp(positions(i), ",") & (start_index ~= 0) & (end_index == 0)
                end_index = i - 1;
                break;
            end
        end
        pos = str2double(positions(start_index:end_index));
    elseif strcmp(axis, "Y") % note: code Y (which is what will be returned) is machine z
        for i = 1:length(positions)
            if strcmp(positions(i), ",") & (start_index == 0)
                start_index = 1;
            elseif strcmp(positions(i), ",") & (start_index == 1)
                start_index = i + 1;
                break;
            end
        end
        pos = str2double(positions(start_index:end));
    elseif strcmp(axis, "Z") % note: code Z (which is what will be returned) is machine x
        for i = 1:length(positions)
            if strcmp(positions(i), ":") & (start_index == 0)
                start_index = i + 1;
            elseif strcmp(positions(i), ",") & (start_index ~= 0) & (end_index == 0)
                end_index = i - 1;
                break;
            end
        end
        pos = str2double(positions(start_index:end_index));
    end
else 
    print("Error: Command ? didn't return status of machine");
    quit
end

end

function out = decode_unicode(in_unicode)
out = string(char(in_unicode));
end

function Homing(x)
writeline(x, "$HZ");
WaitForOk(x);
writeline(x, "$HX");
WaitForOk(x);
writeline(x, "$HY");
WaitForOk(x);
check = input("Was the homing sucessfully completed? (y/N): ", 's');
if (check ~= "y")
    Homing(x);
end
end
