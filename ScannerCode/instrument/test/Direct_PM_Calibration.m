%% Generating Correction for Output Power Meter

%% Clear and Reset 
close all 
clear all
clc

%% Parameters 
%Settings 
% Plot Settings
PLOT_RESULTS            = 1; 

% Sweep
freq                    = linspace(15,25,21);       %GHz
power                   = [-10];                    %dBm
meanConvergence         = 5e-5;                     %absolute relative error threshold of the running mean value
minNumAverages          = 3;                        
maxNumAverages          = 50;                       %maximum number of averages to run

%Power meter settins 
PM_CAL_STEP_TIME = 0.5; 
PM_CAL_WAIT_TIME = 20; 

%Iq structure 

%Instrument Addresses 
% Power Meters 
RF_INPUT_POWER_ADR      = 'USB0::0x2A8D::0xA618::MY57390007::0::INSTR'; 
RF_OUTPUT_POWER_ADR     = 'USB0::0x2A8D::0xA618::MY57390010::0::INSTR'; 
% Multimeter 
MULTIMETER_ADR          = 'GPIB1::19::INSTR'; 
% PSU
MMIC_PSU_ADR            = 'GPIB1::5::INSTR'; 
EQUIP_PSU_ADR           = 'GPIB1::4::INSTR'; 
% RF SWEEPER
RF_SOURCE_ADR           = 'GPIB1::20::INSTR'; 

%% Initialize Results 
%initialize fields here
results.SourcePower  = []; 
results.Frequency    = [];
results.Meter1Power  = []; 
results.Meter1Offset = []; 
results.Meter1Conv   = [];
results.Meter2Power  = []; 
results.Meter2Offset = [];
results.Meter2Conv   = [];

%create results
results = repmat(results,length(power),length(freq)); 

%% Create the Waitbar

wtbr = waitbar(0,sprintf('Initializing Bench...')); 

%% Setup Instruments
%turn of warnings temporarily 
warning('off','all')
%notify user of instrument connection
fprintf('Initializing Instruments...')
rfSource    = instruments.SigGen.k83650A('Address',RF_SOURCE_ADR); 
pwrmeterIn  = instruments.PowerMeter.U8487A('Address',RF_INPUT_POWER_ADR); 
pwrmeterOut = instruments.PowerMeter.U8487A('Address',RF_OUTPUT_POWER_ADR); 
fprintf('Done.\n')
%now turn warnings back on 
warning('on','all')

%% Notify User For Stage 1

fprintf(['Please connect the input power meter to the RF Source' ...
         ' and press any key to continue...\n']);
pause;

%% Wait for Input Power Meter to Zero
if exist('wtbr','var'); waitbar(0,wtbr,'Setup: Zeroing Power Meter...'); end
pwrmeterIn.zero; 

PM_TIME_STEPS = 0:PM_CAL_STEP_TIME:PM_CAL_WAIT_TIME; 
for step = PM_TIME_STEPS
    %update the waitbar
    if exist('wtbr','var')
        waitbar(step./PM_CAL_WAIT_TIME,wtbr,'Setup: Zeroing Power Meter...'); 
    end
    %wait a moment
    pause(PM_CAL_STEP_TIME); 
end

%% Turn the RF Source ON 
rfSource.set('Power',-40,'Frequency',freq(1),'State','ON');

%% Now Iterate Through Powers and Frequencies

if exist('wtbr','var')
    numSteps    = numel(results); 
    stepIndex   = 0; 
end 

for iPower = 1:length(power)
    %get the current power level
    presentPower = power(iPower); 
    %set the current power level
    rfSource.set('Power',presentPower); 

    for iFreq = 1:length(freq)
        %get the current frequency
        presentFreq = freq(iFreq); 

        %set the current frequency 
        rfSource.set('Frequency',presentFreq); 
        pwrmeterIn.frequency(presentFreq); 

        %array for measurments 
        measArray = zeros(1,maxNumAverages);
        %creat new header
        fprintf('### Freq = %0.2f Power = %0.2dBm ###\n',presentFreq,presentPower); 
        %update waitbar
        if exist('wtbr','var')
            stepIndex = stepIndex + 1; 
            waitbar(stepIndex./numSteps,wtbr,...
                sprintf('Power: %0.2fdBm, Frequency: %0.2fGHz',presentPower,presentFreq)); 
        end

        %set results power and frequency
        results(iPower,iFreq).SourcePower = presentPower; 
        results(iPower,iFreq).Frequency   = presentFreq.*1e9; 

        %take measurments over and over again until the the convergence
        %criteria is met
        for averageIndex = 1:maxNumAverages
            %take a measurement 
            measArray(averageIndex) = pwrmeterIn.measure(0.001); 
            if averageIndex >= minNumAverages 
                %get the present convergence value
                results(iPower,iFreq).Meter1Conv  =  abs((mean(measArray(1:(averageIndex))) ...
                - mean(measArray(1:(averageIndex-1))))./ ...
                (mean(measArray(1:(averageIndex))))); 
                %quit if we've met the convergence
                %desplay result for the user
                fprintf('Iteration: %d Convergence: %0.3e\n',averageIndex,results(iPower,iFreq).Meter1Conv); 
                %check if break condition is met
                if results(iPower,iFreq).Meter1Conv < meanConvergence
                    %save the results
                    results(iPower,iFreq).Meter1Power  = mean(measArray(1:averageIndex)); 
                    results(iPower,iFreq).Meter1Offset = presentPower - results(iPower,iFreq).Meter1Power; 
                    break
                elseif averageIndex == maxNumAverages
                    warning('Maximum number of averages taken. Convergence threshold not met.')
                end
            end
        end

        %print the results to the terminal
        fprintf('### RESULT ###\n')
        fprintf('Meter Power: %0.3fdBm\n',results(iPower,iFreq).Meter1Power); 
        fprintf('Meter Convergence: %0.2e\n',results(iPower,iFreq).Meter1Conv); 
        fprintf('Meter Offset: %0.3fdBm\n',results(iPower,iFreq).Meter1Offset); 
    end
