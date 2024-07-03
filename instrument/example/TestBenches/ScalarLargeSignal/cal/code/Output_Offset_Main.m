%% Output Offset TB 
% This testbench relies on and matches the input calibration data from an
% input offset calibration. The reference meter is now the "input
% calibration meter" and the 
%% Clear and Reset 
close all 
clear all
clc

%% Parameters 
%Parameters to Set 
power                   = -15; 

%Addresses
% Power Meters
POWER_METER_ADR         = 'GPIB1::13::INSTR';
RF_INPUT_POWER_ADR      = 'USB0::0x2A8D::0xA618::MY57390007::0::INSTR'; 
RF_OUTPUT_POWER_ADR     = 'USB0::0x2A8D::0xA618::MY57390010::0::INSTR'; 
% RF SWEEPER
RF_SOURCE_ADR           = 'GPIB1::20::INSTR'; 


%% Start Instruments 
%turn of warnings temporarily 
warning('off','all')
%notify user of instrument connection
fprintf('Initializing Instruments...')
%rf source 
rfSource    = instruments.SigGen.k83650A('Address',RF_SOURCE_ADR);
%power meters 
powerMeter  =   instruments.PowerMeter.N1914A('Address',POWER_METER_ADR, ...
                                              'Channel1Name','pwrmeterIn',...
                                              'Channel3Name','pwrmeterOut'); 
fprintf('Done.\n')
%now turn warnings back on 
warning('on','all') 

%pull out the power meter channel abstractions
pwrmeterIn  = powerMeter.pwrmeterIn; 
pwrmeterOut = powerMeter.pwrmeterOut; 

%% The User Needs to Locate the Input Offset Calibration Data
%have user select the input calibration data
[fn,pn] = uigetfile({'*.mat','Datafile'}, ...
                    'Please select the input offset calibration data');

%make sure that a input calibration data file is present
assert(not(isequal(pn,0)),'Calibration data must be selected.'); 

%load the data
inCalData = load(fullfile(pn,fn)); 

%make sure that the loaded data contains the cal results
assert(isfield(inCalData,'inputCalResults'), ...
                'Calibration data not in selected file.'); 

%% Run the Calibration 
%Run the calibration with both power meters
try
    outputCalResults = ScalarOutputCal(rfSource,pwrmeterIn,pwrmeterOut,...
                                     power,inCalData.inputCalResults,true);
catch ME
    rfSource.set('State','OFF')
    rethrow(ME)
end

%% Plot the Results
figure 
hold on 
plot([outputCalResults.freq].*1e-9,[outputCalResults.offset],'ko'); 
title('Calibration Results')
xlabel('Frequency (GHz)')
ylabel('Calculated Offset (dB)')

%% For Saving the Data 
[fn,pn] = uiputfile('results.mat','Save results'); 
%open uiputfile dialog
if not(isequal(pn,0))
    save(fullfile(pn,fn),'outputCalResults'); 
else
    warning('User aborted calset save.')
end

