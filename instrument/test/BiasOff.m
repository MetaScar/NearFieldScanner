function [] = BiasOff(PSU, gate, drain,useWaitBar)
%BiasOff A function for auto biasing off a GaN power amplifier (single
%state)
%   Detailed explanation goes here

%% Handle useWaitbar Variable 
%default to not using the waitbar
if not(exist('useWaitBar','var'))
    useWaitBar = false; 
else
    wtbr = waitbar(0,sprintf('Beginning Bias-Off Sequence...')); 
end

%% Turn down the drain voltage 
%get the on voltage for the drain
Von = PSU.get('drain','Voltage');
%calculate the steps we will set the drain voltage at
VdSteps = ...
    fliplr(drain.Voff:...
          (sign(Von-drain.Voff)*drain.NomStep):Von); 
%now slowly pinch off the gate voltage 
numSteps = length(VdSteps); 
for iVd = 1:length(VdSteps)
    %get the setpoint for the gate voltage
    VdSet = VdSteps(iVd); 
    %now set the gate voltage 
    PSU.set('drain','Voltage',VdSet); 
    %update the progress bar
    if isCurrentLimiting(PSU,gate,drain)
        %run emergency shutdown procedure
        emergencyShutdown(PSU,gate,drain); 
    elseif useWaitBar
        %update the waitbar
        waitbar(iVd/numSteps,wtbr, ...
            sprintf('De-biasing Drain... Vd = %0.3fV',VdSet)); 
    end
    %now wait the proscribed amount of time
    pause(drain.wait); 
end

%% Bring the gate voltage back to 0V
%get the on voltage for the gate
Von = PSU.get('gate','Voltage'); 
%calculate the steps we will set the gate voltage at
VgSteps = fliplr(0:(sign(Von-0)*gate.NomStep):Von); 
%now slowly pinch off the gate voltage 
numSteps = length(VgSteps); 
for iVg = 1:length(VgSteps)
    %get the setpoint for the gate voltage
    VgSet = VgSteps(iVg); 
    %now set the gate voltage 
    PSU.set('gate','Voltage',VgSet); 
    %update the progress bar
    if isCurrentLimiting(PSU,gate,drain)
        %run emergency shutdown procedure
        emergencyShutdown(PSU,gate,drain); 
    elseif useWaitBar
        %update the waitbar
        waitbar(iVg/numSteps,wtbr,sprintf('De-biasing Gate... Vg = %0.3fV',VgSet)); 
    end
    %now wait the proscribed amount of time
    pause(gate.wait); 
end
%% Now turn both channels off
PSU.set('gate','State','OFF'); 
PSU.set('drain','State','OFF'); 

%% Now close the waitbar if it was originally requested
close(wtbr);

end

function emergencyShutdown(PSU,gate,drain)
%% Emergency shutdown function for this autobiasing operation 
%first, immediately set the drain voltage to the off voltage 
PSU.set('drain','Voltage',drain.Voff); 
pause(1); %wait for any capacitance to discharge
%next, turn the gate voltage off 
% PSU.set('gate','Voltage',gate.Voff); 
PSU.set('gate','Voltage',0);
%now turn both channels off 
PSU.set('drain','State','OFF');
PSU.set('gate','State','OFF'); 
%throw an error for the emergency shutdown 
error('Current limiting detected. Bias on procedure aborted.')
end

function tf = isCurrentLimiting(PSU,gate,drain)
%% Is Current Limiting - Returns true if the supply is current limiting 
tf = PSU.get('drain','Current') >= 0.95*drain.Ilim ||...
     PSU.get('gate','Current')  >= 0.95*gate.Ilim; 
end