end

%% Turn RF Source OFF
rfSource.set('State','OFF'); 

%% Notify User For Stage 2

fprintf(['Please connect the output power meter to the RF Source' ...
         ' and press any key to continue...\n']);
pause;


%% Wait for Output Power Meter to Zero
if exist('wtbr','var'); waitbar(0,wtbr,'Setup: Zeroing Power Meter...'); end
pwrmeterOut.zero; 

PM_TIME_STEPS = 0:PM_CAL_STEP_TIME:PM_CAL_WAIT_TIME; 
for step = PM_TIME_STEPS
    %update the waitbar
    if exist('wtbr','var')
        waitbar(step./PM_CAL_WAIT_TIME,wtbr,'Setup: Zeroing Power Meter...'); 
    end
    %wait a moment
    pause(PM_CAL_STEP_TIME); 
end

%% Turn the RF Source ON 
rfSource.set('Power',-40,'Frequency',freq(1),'State','ON');

%% Now Iterate Through Powers and Frequencies

if exist('wtbr','var')
    numSteps    = numel(results); 
    stepIndex   = 0; 
end 

for iPower = 1:length(power)
    %get the current power level
    presentPower = power(iPower); 
    %set the current power level
    rfSource.set('Power',presentPower); 

    for iFreq = 1:length(freq)
        %get the current frequency
        presentFreq = freq(iFreq); 

        %set the current frequency 
        rfSource.set('Frequency',presentFreq); 
        pwrmeterOut.frequency(presentFreq); 

        %array for measurments 
        measArray = zeros(1,maxNumAverages); 
        %creat new header
        fprintf('### Freq = %0.2f Power = %0.2dBm ###\n',presentFreq,presentPower); 
        %update waitbar
        if exist('wtbr','var')
            stepIndex = stepIndex + 1; 
            waitbar(stepIndex./numSteps,wtbr,...
                sprintf('Power: %0.2fdBm, Frequency: %0.2f GHz',presentPower,presentFreq)); 
        end
        %take measurments over and over again until the the convergence
        %criteria is met
        for averageIndex = 1:maxNumAverages
            %take a measurement 
            measArray(averageIndex) = pwrmeterOut.measure(0.001); 
            if averageIndex >= minNumAverages 
                %get the present convergence value
                results(iPower,iFreq).Meter2Conv  =  abs((mean(measArray(1:(averageIndex))) ...
                - mean(measArray(1:(averageIndex-1))))./ ...
                (mean(measArray(1:(averageIndex))))); 
                %quit if we've met the convergence
                %desplay result for the user
                fprintf('Iteration: %d Convergence: %0.3e\n',averageIndex,results(iPower,iFreq).Meter2Conv); 
                %check if break condition is met
                if results(iPower,iFreq).Meter1Conv < meanConvergence
                    %save the results
                    results(iPower,iFreq).Meter2Power  = mean(measArray(1:averageIndex)); 
                    results(iPower,iFreq).Meter2Offset = presentPower - results(iPower,iFreq).Meter2Power; 
                    break
                elseif averageIndex == maxNumAverages
                    warning('Maximum number of averages taken. Convergence threshold not met.')
                end
            end
        end

        %print the results to the terminal 
        fprintf('### RESULT ###\n')
        fprintf('Meter Power: %0.3fdBm\n',results(iPower,iFreq).Meter2Power); 
        fprintf('Meter Convergence: %0.2e\n',results(iPower,iFreq).Meter2Conv); 
        fprintf('Meter Offset: %0.3fdBm\n',results(iPower,iFreq).Meter2Offset); 
    end
end

%% Turn RF Source OFF
rfSource.set('State','OFF'); 
close(wtbr)

%% Plot the Results 
figure 
hold on 
plot([results(1,:).Frequency],[results(1,:).SourcePower],'k'); 
plot([results(1,:).Frequency],[results(1,:).Meter1Power],'kx'); 
plot([results(1,:).Frequency],[results(1,:).Meter2Power],'ko');
xlabel('Frequency (GHz)')
ylabel('Power (dBm)')
title('Power Readings')
legend('Source Set', 'Meter 1 (input)','Meter 2 (Output)');
%% Save Data 
save([datestr(now,'yyyymmddTHHMMSS') '_MeterCalResults.mat'],'results','power','freq');