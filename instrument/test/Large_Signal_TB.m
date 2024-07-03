%% Large Signal Testbench 

%% Clear and Reset Workspace 
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
% clear results

%% Parameters 
%Settings 
% Plot Settings
PLOT_RESULTS            = 1; 

% Sweep
freq                    = linspace(6,14,35);     %GHz
power                   = unique([0:5:20, 20:0.5:22, 22:0.2:25]); 
% Bias
AMPLIFIER_IS_BIASED     = false;                    %tracks the state of the amplifier 
AUTO_BIAS_AMPLIFIER     = true;                     %set to false if you don't want this code to bias off the amplifier
ROBUST_MODE             = false;                    %return sweep power to lower limit, and blacklist frequencies where driver is saturated (don't error out)
ROBUST_MODE_POW_SWITCH  = 20;                       %power level that will trigger robust mode.

%gate structure 
gate.Voff               = 3; 
gate.Max                = 4; 
gate.Min                = 1; 
gate.Ilim               = 10e-3; 
gate.NomStep            = 0.025;
gate.wait               = 0.5; 

%drain structure 
drain.Voff              = 0; 
drain.Von               = 28; 
drain.Max               = 30; 
drain.Min               = 0; 
drain.Ilim              = 180e-3; 
% drain.Ilim              = 40e-3; 
drain.NomStep           = 0.5; 
drain.wait              = 0.5; 

%Iq structure 
% IqTarget.Value          = 34.5e-3; 
IqTarget.Value          = 35e-3; 
IqTarget.Tol            = 0.1e-3; 


% gateVotlageOff          = -4;                       %V
% drainVoltageOn          = 28;                       %V
% drainVoltageOff         = 0;                        %V
% quiescentCurrent        = 34e-3;                    %A
% quiescentCurrentTol     = 5e-3;                     %A
% drainCurrentLim         = 80e-3;                    %A
% gateCurrentLim          = 10e-3;                    %A
% gateStepV               = 0.1;                      %Maximum voltage step of the gate
% drainStepV              = 0.25;                     %Maximum voltage step of the drain

%Power meter settins 
PM_CAL_STEP_TIME = 0.5; 
PM_CAL_WAIT_TIME = 20; 

%power step settings  
powStepInit             = 1;                      %dBm
powInitOffset           = -45;                    %dBm
powInitSweep            = -5;                     %dBm
powTolerance            = 0.05;                   %dBm
powSettleTime           = 0.5;                    %time between loops 
maxRfSourcePower        = 10;                     %power limit where driver will be damaged
TURN_SRC_PWR_OFF_BETWEEN_FREQS = false; 
%Instrument Addresses 
% Power Meters 
POWER_METER_ADR         = 'GPIB1::13::INSTR';
RF_INPUT_POWER_ADR      = 'USB0::0x2A8D::0xA618::MY57390007::0::INSTR'; 
RF_OUTPUT_POWER_ADR     = 'USB0::0x2A8D::0xA618::MY57390010::0::INSTR'; 
% Multimeter 
MULTIMETER_ADR          = 'GPIB1::19::INSTR'; 
DRAIN_MULTIMETER_ADR    = 'GPIB1::22::INSTR'; 
% PSU
MMIC_PSU_ADR            = 'GPIB1::5::INSTR'; 
EQUIP_PSU_ADR           = 'GPIB1::4::INSTR'; 
% RF SWEEPER
RF_SOURCE_ADR           = 'GPIB1::20::INSTR'; 

%Coupler S-Parameter Files 
%probes
probes = sparameters(['C:\Users\W-band\Documents\Paul' ...
                        '\ScalarPowerCal_Char\Thru\probes_thru.s2p']);

%build probe loss interpolation function
probeLossInterp = @(f) interp1(probes.Frequencies, ...
                           20.*log10(abs(rfparam(probes,2,1)))./2, f);

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

%% Build Pavs Conversion Function
% allow user to open input scalar calibrated offsets
[fn,pn] = uigetfile({'*.mat', 'Matlab data file'},...
                        'Select Input Offset Calibration File'); 
if not(isequal(pn,0))
    %get the calibration data
    calData     = load(fullfile(pn,fn)); 
    calResults  = calData.inputCalResults; 
    %now build the offset function 
    inOffsetFunction = @(f) interp1([calResults.freq], ...
                              [calResults.offset],f) + probeLossInterp(f); 

else
    inputOffset = 20.*log10(abs(rfparam(probes,2,1)))/2 + ...
                  20.*log10(abs(rfparam(inputThru,2,1))) - ...
                  20.*log10(abs(rfparam(inputCpl,2,1))); 
    inOffsetFunction = @(f) interp1(probes.Frequencies,inputOffset,f,...
                                    "linear","extrap");
end
%setup function for extracting Pavs
convertToPavs = @(pinRaw,freq) pinRaw + inOffsetFunction(freq);

%% Build Pdel Conversion Function
% allow user to open output scalar calibrated offsets
[fn,pn] = uigetfile({'*.mat', 'Matlab data file'},...
                        'Select Output Offset Calibration File'); 
if not(isequal(pn,0))
    %get the calibration data
    calData     = load(fullfile(pn,fn)); 
    calResults  = calData.outputCalResults; 
    %now build the offset function 
    outOffsetFunction = @(f) interp1([calResults.freq], ...
                              [calResults.offset],f) - probeLossInterp(f); 

else
    outputOffset = -20.*log10(abs(rfparam(probes,2,1)))./2 -...
                    20.*log10(abs(rfparam(outputCpl,2,1))); 
    outOffsetFunction = @(f) interp1(probes.Frequencies,outputOffset,f,...
                                    "linear","extrap");
end
%setup function for extracting Pdel
convertToPdel = @(poutRaw,freq) poutRaw + outOffsetFunction(freq);  

%% Other Functions 
%create dbm2w function 
dbm2w = @(dBmIn) 10.^((dBmIn-30)./10); 

%% Create the Waitbar

wtbr = waitbar(0,sprintf('Initializing Bench...')); 

%% Initialize the Results Array 
%build the results structure
results.Id      = []; 
results.Vd      = [];
results.Pin     = [];
results.Pout    = [];
results.Pavs    = [];
results.Pdel    = [];
results.Psource = [];
results.fset    = [];
results.pset    = [];

%if a multimeter is sensing the drain voltage estimate the dc contact
%resistance 
if exist('drainVMeter','var')
    results.VdPSU = []; %drain voltage at the PSU
    results.drainContactResEst = [];
end

%build array of structures 
results = repmat(results,length(power),length(freq)); 

%% Setup Instruments
%turn of warnings temporarily 
warning('off','all')
%notify user of instrument connection
fprintf('Initializing Instruments...')
rfSource    = instruments.SigGen.k83650A('Address',RF_SOURCE_ADR); 

% pwrmeterIn  = instruments.PowerMeter.U8487A('Address',RF_INPUT_POWER_ADR); 
% pwrmeterOut = instruments.PowerMeter.U8487A('Address',RF_OUTPUT_POWER_ADR); 
powerMeter  =   instruments.PowerMeter.N1914A('Address',POWER_METER_ADR, ...
                                              'Channel1Name','pwrmeterIn',...
                                              'Channel3Name','pwrmeterOut'); 

supplyMMIC  = instruments.PSU.E3649A('Address',MMIC_PSU_ADR,...
                                     'Output1Name','drain',...
                                     'Output2Name','gate', ...
                                     'Channel1Name','drain',...
                                     'Channel2Name','gate'); 
% supplyEQUIP = instruments.PSU.E3649A('Address',EQUIP_PSU_ADR); 

multimeter  = instruments.Multimeter.k34410A('Address',MULTIMETER_ADR); 

%if drain multimeter is specified
if exist('DRAIN_MULTIMETER_ADR','var') && not(isempty(DRAIN_MULTIMETER_ADR))
    drainVMeter = instruments.Multimeter.k34410A('Address',DRAIN_MULTIMETER_ADR); 
end


fprintf('Done.\n')
%now turn warnings back on 
warning('on','all')

%pull out the power meter channel abstractions
pwrmeterIn  = powerMeter.pwrmeterIn; 
pwrmeterOut = powerMeter.pwrmeterOut; 

%% Setup Power Meters
% pwrmeterOut.offsetFreqs = offsetFreqs; 
% pwrmeterOut.offsetVals  = outMeterOffset; 
% pwrmeterOut.useOffset   = true; 

if exist('wtbr','var'); waitbar(0,wtbr,'Setup: Zeroing Power Meters...'); end
pwrmeterIn.zero; 
pwrmeterOut.zero; 

PM_TIME_STEPS = 0:PM_CAL_STEP_TIME:PM_CAL_WAIT_TIME; 
for step = PM_TIME_STEPS
    %update the waitbar
    if exist('wtbr','var')
        waitbar(step./PM_CAL_WAIT_TIME,wtbr,'Setup: Zeroing Power Meters...'); 
    end
    %wait a moment
    pause(PM_CAL_STEP_TIME); 
end


%% Bias Up Amplifier 
%update waitbar 
if exist('wtbr','var'); waitbar(0,wtbr,'Setup: Biasing Amplifier'); end
%bias on amplifier
if not(AMPLIFIER_IS_BIASED) && AUTO_BIAS_AMPLIFIER
    BiasOn(supplyMMIC,gate,drain,IqTarget,true); 
    AMPLIFIER_IS_BIASED = true; 
end

%% Measure the Contact Resistance 


%if the drain voltage multimeter is set, use it to estimate the drain
%contact resistance (using the running drain voltage has proven unreliable)
if exist('drainVMeter','var')
    %now report that
    if exist('wtbr','var'); waitbar(0,wtbr,'Finding Contact Resistance...'); end
    %get the drain quiescent current 
    iqContactResistance = multimeter.get('Current'); 
    vdDrainContactResistance = drainVMeter.get('Voltage'); 
    vdSetContactResistance = supplyMMIC.get('drain','Voltage'); 
    %now estimate the contact resistance of the drain probe 
    quiescentContactRes = (vdSetContactResistance-vdDrainContactResistance)/iqContactResistance; 
    %report finding to the user 
    fprintf('Contact resistance found: %0.3f Ohms\n',quiescentContactRes); 
end

%% Run Sweeps 
%initialize the RF Source 
rfSource.set('Power',-40,'Frequency',freq(1),'State','OFF'); 

%wait for system to settle before moving into testing 
if exist('wtbr','var')
    waitbar(0,wtbr,'Finding Contact Resistance...'); 
    pause(10); 
else
    fprintf('Waiting for the system to settle...'); 
    pause(10); 
    fprintf('Done.\n')
end

% setup the progress bar 
numSteps = numel(results); 
sweepNumber = 0; 
if exist('wtbr','var'); waitbar(0,wtbr,sprintf('Beginning Sweep...')); end 

%create frequency blacklist for robus mode (exists in normal mode as well)
freqBlackList = []; 

try
    %begin sweep to take measurements 
    for iPower = 1:length(power)
        %get current target power
        powTarget = power(iPower); 
        
        %check if it's time to move into robust mode 
        if powTarget>= ROBUST_MODE_POW_SWITCH
            ROBUST_MODE = true; 
        end
        
        %set initial source power for the next frequency sweep
        sourcePower = powTarget + powInitOffset; 
        PavsLB      = powTarget - powTolerance; 
        PavsUB      = powTarget + powTolerance; 

        %if all frequencies are blacklisted throw an error because it isn't
        %possible to continue 
        assert(not(length(freqBlackList) == length(freq)),...
            ['Could not continue. Driver amplifier is compressed at ' ...
            'all frequencies.']) 


        for iFreq = 1:length(freq)
            freqTarget = freq(iFreq); 
            if any(freqTarget == freqBlackList) %if the current value is on the black list ignore it and move on
                warning('Skipping frequency %0.3f. Driver compressed.',freqTarget); 
                continue; 
            end
            %set the signal generator power and frequency 
            % sourcePower = powTarget - LinearGainEstimate(iFreq) + powInitSweep; 
%             if not(iFreq==1)
%                 sourcePower = sourcePower + powInitSweep; 
%             end
            if not(iFreq==1) && not(ROBUST_MODE)
                sourcePower = sourcePower + powInitSweep; 
            elseif ROBUST_MODE %start the well below the target (slows things down but avoids trouble)
                sourcePower = powTarget + powInitOffset; 
            end

            %re-initialize the state variables
            Pstep           = powStepInit; %reset the power step size
            prevBelowTarget = true; 
            
            %update the sweep counter 
            sweepNumber = sweepNumber + 1; 
            progress = sweepNumber/numSteps;
            waitbar(progress,...
                    wtbr,...
                    sprintf(['Power: %0.3fdBm, ' ...
                    'Freq: %0.3f GHz'],powTarget,freqTarget)); 
    
            %now try to find a suitable source power 
            while true
                %if the program attempts to set a power greatter than the
                %damage threshold of the equipment turn the rf-generator off
                %and throw an error 
                if (sourcePower > maxRfSourcePower)
                    if ROBUST_MODE %if in robust mode blacklist the frequency and reset power level
                        freqBlackList = [freqBlackList freqTarget];         %add present frequency to the blacklist
                        rfSource.set('State','OFF');                        %turn the source off
                        warning(['Frequency %0.3f blacklisted. ' ...        %let the user know there is an issue
                            'Attempted to set power to: %0.3f dBm'], ...
                            freqTarget,sourcePower);                
                        sourcePower = powTarget + powInitOffset;            %reset the source power to the initial value
                        break; 
                    else %throw an error  
                        rfSource.set('State','OFF'); 
                        error(['Attempted power level will damage driver ' ...
                               'amplifier. Cancelling test.']); 
                    end
                else %if the next power won't damage the driver continue with setting it
                    %set the RF source power 
                    rfSource.set('Power',sourcePower,...
                                 'Frequency',freqTarget,...
                                 'State','ON'); 
                end

                %allow system to settle between setting the power and measuring
                pause(powSettleTime);
                %read the input power
    %             Pavs = convertToPavs(pwrmeterIn.measure(0.1),freqTarget.*1e9);
                Pavs = convertToPavs(pwrmeterIn.measure('Resolution',0.1),freqTarget.*1e9);
                %turn the source power off if requested
                if TURN_SRC_PWR_OFF_BETWEEN_FREQS
                    rfSource.set('State','OFF'); 
                end
                %now determine if the input power foun
                if Pavs>=PavsLB && Pavs<=PavsUB
                    break;
                elseif  Pavs>PavsUB
                    %handle the case where we passed the bounds of our goal 
                    if prevBelowTarget 
                        Pstep = Pstep/2; 
                    end
                    %now set the new power level 
                    sourcePower = sourcePower-Pstep; 
                    prevBelowTarget = false; 
                else 
                    %handle the case where we were previously above the bounds 
                    if not(prevBelowTarget)
                        Pstep = Pstep/2; 
                    end
                    %now set the new power level 
                    sourcePower = sourcePower+Pstep;
                    prevBelowTarget = true; 
                end
            end
            
            if not(any(freqTarget==freqBlackList)) %only save data for valid points
                %Update the waitbar
                if exist('wtbr','var')
                    waitbar(progress,...
                            wtbr,...
                            sprintf(['Pavs = %0.3fdBm ' ...
                            'Taking Final Measurement...'],Pavs)); 
                end
                
                %take a measurement 
                %turn the RF source on if it was turned off
                if TURN_SRC_PWR_OFF_BETWEEN_FREQS
                    rfSource.set('State','ON');
                end
                %get the output power 
                results(iPower,iFreq).Pin       = pwrmeterIn.measure('Resolution',0.001);
                results(iPower,iFreq).Pavs      = convertToPavs(results(iPower,iFreq).Pin,freqTarget*1e9); 
                results(iPower,iFreq).Pout      = pwrmeterOut.measure('Resolution',0.001);
                results(iPower,iFreq).Pdel      = convertToPdel(results(iPower,iFreq).Pout,freqTarget*1e9);
                results(iPower,iFreq).Id        = multimeter.get('Current'); 
                results(iPower,iFreq).fset      = freq(iFreq);
                results(iPower,iFreq).pset      = power(iPower); 
                if exist("drainVMeter",'var')
                    results(iPower,iFreq).VdPSU = supplyMMIC.get('drain','Voltage'); %drain voltage of the power supply
                    results(iPower,iFreq).Vd    = drainVMeter.get('Voltage');        %drain voltage measured by the multimeter
                    results(iPower,iFreq).drainContactResEst = ...                   %estimated contact resistance
                        (results(iPower,iFreq).VdPSU - ...
                        results(iPower,iFreq).Vd)/results(iPower,iFreq).Id; 
                else
                    results(iPower,iFreq).Vd    = supplyMMIC.get('drain','Voltage'); 
                end
                results(iPower,iFreq).Psource   = sourcePower; 
                %turn the RF source off again
                rfSource.set('State','OFF'); 
                
                
                % Print the Results 
                fprintf('### Captured Results (Frequency: %0.3f Power: %0.3f) ###\n',freq(iFreq),power(iPower)); 
                fprintf('Pin: %0.3f\n',  results(iPower,iFreq).Pin)
                fprintf('Pavs: %0.3f\n', results(iPower,iFreq).Pavs);
                fprintf('Pout: %0.3f\n', results(iPower,iFreq).Pout); 
                fprintf('Pdel: %0.3f\n', results(iPower,iFreq).Pdel);
                fprintf('Drain Current: %0.3f\n', results(iPower,iFreq).Id);
                fprintf('Drain Voltage: %0.3f\n', results(iPower,iFreq).Vd);
                if exist("drainVMeter",'var')
                    fprintf('Drain Contact Resistance: %0.3f Ohms\n',results(iPower,iFreq).drainContactResEst); 
                end
                fprintf('Final Source Power: %0.3f\n',results(iPower,iFreq).Psource);
            end
        end
        
        %plot results to the figure number provided
        if PLOT_RESULTS
            if not(exist('legendData','var'))
                legendData = {sprintf('Pavs = %0.1dBm',powTarget)}; 
            else
                legendData = [legendData {sprintf('Pavs = %0.1dBm',powTarget)}];
            end
            %set figure number 
            figure(PLOT_RESULTS); 
            %plot the output power 
            subplot(221)
            hold on 
            plot(freq(not([results(iPower,:).Pdel]==0)),...
                [results(iPower,:).Pdel]); 
            title('Power Delivered');
            ylabel('Pdel (dBm)');
            legend(legendData{:});
            
            %plot available source power
            subplot(222)
            hold on 
            plot(freq(not([results(iPower,:).Pavs]==0)),...
                [results(iPower,:).Pavs]); 
            title('Available Source Power');
            ylabel('Pavs (dBm)');
    
            %plot the transducer gain
            subplot(223)
            hold on 
            plot(freq(not([results(iPower,:).Pdel]==0)),...
                [results(iPower,:).Pdel] - [results(iPower,:).Pavs]); 
            title('Transducer Gain')
            ylabel('Gain (dBm)')
            
            %plot the PAE
            subplot(224)
            hold on 
            plot(freq(not([results(iPower,:).Pdel]==0)),...
                100.*(dbm2w([results(iPower,:).Pdel]) - ...
                dbm2w([results(iPower,:).Pavs])) ...
                ./([results(iPower,:).Vd].*[results(iPower,:).Id])); 
            title('PAE')
            ylabel('PAE (%)')
        end
        
    end
catch ME %if an error is encountered in this loop
    %save the data
    if exist('quiescentContactRes','var')
        save([datestr(now,'yyyymmddTHHMMSS') '_Emergency_Save_results.mat'],'results','power','freq','quiescentContactRes');
    else 
        save([datestr(now,'yyyymmddTHHMMSS') '_Emergency_Save_results.mat'],'results','power','freq');
    end
    %make sure the RF source is off
    rfSource.set('State','OFF'); 
    %attempt to shutdown the power amplifier (if on)
    if AMPLIFIER_IS_BIASED && AUTO_BIAS_AMPLIFIER
        fprintf('Attempting to bias off amplifier...')
        BiasOff(supplyMMIC,gate,drain,true); 
        AMPLIFIER_IS_BIASED = false; 
        fprintf('Done\n')
    end
    %close the waitbar if open
    if exist('wtbr','var')
        close(wtbr)
    end
    %plot the available source power levels 
    figure 
    hold on 
    labels = {}; 
    for iPower = 1:iPower
        %plot the chosen source power level 
        plot(freq(not([results(iPower,:).Psource]==0)),...
            [results(iPower,:).Psource]); 
        labels = [labels {sprintf('%0.3f dBm',power(iPower))}]; 
    end
    xlabel('Frequency (GHz)'); 
    ylabel('Source Power Set Point (dBm)'); 
    title('Set Power vs Frequency'); 
    legend(labels{:}); 
    %rethrow the error
    rethrow(ME)
end

%close the waitbar 
try 
    %notify the user that measurements are complete
    waitbar(1,...
        wtbr,...
        'Measurement complete. Next the DUT will be turned off.');
    pause(5); 
    %close the figure 
    close(wtbr); 
catch
    warning('Handle to waitbar is invalid.')
end

%% Bias Off Amplifier 
if AMPLIFIER_IS_BIASED && AUTO_BIAS_AMPLIFIER
    fprintf('Attempting to bias off amplifier...')
    BiasOff(supplyMMIC,gate,drain,true); 
    AMPLIFIER_IS_BIASED = false; 
    fprintf('Done\n')
end
%% Save Data 
if exist('quiescentContactRes','var')
    save([datestr(now,'yyyymmddTHHMMSS') '_results.mat'],'results','power','freq','quiescentContactRes');
else 
    save([datestr(now,'yyyymmddTHHMMSS') '_results.mat'],'results','power','freq');
end