%% k34410A Test Bench

%% Clear and Reset 
close all
clear all
clc

%% Test Parameters 

mmeter = instruments.Multimeter.k34410A('Address','GPIB1::19::INSTR');

%% Test Individual Channel Settings 


