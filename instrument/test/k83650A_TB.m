%% 83650A Test Bench

%% Clear and Reset 
close all
clear all
clc

%% Parameters 

%initialize sig gen 
% sigGen = instruments.SigGen.k83650A('Address','GPIB1::20::INSTR'); 
sigGen = instruments.SigGen.k83650A(); 

