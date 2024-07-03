%% E3649A Test Bench

%% Clear and Reset 
close all
clear all
clc

%% Test Parameters 

% supply = instruments.PSU.E3649A('Address','GPIB1::5::INSTR',...
%                                 'Output1Name','gate',...
%                                 'Output2Name','drain');
supply = instruments.PSU.E3649A('Output1Name','gate',...
                                'Output2Name','drain',...
                                'Channel1Name','gate',...
                                'Channel2Name','drain');
% supply = instruments.PSU.E3649A('Output1Name','gate',...
%                                 'Output2Name','drain');

%% Test Individual Channel Settings 


