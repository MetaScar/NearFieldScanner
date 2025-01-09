clc; clear; close all

% for now going to declare center, but future code should have user
% determine the center
x_center = -558.8;
x_max = -52.8;
x_min = -898.8;

% x = serialport('COM3', 115200);

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

X_position