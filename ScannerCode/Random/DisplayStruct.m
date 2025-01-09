clc; clear; close all

% given the struct variable output from organizeData function, display the
% magnitude and phase in space with colors
% Resource: https://optics.ansys.com/hc/en-us/articles/360034404014-Creating-2D-image-plots-with-MATLAB

% load previous file (for testing)
orgData = load("2024-07-03_Test1.mat");

dispS21Data(orgData)

function dispS21Data(data)
% speed of light
c = 299792458;
% lambda in mm
lambda = (c/data.var.frequency)*1000;
% dimensional data in terms of lambda
x = data.var.x / lambda;
y = data.var.y / lambda;
% S21 data
s = data.var.s;

% Calculate magnitude
mag = 20*log10(abs(s));

% Calculate phase
phase = angle(s);

% Determine unique x and y values
unique_x = unique(x);
unique_y = unique(y);

% Create a grid of NaNs
Mag = NaN(length(unique_y), length(unique_x));
Phase = NaN(length(unique_y), length(unique_x));

% Fill the grid with corresponding z values
for i = 1:length(mag)
    % Find indices in unique_x and unique_y
    [~, idx_x] = ismember(x(i), unique_x);
    [~, idx_y] = ismember(y(i), unique_y);
    
    % Assign z value to the correct position in Z
    Mag(idx_y, idx_x) = mag(i);
    Phase(idx_y, idx_x) = phase(i);
end

% Plot using pcolor
figure
pcolor(unique_x, unique_y, Mag);
colorbar;
xlabel('x/\lambda (mm)');
ylabel('y/\lambda (mm) ');
title('S21 Magnitude (dB)');
shading interp;
figure
pcolor(unique_x, unique_y, Phase);
colorbar;
xlabel('x/\lambda (mm)');
ylabel('y/\lambda (mm) ');
title('S21 Phase');
shading interp;



end