%% LARGE SIGNAL TEST BENCH (V1)
%   AUTHOR: Paul Flaten
%   DATE:   13DEC2023
%
%   INTRODUCTION: 
%       PURPOSE: 
%        The purpose of this bench is to provide a uniform means of
%       performing automated scalar large-signal testing of amplifiers with
%       an arbitrary number of stages. It will autobias the amplifier based
%       on the desired bias parameters provided, and will begin sweeping
%       through a list of available source powers and frequencies. In this
%       version of the program, the inner loop is frequency and the outer
%       loop is power. 
%       OPERATING CONCEPT:
%        This program pulls in the configuration of the DUT, equipment, and
%       general parameters (sweep parameters) from the user-provided
%       directory and saves all results to that same directory with a
%       timestamp that follows the format YYYYMMDDTHHMMSS (where YYYY=year,
%       MM=month, DD=day, HH=hour, MM=minute, SS = second). This operating
%       concept garuntees that the results saved in the working directory
%       were obtained with the parameters specified in that directory AS
%       LONG AS the user does not change the configuration for multiple
%       different tests. Therefore, to get the most out of this program it
%       is advisable that the user follow the rule: ONE CONFIGURATION, 
%       ONE DIRECTORY.
%       RESULTS:
%        The final results of a test will be saved in a time-stamped file
%       either upon test completion or if an error is encountered during
%       the power and frequency sweeps. The results will contain the
%       following data: freq (a list of frequencies-in GHz-that were
%       swept over), power (a list of powers that were swept over),
%       quiescentContactRes (the estimated resistance between the PSU and
%       drain of the device), and results (NxM array of results structures
%       where N is the number of Pavs swept over and M is the number of
%       frequencies swept over). "results" will have the follwing fields
%       per entry: 
%        pset - the available source power setpoint for this data point
%        fset - the frequency setpoint for this data point
%        Pin  - the input power (dBm) measured by the input power meter
%        Pout - the output power (dBm) measured by the output power meter
%        Pavs - the measured available source power (dBm) measured at the DUT
%        Pdel - the measured delivered power (dBm) at the DUT 
%        Psource - the power set at the sweeper (RF source) in dBm   
%        VgN  - the gate voltage (V) measured by the PSU for the Nth stage
%        IgN  - the gate current (A) measured by the PSU for the Nth stage
%        VdN  - the drain voltage (V) measured by the PSU for the Nth stage
%        IdN  - the drain current (A) measured by the PSU for the Nth stage
%        DrainVmeterN - the drain voltage (V) of the Nth stage measured by 
%                       the drain voltage multimeter (if available) 
%        DrainImeterN - the drain current (A) of the Nth stage measured by 
%                       the drain current multimeter (if available) 
%        GateVmeterN  - the gate voltage (V) of the Nth stage measured by
%                       the gate voltage multimeter (if available) 
%        GateImeterN  - the gate current (A) of the Nth stage measured by
%                       the gate current multimeter (if available)
%       INSTRUMENT LIBRARY: 
%        This program makes use of a general instrument library that is
%       source-controlled (https://github.com/pflaten321/instrument).
%       While modifying this library isn't prohibited, it is strongly
%       recommended that the user only make changes when absolutely
%       necissary so that this program can maintain compability with future
%       library releases.
%   GENERAL INSTRUCTIONS: 
%   STEP 0) CHECK STABILITY 
%       While the prgram will abort the test if it detects current limiting
%       during the bias on and off procedures, it is always advisable that
%       the user manually check for stability before testing.
%   STEP 1) CREATE TEST DIRECTORY 
%       If the configuration of the bench, the dut, or the test parameters
%       are new, it is highly recommended that the user create a new
%       directory for that test.
%   STEP 2) COPY/UPDATE CONFIGURATION FILES IN TEST DIRECTORY 
%       In the new directory, the user should copy the three configuration
%       files GENERAL_CONFIGURATION, EQUIPMENT_CONFIGURATION,
%       DUT_CONFIGURATION, and modify them as necissary to fullfil the test
%       parameters. Once each file has been modified and checked, they
%       should be closed in the editor (MATLAB will allow multiple files
%       with the same name to be open from multiple different
%       directories--possibly causing errors when running a test).
%   STEP 3) RUN MAIN 
%       Once done with the configuration files, the user should type "main"
%       into the command window to initiate the program. The program will
%       prompt the user to find the desired working directory and will load
%       in the configuration set by the user. 


