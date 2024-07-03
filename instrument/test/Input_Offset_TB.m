%% Input Offset TB 

%% Clear and Reset 
close all 
clear all
clc

% %% Load Offset Data 
% load('./MeterCal/Fine_MeterCalResults.mat');
% %assume meter1 is the accurate meter and don't use an offset 
% offsetFreqs     = [results(1,:).Frequency];
% meter1Power     = [results(1,:).Meter1Power]; 
% meter2Power     = [results(1,:).Meter2Power]; 
% outMeterOffset  = meter1Power - meter2Power; 

%% Parameters 
%Parameters to Set 
power                   = -20; %power of the sweeper (not Pavs)
freqList                = linspace(2e9,50e9,481); 

%Addresses
% Power Meters
POWER_METER_ADR         = 'GPIB1::13::INSTR';
RF_INPUT_POWER_ADR      = 'USB0::0x2A8D::0xA618::MY57390007::0::INSTR'; 
RF_REF_POWER_ADR        = 'USB0::0x2A8D::0xA618::MY57390010::0::INSTR'; 
% RF SWEEPER
RF_SOURCE_ADR           = 'GPIB1::20::INSTR'; 
%% Setup Offsets 
%Coupler S-Parameter Files 
%probes
probes = sparameters(['C:\Users\W-band\Documents\Paul' ...
                        '\ScalarPowerCal_Char\Thru\probes_thru.s2p']);

% Input 
inputThru   = sparameters(['C:\Users\W-band\Documents\Paul' ...
                             '\ScalarPowerCal_Char\Input\RFin_RFout.s2p']);

inputCpl    = sparameters(['C:\Users\W-band\Documents\Paul' ...
                             '\ScalarPowerCal_Char\Input\RFin_CPL.s2p']);

% Output 
outputCpl   = sparameters(['C:\Users\W-band\Documents\Paul' ...
                             '\ScalarPowerCal_Char\Output\RFin_cpl.s2p']);

%construct the function that will describe the input offset function (Note:
%this part assumes that the same frequency setting was used on all
%measurements. 
inputOffset = 20.*log10(abs(rfparam(probes,2,1)))/2 + ...
              20.*log10(abs(rfparam(inputThru,2,1))) - ...
              20.*log10(abs(rfparam(inputCpl,2,1))); 
inOffsetFunction = @(f) interp1(probes.Frequencies,inputOffset,f,...
                                "linear","extrap");

outputOffset = -20.*log10(abs(rfparam(probes,2,1)))./2 -...
                20.*log10(abs(rfparam(outputCpl,2,1))); 
outOffsetFunction = @(f) interp1(probes.Frequencies,outputOffset,f,...
                                "linear","extrap");

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
% pwrmeterIn  = instruments.PowerMeter.U8487A('Address',RF_INPUT_POWER_ADR); 
% pwrmeterOut = instruments.PowerMeter.U8487A('Address',RF_REF_POWER_ADR); 
powerMeter  =   instruments.PowerMeter.N1914A('Address',POWER_METER_ADR, ...
                                              'Channel1Name','pwrmeterIn',...
                                              'Channel3Name','pwrmeterOut'); 
fprintf('Done.\n')
%now turn warnings back on 
warning('on','all')

%pull out the power meter channel abstractions
pwrmeterIn  = powerMeter.pwrmeterIn; 
pwrmeterOut = powerMeter.pwrmeterOut; 

%% Set Up Power Meters
%apply offset to output power meter 
% pwrmeterOut.offsetFreqs = offsetFreqs; 
% pwrmeterOut.offsetVals  = outMeterOffset; 
% pwrmeterOut.useOffset   = true; 

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
probeLossInterp = @(f) interp1(probes.Frequencies, ...
                               20.*log10(abs(rfparam(probes,2,1)))./2, f);
figure
hold on 
% plot(freqList.*1e-9,inOffsetFunction(freqList),'kx'); 
plot(freqList.*1e-9,[inputCalResults.offset] - probeLossInterp(freqList),'ko');
title('VNA vs Scalar Calibration'); 
xlabel('Frequency (GHz)')
ylabel('Calculated Offset (dB)')
% legend('VNA','Power Meter')

%% For Saving the Data 
%open uiputfile dialog
if not(isequal(PN,0))
    save(fullfile(PN,FN),'inputCalResults'); 
else
    warning('User aborted calset save.')
end
