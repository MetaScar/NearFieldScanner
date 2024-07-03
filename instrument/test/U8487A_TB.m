%% Testbench for the U8487A Bench

%% Clear and Reset 
close all
clear all
clc

%% Initialize the Instrument

% pmIn = instruments.PowerMeter.U8487A(); 

pmIn = instruments.PowerMeter.U8487A('Address',...
                        'USB0::0x2A8D::0xA618::MY57390007::0::INSTR'); 