%% Clear and Reset Workspace 

%if a waitbar is open, close it 
if exist('wtbr','var') && isvalid(wtbr)
    close(wtbr); 
end

%now reset workspace
close all
clear all
clc

%% Constant Parameters (DO NOT MODIFY UNLESS YOU KNOW WHAT YOU'RE DOING)
%Power meter zero settings
PM_CAL_STEP_TIME = 0.5; 
PM_CAL_WAIT_TIME = 20;

%directory that this bench is stored in 
HOME = 'C:\Users\W-band\Documents\LargeSignalBench';
%directory to open user to for locating workspace
ROOT = userpath; 

%add path to instruments repository 
addpath(fullfile(HOME,'instrument')); 

%% Step 0: Setup Auxiliary Functions & Create Waitbar 
%create the waitbar
wtbr = waitbar(0,sprintf('Initializing Bench...')); 
%create dbm2w function 
dbm2w = @(dBmIn) 10.^((dBmIn-30)./10); 

%% Step 1: Set Working Directory 

%get the working directory from the user 
WORKING_DIR = uigetdir(ROOT,'Select working directory for this run.');

%cancel the test if the user does not specify a working directory
assert(not(isequal(WORKING_DIR,0)),'Test aborted. No directory specified.');

%% Step 2: Import General User Configuration Files 
%update user 
if exist('wtbr','var') && isvalid(wtbr) 
    wtbr = waitbar(0,wtbr,sprintf('Loading equipment configuration...')); 
end
fprintf('Loading general configuration...')
%check if equipment addresses are located in working directory 
if exist(fullfile(WORKING_DIR,"GENERAL_CONFIGURATION.m"),"file")
    %run the file if it exists 
    run(fullfile(WORKING_DIR,"GENERAL_CONFIGURATION.m")); 
    %report to user 
    fprintf('Done. Found in working directory.\n')
elseif exist(fullfile(pwd,"GENERAL_CONFIGURATION.m"),"file")
    %run the file located in the current directory 
    run(fullfile(pwd),"GENERAL_CONFIGURATION.m"); 
    %report to user 
    fprintf('Done. Found in present directory.\n')
else
    [fn,pn] = uigetfile(...
        {'*.m','Configuration file'}, ...
        'Pick General Configuration File'); 
    %if user configuration file is provided--run it
    assert(not(isequal(fn,0)),'No general configuration file probided. ');
    %if assertion passes run the configuration file 
    run(fullfile(pn,fn)); 
    %report to user 
    fprintf('Done. Provided by user.\n')
end


%% Step 3: Initialize Equipment 
%update user 
if exist('wtbr','var') && isvalid(wtbr) 
    wtbr = waitbar(0,wtbr,sprintf('Loading equipment configuration...')); 
end
fprintf('Loading equipment configuration...')
%check if equipment addresses are located in working directory 
if exist(fullfile(WORKING_DIR,"EQUIPMENT_CONFIGURATION.m"),"file")
    %run the file if it exists 
    run(fullfile(WORKING_DIR,"EQUIPMENT_CONFIGURATION.m")); 
    %report to user 
    fprintf('Done. Found in working directory.\n')
elseif exist(fullfile(pwd,"EQUIPMENT_CONFIGURATION.m"),"file")
    %run the file located in the current directory 
    run(fullfile(pwd),"EQUIPMENT_CONFIGURATION.m"); 
    %report to user 
    fprintf('Done. Found in present directory.\n')
else
    [fn,pn] = uigetfile(...
        {'*.m','Configuration file'}, ...
        'Pick Equipment Configuration File'); 

    %check if the file or pathname is empty 
    assert(not(isequal(fn,0)),"No equipment configuration file " + ...
        "provided. Aborting test."); 
    %if assetion passes, run the file 
    run(fullfile(pn,fn)); 
    %report to user 
    fprintf('Done. Provided by user.\n')
end

%% Step 4: Get DUT Configuration - This is where the bias configuration is set 
%update user 
if exist('wtbr','var') && isvalid(wtbr) 
    wtbr = waitbar(0,wtbr,sprintf('Loading DUT configuration...')); 
end
fprintf('Loading DUT configuration...')
%find the configuration file
if exist(fullfile(WORKING_DIR,"DUT_CONFIGURATION.m"),"file")
    %run the file if it exists 
    run(fullfile(WORKING_DIR,"DUT_CONFIGURATION.m")); 
    %report to user 
    fprintf('Done. Found in working directory.\n')
elseif exist(fullfile(pwd,"DUT_CONFIGURATION.m"),"file")
    %run the file located in the current directory 
    run(fullfile(pwd),"DUT_CONFIGURATION.m"); 
    %report to user 
    fprintf('Done. Found in present directory.\n')
else
    [fn,pn] = uigetfile(...
        {'*.m','Configuration file'}, ...
        'Pick Equipment Configuration File'); 

    %check if the file or pathname is empty 
    assert(not(isequal(fn,0)),"No DUT configuration file " + ...
        "provided. Aborting test.")
    
    %if assetion passes, run the file 
    run(fullfile(pn,fn)); 
    %report to user 
    fprintf('Done. Provided by user.\n')
end

%% Step 5: Import Cal Data
%update user 
if exist('wtbr','var') && isvalid(wtbr) 
    wtbr = waitbar(0,wtbr,sprintf('Importing Calibration...')); 
end
fprintf('Importing Probe Calibration...')
%For the probes...
if not(exist("PROBE_FP","var")) || not(exist(PROBE_FP,"file"))
    %get the file from the user 
    [fn,pn] = uigetfile({'*.s2p','S-Parameter File'}, ...
        'Please select probe S-Parameters'); 
    %try to open the file 
    PROBE_FP = fullfile(pn,fn); 
end

%attempt to open the s-parameter files 
probes = sparameters(PROBE_FP); 
%build the interpolation function 
probeLossInterp = @(f) interp1(probes.Frequencies, ...
                           20.*log10(abs(rfparam(probes,2,1)))./2, f);
fprintf('Done.\n'); 


fprintf('Importing Input Offset...'); 
%For the input offset...
if not(exist("INPUT_OFFSET_FP","var")) || not(exist(INPUT_OFFSET_FP,"file"))
    %get the file from the user 
    [fn,pn] = uigetfile({'*.mat','MAT-file'}, ...
        'Please select input offset file.'); 
    %try to open the file 
    OUTPUT_OFFSET_FP = fullfile(pn,fn); 
end
%attempt to load the calibration data from provided path
calData     = load(OUTPUT_OFFSET_FP); 
%grab the calibration results
calResults  = calData.outputCalResults; 
%now build the offset function 
inOffsetFunction = @(f) interp1([calResults.freq], ...
                          [calResults.offset],f) + probeLossInterp(f); 
%setup function for extracting Pavs
convertToPavs = @(pinRaw,freq) pinRaw + inOffsetFunction(freq);
fprintf('Done.\n')


fprintf('Importing Output Offset...')
%For the output offset...
if not(exist("OUTPUT_OFFSET_FP","var")) || not(exist(OUTPUT_OFFSET_FP,"file"))
    %get the file from the user 
    [fn,pn] = uigetfile({'*.mat','MAT-file'}, ...
        'Please select output offset file.'); 
    %try to open the file 
    OUTPUT_OFFSET_FP = fullfile(pn,fn); 
end
%attempt to load the calibration data from provided path
calData     = load(OUTPUT_OFFSET_FP); 
%grab the calibration results
calResults  = calData.outputCalResults; 
%now build the offset function 
outOffsetFunction = @(f) interp1([calResults.freq], ...
                          [calResults.offset],f) - probeLossInterp(f); 
%setup function for extracting Pdel
convertToPdel = @(poutRaw,freq) poutRaw + outOffsetFunction(freq);  
fprintf('Done.\n')


%% Step 6: Initialize the Power Meters 

%make sure the rf source is off 
rfSource.set('Power',-60,'Frequency',freq(1),'State','OFF'); 

%update the user
if exist('wtbr','var') && isvalid(wtbr) 
    waitbar(0,wtbr,'Setup: Zeroing Power Meters'); 
end

%zero each power meter
pwrmeterIn.zero; 
pwrmeterOut.zero; 

PM_TIME_STEPS = 0:PM_CAL_STEP_TIME:PM_CAL_WAIT_TIME; 
for step = PM_TIME_STEPS
    %update the waitbar
    if exist('wtbr','var') && isvalid(wtbr) 
        waitbar(step./PM_CAL_WAIT_TIME,wtbr,'Setup: Zeroing Power Meters...'); 
    end
    %wait a moment
    pause(PM_CAL_STEP_TIME); 
end

%% Step 7: Now Bias On the Devices 

if AUTO_BIAS_AMPLIFIER
    %hold everything in a try loop - Shut it all down in the event current
    %limiting is encountered.
    try
        numSteps = length(stages); 
        for stageIndex = 1:numSteps
            %notify the user 
            if exist('wtbr','var') && isvalid(wtbr) 
                wtbr = waitbar(stageIndex./numSteps, ...
                    wtbr, ...
                    sprintf('Biasing: %s',stages(stageIndex).name)); 
            end
            %now bias on the stage 
            stages(stageIndex) = biasOn(stages(stageIndex),AUTO_BIAS_WTBR); 
        end
    catch ME
        %shutdown in reverse order
        emergencyShutdown(fliplr(stages)); 
        %rethrow the error 
        rethrow(ME); 
    end
end

%% Step 8: Build Results 
%save the power and frequency at this point
results.pset        = []; %target Pavs
results.fset        = []; %target requency 
%save the input power (both with and without offset)
results.Pin         = []; %raw value
results.Pout        = []; %raw value
results.Pavs        = []; %offset value
results.Pdel        = []; %offset value
results.Psource     = []; %power rf generator was set to

%build result data per stage 
for index = 1:length(stages)
    %% For the Gate of the Present Stage
    %direct PSU measurements
    results.(sprintf('Vg%d',index)) = []; 
    results.(sprintf('Ig%d',index)) = []; 
    %if multimeter is available for the gate 
    if not(isempty(stages(index).gate.Vmeter))
        results.(sprintf('GateVmeter%d',index)) = []; 
    end
    if not(isempty(stages(index).gate.Imeter))
        results.(sprintf('GateImeter%d',index)) = []; 
    end
    %% For the Drain of the Present Stage
    %direct PSU measurements
    results.(sprintf('Vd%d',index)) = []; 
    results.(sprintf('Id%d',index)) = []; 
    %if multimeter is available for the gate 
    if not(isempty(stages(index).drain.Vmeter))
        results.(sprintf('DrainVmeter%d',index)) = []; 
    end
    if not(isempty(stages(index).drain.Imeter))
        results.(sprintf('DrainImeter%d',index)) = []; 
    end
end

%build array of structures 
results = repmat(results,length(power),length(freq)); 


%% Step 9: Run the Loop 

%create an array of zeros 
quiescentContactRes = zeros(1,length(stages)); 
%loop through each stage and evaluate if the contact resistance can be
%found
for index = 1:length(stages)
    if not(isempty(stages(index).drain.Vmeter))
        if not(isempty(stages(index).drain.Imeter))
            quiescentContactRes(index) = (stages(index).drain.PSU.get('Voltage') - ...
                                         stages(index).drain.Vmeter.get('Voltage'))/...
                                         stages(index).drain.Imeter.get('Current'); 
        else
            quiescentContactRes(index) = (stages(index).drain.PSU.get('Voltage') - ...
                                         stages(index).drain.Vmeter.get('Voltage'))/...
                                         stages(index).drain.PSU.get('Current'); 
        end
    end
end


% wait for system to settle 
if exist('wtbr','var') && isvalid(wtbr) 
    waitbar(0,wtbr,sprintf('Waiting for system to settle...')); 
end
%wait for 10 seconds
pause(10); 
%notify user that wait time is complete
if exist('wtbr','var') && isvalid(wtbr) 
    waitbar(0,wtbr,sprintf('Done.')); 
end


% setup the progress bar 
numSteps = numel(results); 
sweepNumber = 0; 
if exist('wtbr','var') && isvalid(wtbr) 
    waitbar(0,wtbr,sprintf('Beginning Sweep...')); 
end 

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
            %update progress in the waitbar
            if exist('wtbr','var') && isvalid(wtbr) 
                waitbar(progress,...
                        wtbr,...
                        sprintf(['Power: %0.3fdBm, ' ...
                        'Freq: %0.3f GHz'],powTarget,freqTarget)); 
            end
    
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
                %check if current limits are being exceeded 
                if exist('ASSERT_CURRENT_LIMITS','var') && ASSERT_CURRENT_LIMITS
                    assertCurrentLimits(stages); 
                end

                %allow system to settle between setting the power and measuring
                pause(powSettleTime);
                %read the input power
                Pavs = convertToPavs(pwrmeterIn.measure('Resolution',0.1),freqTarget.*1e9);
                %turn the source power off if requested
                if TURN_SRC_PWR_OFF_BETWEEN_FREQS
                    rfSource.set('State','OFF'); 
                end
                %now determine if the input power found
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
                if exist('wtbr','var') && isvalid(wtbr) 
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
                results(iPower,iFreq).fset      = freq(iFreq);
                results(iPower,iFreq).pset      = power(iPower); 
                results(iPower,iFreq).Pin       = pwrmeterIn.measure('Resolution',0.001);
                results(iPower,iFreq).Pavs      = convertToPavs(results(iPower,iFreq).Pin,freqTarget*1e9); 
                results(iPower,iFreq).Pout      = pwrmeterOut.measure('Resolution',0.001);
                results(iPower,iFreq).Pdel      = convertToPdel(results(iPower,iFreq).Pout,freqTarget*1e9);
                results(iPower,iFreq).Psource   = sourcePower; 

                for index = 1:length(stages)
                    %get gate and drain PSU voltage
                    results(iPower,iFreq).(sprintf('Vd%d',index)) = stages(index).drain.PSU.get('Voltage'); 
                    results(iPower,iFreq).(sprintf('Vg%d',index)) = stages(index).gate.PSU.get('Voltage'); 
                    %get gate and drain PSU current 
                    results(iPower,iFreq).(sprintf('Id%d',index)) = stages(index).drain.PSU.get('Current'); 
                    results(iPower,iFreq).(sprintf('Ig%d',index)) = stages(index).gate.PSU.get('Current'); 
                    %get the meter currents and voltages if the field
                    %exists 
                    %drain voltage multimeter
                    if isfield(results(iPower,iFreq),sprintf('DrainVmeter%d',index))
                        results(iPower,iFreq).(sprintf('DrainVmeter%d',index)) = stages(index).drain.Vmeter.get('Voltage'); 
                    end
                    %drain current multimeter
                    if isfield(results(iPower,iFreq),sprintf('DrainImeter%d',index))
                        results(iPower,iFreq).(sprintf('DrainImeter%d',index)) = stages(index).drain.Imeter.get('Current'); 
                    end
                    %gate voltage multimeter
                    if isfield(results(iPower,iFreq),sprintf('GateVmeter%d',index))
                        results(iPower,iFreq).(sprintf('GateVmeter%d',index)) = stages(index).gate.Vmeter.get('Voltage'); 
                    end
                    %gate current multimeter
                    if isfield(results(iPower,iFreq),sprintf('GateImeter%d',index))
                        results(iPower,iFreq).(sprintf('GateImeter%d',index)) = stages(index).gate.Imeter.get('Current'); 
                    end
                end

                %turn off source power 
                if TURN_SRC_PWR_OFF_BETWEEN_FREQS
                    %turn the RF source off again
                    rfSource.set('State','OFF'); 
                end
                
                % Print the Results 
                fprintf('### Captured Results (Frequency: %0.3f Power: %0.3f) ###\n',freq(iFreq),power(iPower)); 
                fprintf('Pin: %0.3f\n',  results(iPower,iFreq).Pin)
                fprintf('Pavs: %0.3f\n', results(iPower,iFreq).Pavs);
                fprintf('Pout: %0.3f\n', results(iPower,iFreq).Pout); 
                fprintf('Pdel: %0.3f\n', results(iPower,iFreq).Pdel);
                for index = 1:length(stages)
                    fprintf('%s Drain Voltage: %0.3f\n', stages(index).name, results(iPower,iFreq).(sprintf('Vd%d',index)));
                    fprintf('%s Drain Current: %0.3f\n', stages(index).name, results(iPower,iFreq).(sprintf('Id%d',index))); 
                    fprintf('%s Gate Voltage: %0.3f\n', stages(index).name, results(iPower,iFreq).(sprintf('Vg%d',index)));
                    fprintf('%s Gate Current: %0.3f\n', stages(index).name, results(iPower,iFreq).(sprintf('Ig%d',index))); 
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
            %figure(PLOT_RESULTS);
            figure(1);
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
            %calculate the dc power 
            pdcEst = zeros(1,length(freq)); %get dc power estimate for each stage
            for index = 1:length(stages)
                pdcEst = pdcEst + ...
                    [results(iPower,:).(sprintf('Vd%d',index))].*...
                    [results(iPower,:).(sprintf('Id%d',index))] +...
                    [results(iPower,:).(sprintf('Vg%d',index))].*...
                    [results(iPower,:).(sprintf('Ig%d',index))]; 
            end

            plot(freq(not([results(iPower,:).Pdel]==0)),...
                100.*(dbm2w([results(iPower,:).Pdel]) - ...
                dbm2w([results(iPower,:).Pavs])) ...
                ./(pdcEst)); 
            title('PAE')
            ylabel('PAE (%)'); 
        end
        
    end
catch ME %if an error is encountered in this loop
    %save the data
    fn = [datestr(now,'yyyymmddTHHMMSS') '_Emergency_Save_results.mat']; 
    if exist('quiescentContactRes','var')
        save(fullfile(WORKING_DIR,fn),'results','power','freq','quiescentContactRes');
    else 
        save(fullfile(WORKING_DIR,fn),'results','power','freq');
    end
    %make sure the RF source is off
    rfSource.set('State','OFF'); 
    %attempt to shutdown the power amplifier (if on)
    if AUTO_BIAS_AMPLIFIER
        fprintf('Attempting to bias off amplifier...')
        for stageIndex = fliplr(1:length(stageIndex))
            stages(stageIndex) = biasOff(stages(stageIndex)); 
        end
        fprintf('Done\n')
    end
    %close the waitbar if open
    if exist('wtbr','var') && isvalid(wtbr) 
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


%% Step 10: Bias Off the Amplifier 

%make sure rf source is off 
rfSource.set('State','OFF'); 

%now try to bias off the amplifier
if AUTO_BIAS_AMPLIFIER
    try
        fprintf('Attempting to bias off amplifier...'); 
        numSteps = length(stages); 
        for stageIndex = fliplr(1:numSteps)
            %notify the user 
            if exist('wtbr','var') && isvalid(wtbr) 
                wtbr = waitbar(stageIndex./numSteps,...
                               wtbr,...
                               sprintf('De-biasing: %s',stages(stageIndex).name)); 
            end
            %now debias the stage
            stages(stageIndex) = biasOff(stages(stageIndex),AUTO_BIAS_WTBR); 
        end
        fprintf('Done. DUT is off.\n')
    catch ME 
        %shutdown in revers order 
        emergencyShutdown(fliplr(stages))
        %rethrow the error 
        rethrow(ME); 
    end
end  

%% Step 11: Save The Results 
%Tell the user that we are closing the results
if exist('wtbr','var') && isvalid(wtbr) 
    waitbar(1,wtbr,'Saving Results...');
end

fprintf('Saving results...')
fn = [datestr(now,'yyyymmddTHHMMSS') '_results.mat'];
if exist('quiescentContactRes','var')
    save(fullfile(WORKING_DIR,fn),'results','power','freq','quiescentContactRes');
else 
    save(fullfile(WORKING_DIR,fn),'results','power','freq');
end

%tell the user that the results are saved
if exist('wtbr','var') && isvalid(wtbr)
    waitbar(1,wtbr,'Done'); 
end
fprintf('Done. Results saved successfully to %s\n',WORKING_DIR)

%% Step 12: Close the Waitbar
if  exist('wtbr','var') && isvalid(wtbr)
    close(wtbr); 
end
