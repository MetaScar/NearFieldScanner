%% Testbench for the N1914A Power Meter

%% Clear and Reset
close all
clear all
clc

%% Open Up the Power Meter 

% initialize with address
PM = instruments.PowerMeter.N1914A('Address','GPIB1::13::INSTR', ...
                                    'Channel1Name','pwrmeterIn',...
                                    'Channel3Name','pwrmeterOut',...
                                    'DebugComm',true); 

% PM = instruments.PowerMeter.N1914A('Channel1Name','pwrmeterOut','Channel3Name','pwrmeterIn'); 