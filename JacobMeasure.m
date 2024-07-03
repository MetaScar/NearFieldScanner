%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Huge thanks to Paul Flaten and Joel Johnson for the library used to
% control the PNA. 

% Standard cleanup at beginning of program
clc; clear; close all;

% Setup pna object
pna = instruments.VNA.N5224A("Address", "GPIB0::16::INSTR");
% Make the VNA screen nice and fancy
pna.set("View", "Default");
% Grab an S-Parameter Object
% Note that anything can go in the second parameter of the function
S = pna.get("S2P", "");

% If you wish for the PNA to make multiple measurements and take the
% average of these measurements, you can use this command, where 30 is 
% the number of measurements to be averaged:

% pna.set("Average", 30);

% Now when you get a measurement, it will be the average of 30 measurements
% S_30 = pna.get("S2P, "");