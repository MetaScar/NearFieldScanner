% Note: if getting error with instruments.VNA.N5224A, then you need to
% include the instrument folder for your matlab code

clc; clear; close all

% add instrument path manually
addpath(".\instrument\");

% Connect to serial
x = serialport('COM6', 115200);
% the serial readline command has a timeout that will stop program before
% procedures (namely homing) are completed. So extend time as needed
x.Timeout = 120;

% Pause for 5 seconds to allow for connection
pause(5);
% home the machine
Homing(x);

% for now going to declare center, but future code should have user
% determine the center
x_center = -558.8;
X_position = FindXPos(x_center);

% y axis now!
% for now going to declare center, but future code should have user
% determine the center
y_center = -438.2;
Y_position = FindYPos(y_center);

% positions have been determined! Convert to string
Y_pos_str = string(Y_position);
X_pos_str = string(X_position);

% Create table for putting data
sizeY = size(Y_position);
sizeX = size(X_position);
rows = sizeX(1) * sizeY(1);
sz = [rows, 3];
varTypes = ["double", "double", "sparameters"];
varNames = ["X position", "Y position", "S parameters"];
paramsTable = table('Size', sz,'VariableTypes', varTypes, 'VariableNames',varNames);

% Setup pna object
pna = instruments.VNA.N5224A("Address", "GPIB0::16::INSTR");
% Make the VNA screen nice and fancy
pna.set("View", "Default");

tablePos = 1;
odd = true;
j = 1;
for i = 1:size(Y_pos_str)
    loop = true;
    while(loop)
        % prep command
        command = "G90 Y" + X_pos_str(j) + " Z" + Y_pos_str(i);
        % send command
        writeline(x, command);
        % wait until the motion is complete
        WaitMotionComplete(x);
        disp('Position: X:' + X_pos_str(j) + ' Y: ' + Y_pos_str(i));
        % Grab an S-Parameter Object
        % Note that anything can go in the second parameter of the function
        S = pna.get("S2P", "");
        paramsTable(tablePos, :) = {X_position(j)-x_center, Y_position(i)-y_center, S};
        tablePos = tablePos + 1;
        % if going the odd route,
        if odd
            % if j has reached the end, then escape the loop and set j such
            % that it will be 1
            if(isequal(j,size(X_pos_str,1)))
                loop = false;
                j = size(X_pos_str,1) - 1;
                odd = false;
            end
            % add 1 to j
            j = j + 1;
            % if it's even
        elseif ~odd
            % check if loop is done
            if(isequal(j, 1))
                loop = false;
                j = 2;
                odd = true;
            end
            % subtract 1 from j
            j = j - 1;
        end
    end

end

paramsTable


function X_position = FindXPos(x_center)
x_max = -50.8;
x_min = -898.8;

% would prob be better if prompting for X was a function. That way if it
% needs to be redone, you just call the function

% Prompt user for desired X width
X = input('How wide (x-axis) do you want the scan (mm): ');


% Check loop

go = true;
while go
    check1 = true;
    check2 = true;
    check3 = true;
    % Check if negative number
    while (X < 0)
        X = input('You have input a negative number. Please try again: ');
        check3 = false;
    end
    % Check if width is beneath max
    while(x_center + (X/2) > x_max)
        X = input('Sorry! Too wide. Please try again: ');
        check1 = false;
    end
    % Check if width is above min
    while(x_center - (X/2) < x_min)
        X = input('Sorry! Too wide. Please try again: ');
        check2 = false;
    end
    % if all checks passed, can procede
    if (check1 & check2 & check3)
        go = false;
    end
end

% Checks have been passed! Now ask for max deltax
deltax = input('Input maximum delta x: ');

% Make sure it's positive
while (deltax < 0)
    deltax = input('Delta x cannot be negative! Please try again: ');
end
% Make sure user is ok with delta X being greater than width
if (deltax > X)
    confirm = input('Delta x is greater than width! Are you ok with this? (y/N): ', 's');
    if (confirm ~= "y")
        return
    end
    % if max deltax is greater than width, then set deltax to width
    deltax = X;
end

% Calculate # of points
npoints = ceil(X/deltax) + 1;
% Confirm with user if this is ok
cont = input("The number of points will be " + npoints + ". Is this ok? (y/N): ", 's');
if (cont ~= "y")
    % in future; reprompt for X width. This is temp solution
    return
end

deltax = X / (npoints - 1);

X_position = zeros(npoints, 1);
% fill out array of x axis points
for i = 1:npoints
    X_position(i) = (x_center - (X/2)) + ((i - 1) * deltax);
end
end

function Y_position = FindYPos(y_center)
y_max = -1.2;
y_min = -654.2;

% Prompt user for desired Y width
Y = input('How tall (y-axis) do you want the scan (mm): ');

% Check loop

go = true;
while go
    check1 = true;
    check2 = true;
    check3 = true;
    % Check if negative number
    while (Y < 0)
        Y = input('You have input a negative number. Please try again: ');
        check3 = false;
    end
    % Check if width is beneath max
    while(y_center + (Y/2) > y_max)
        Y = input('Sorry! Too wide. Please try again: ');
        check1 = false;
    end
    % Check if width is above min
    while(y_center - (Y/2) < y_min)
        Y = input('Sorry! Too wide. Please try again: ');
        check2 = false;
    end
    % if all checks passed, can procede
    if (check1 & check2 & check3)
        go = false;
    end
end

% Checks have been passed! Now ask for max deltax
deltay = input('Input maximum delta y: ');

% Make sure it's positive
while (deltay < 0)
    deltay = input('Delta y cannot be negative! Please try again: ');
end
% Make sure user is ok with delta X being greater than width
if (deltay > Y)
    confirm = input('Delta y is greater than width! Are you ok with this? (y/N): ', 's');
    if (confirm ~= "y")
        return
    end
    % if max deltax is greater than width, then set deltax to width
    deltay = Y;
end

% Calculate # of points
npoints = ceil(Y/deltay) + 1;
% Confirm with user if this is ok
cont = input("The number of points will be " + npoints + ". Is this ok? (y/N): ", 's');
if (cont ~= "y")
    % in future; reprompt for X width. This is temp solution
    return
end

deltay = Y / (npoints - 1);

Y_position = zeros(npoints, 1);
% fill out array of y axis points
for i = 1:npoints
    Y_position(i) = (y_center - (Y/2)) + ((i - 1) * deltay);
end
end

function out = decode_unicode(in_unicode)
out = string(char(in_unicode));
end

function WaitForOk(x)
reading = true;

while reading
    grbl_out = readline(x);
    grbl_response = decode_unicode(strip(grbl_out));
    disp(grbl_response);
    if isequal(grbl_response, 'ok')
        reading = false;
    end
    pause(0.2); % apparently pull at 5 Hz
end
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

% Code by Samuel Freitas 5/31/2022
% https://github.com/Sam-Freitas/python_to_GRBL/blob/main/simple_stream.m
function WaitMotionComplete(x)
% wait a second
pause(1);
% used later to escape function
idle_counter = 0;

while 1
    % clear the buffer for input
    flush(x, "input");
    % send command to check status
    writeline(x, '?\n');
    % get response
    grbl_out = readline(x);
    grbl_response = decode_unicode(strip(grbl_out));
    % check if response isn't 'ok'. If 'Idle' for 10 loops, movement
    % done
    if ~isequal(grbl_response,'ok')

        if contains(grbl_response,'Idle')
            idle_counter = idle_counter + 1;
        end
    end

    if idle_counter > 10
        break
    end
    % in the GRBL documentation it reccomends a 5Hz rate for the '?' command
    pause(0.2)
end
end

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