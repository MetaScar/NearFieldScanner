function stage = biasOff(stage,useWaitBar)
%BiasOff A function for auto biasing off a GaN power amplifier 
%   Detailed explanation goes here

%% Make sure the stage is on 
assert(strcmpi(stage.state,'on'),['Stage is already flagged as off. ' ...
    'Cannot bias off.']); 

%% Handle useWaitbar Variable 
%default to not using the waitbar
if not(exist('useWaitBar','var'))
    useWaitBar = false; 
else
    wtbr = waitbar(0,sprintf('Beginning Bias-Off Sequence...')); 
end

%% Turn down the drain voltage 
%get the on voltage for the drain
Von = stage.drain.PSU.get('Voltage');
%calculate the steps we will set the drain voltage at
VdSteps = fliplr(stage.drain.Voff:...
                 (sign(Von-stage.drain.Voff)*stage.drain.NomStep):...
                 Von); 

%now slowly pinch off the gate voltage 
numSteps = length(VdSteps); 
for iVd = 1:length(VdSteps)
    %get the setpoint for the gate voltage
    VdSet = VdSteps(iVd); 
    %now set the gate voltage 
    stage.drain.PSU.set('Voltage',VdSet); 
    %update the progress bar
    if isCurrentLimiting()
        %run emergency shutdown procedure
        emergencyShutdown(stage); 
        %close the waitbar 
        close(wtbr); 
        %return an error 
        error('Current limiting encountered during drain de-biasing of stage %s',stage.name); 
    elseif useWaitBar
        %update the waitbar
        waitbar(iVd/numSteps,wtbr, ...
            sprintf('De-biasing Drain... Vd = %0.3fV',VdSet)); 
    end
    %now wait the proscribed amount of time
    pause(stage.drain.wait); 
end

%% Turn Gate Voltage Back To 0V
%get the on voltage for the gate
Von = stage.gate.PSU.get('Voltage'); 
%calculate the steps we will set the gate voltage at
VgSteps = fliplr(0:(sign(Von-0)*stage.gate.NomStep):Von); 
%now slowly pinch off the gate voltage 
numSteps = length(VgSteps); 
for iVg = 1:length(VgSteps)
    %get the setpoint for the gate voltage
    VgSet = VgSteps(iVg); 
    %now set the gate voltage 
    stage.gate.PSU.set('Voltage',VgSet); 
    %update the progress bar
    if isCurrentLimiting()
        %run emergency shutdown procedure
        emergencyShutdown(); 
        %close the waitbar 
        close(wtbr); 
        %return an error
        error('Current limiting encountered during gate de-biasing of stage %s',stage.name); 
    elseif useWaitBar
        %update the waitbar
        waitbar(iVg/numSteps,wtbr,sprintf('De-biasing Gate... Vg = %0.3fV',VgSet)); 
    end
    %now wait the proscribed amount of time
    pause(stage.gate.wait); 
end

%% Close the Waitbar 
if exist('wtbr','var')
    close(wtbr); 
end

%% Additional Function Definitions
    function tf = isCurrentLimiting()
        %% Assesses Whether the Stage is Presently Current Limiting
        %assume we pass unless stated otherwise 
        tf = false; 
        %check the drain and then the gate
        if stage.drain.PSU.get('Current') >= 0.95*(stage.drain.Ilim) 
            tf = true; 
            return 
        elseif stage.gate.PSU.get('Current') >= 0.95*(stage.gate.Ilim) 
            tf = true; 
            return
        end
    end
end