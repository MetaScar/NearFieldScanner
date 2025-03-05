% quick speed test for getting VNA data
% see how to speed up the S parameter measurements for the VNA
% STATUS
% It appears ASCII form is about twice as slow as Real 64 (binary, 64
% bits) and four times a slow as Real 32 (binary, 32 bits).
% The signifcant slow down happens somewhere in Joel's code. Not sure
% why though. Could be organization into S Parameters.
%
% Optimizing speed further might only be worth it if only extracting S21
% parameter. Method for doing so unknown

clc; clear; close all

% add instruments folder
addpath("..\");

% connect to VNA
vna = visadev("GPIB0::16::INSTR");

% set data type to ASCII

writeline(vna, ":FORM:DATA ASC");
writeread(vna, "FORM:DATA?")

tic
asc_data = writeread(vna, "CALC:DATA:SNP:PORTS? '1,2'");
toc

tic
bin_all = writeread(vna, "CALC:DATA? SDATA");
% bin_all = readbinblock(vna);
toc

writeline(vna, "FORM:DATA REAL,64");
writeread(vna, "FORM:DATA?")

tic
writeline(vna, "CALC:DATA:SNP:PORTS? '1,2'");
bin_data = readbinblock(vna);
toc

writeline(vna, "FORM:DATA REAL,32");
writeread(vna, "FORM:DATA?")

tic
writeline(vna, "CALC:DATA:SNP:PORTS? '1,2'");
bin_small_data = readbinblock(vna);
toc

writeline(vna, ":FORM:DATA ASC");
writeread(vna, "FORM:DATA?")

clear vna

vna = instruments.VNA.N5224A("Address", "GPIB0::16::INSTR");


tic
joel_data = vna.get("SNP", {1,2});
toc

