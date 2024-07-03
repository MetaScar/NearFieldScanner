%% Input Offset Main 

%% Clear and Reset 
close all 
clear all
clc

%% Parameters 
%Parameters to Set 
power                   = -25; %power of the sweeper (not Pavs)
freqList                = linspace(20e9,40e9,81); 

%Addresses
% Power Meters
POWER_METER_ADR         = 'GPIB1::13::INSTR';
RF_INPUT_POWER_ADR      = 'USB0::0x2A8D::0xA618::MY57390007::0::INSTR'; 
RF_REF_POWER_ADR        = 'USB0::0x2A8D::0xA618::MY57390010::0::INSTR'; 
% RF SWEEPER
RF_SOURCE_ADR           = 'GPIB1::20::INSTR'; 

%% Make sure instrument library is on the path 

addpath('../../instrument'); 

%% Have User Provide The Save Location
[FN,PN] = uiputfile('results.mat','Save results'); 


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

%% Run the Calibration 
%Run the calibration with the reference power meter. 
try
    inputCalResults = ScalarInputCal(rfSource,pwrmeterIn,pwrmeterOut, ...
                                        power,freqList,true); 
catch ME
    %turn the RF source off
    rfSource.set('State','OFF'); 
    %close the waitbar
    if exist('wtbr','var')
        close(wtbr)
    end
    rethrow(ME); 
end

%% Plot the Results 

figure
hold on 
% plot(freqList.*1e-9,inOffsetFunction(freqList),'kx'); 
plot(freqList.*1e-9,[inputCalResults.offset],'ko');
title('Scalar Input Calibration'); 
xlabel('Frequency (GHz)')
ylabel('Calculated Offset (dB)')

%% For Saving the Data 
%open uiputfile dialog
if not(isequal(PN,0))
    save(fullfile(PN,FN),'inputCalResults'); 
else
    warning('User aborted calset save.')
end
