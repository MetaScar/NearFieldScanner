function [] = BiasOn(PSU, gate, drain, IqTarget,useWaitBar)
%BiasOn A function for auto biasing on a GaN power amplifier 
%   Detailed explanation goes here

%% Handle useWaitbar Variable 
if not(exist('useWaitBar','var'))
    useWaitBar = false; 
else
    wtbr = waitbar(0,sprintf('Beginning Bias-On Sequence...')); 
end

%% Initialize both channels and turn them on 
%initialize both channels (make sure both channels are off during this
%step)
PSU.set('drain','Voltage',0,'Current',drain.Ilim,'State','OFF'); 
PSU.set('gate','Voltage',0,'Current',gate.Ilim,'State','OFF'); 
%turn both channels on 
PSU.set('drain','State','ON'); 
PSU.set('gate','State','ON'); 

%% Pinch off the gate voltage 
%calculate the steps we will set the gate voltage at
VgSteps = 0:(sign(gate.Voff-0)*gate.NomStep):gate.Voff; 
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
        waitbar(iVg/numSteps,wtbr,sprintf('Biasing Gate... Vg = %0.3fV',VgSet)); 
    end
    %now wait the proscribed amount of time
    pause(gate.wait); 
end

%% Turn up the drain voltage
%calculate the steps we will set the gate voltage at
VdSteps = drain.Voff:(sign(drain.Von-drain.Voff)*drain.NomStep):drain.Von; 
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
            sprintf('Biasing Drain... Vd = %0.3fV',VdSet)); 
    end
    %now wait the proscribed amount of time
    pause(drain.wait); 
end

%% Turn gate voltage back up 
qCurrHigh = IqTarget.Value + IqTarget.Tol; 
qCurrLow  = IqTarget.Value - IqTarget.Tol; 
vgStep = gate.NomStep; prevBelowTarget = true; 
presVgVal = abs(gate.Voff); 
%for determining the waitbar position
maxTolErr = abs(IqTarget.Tol)./IqTarget.Value; 

while true
    %get the drain current
    iDrain = PSU.get('drain','Current');

    %update the waitbar if it's available 
    if useWaitBar
        %get the percent error of the present current
        pctErr = abs(iDrain - IqTarget.Value)./IqTarget.Value; 
        %calculate the progress
        progress = min(max(maxTolErr./pctErr,0),1); 
        %update the waitbar
        waitbar(progress,wtbr, ...
            sprintf('Measured Current: %0.3e A, relErr: %0.1f%%', ...
            iDrain, pctErr.*100)); 
    end
    
    if isCurrentLimiting(PSU,gate,drain)
        emergencyShutdown(PSU,gate,drain)
    elseif (iDrain >= qCurrLow) && (iDrain <= qCurrHigh)
        break; 
    elseif iDrain > qCurrHigh
        %if we were previously below the target
        if prevBelowTarget
            vgStep = vgStep/2; 
            prevBelowTarget = false; 
        end
        %now add step to current voltage value (move away from 0V)
        presVgVal = (presVgVal + vgStep)*sign(gate.Voff); 
    else
        %if we were previously above the target 
        if not(prevBelowTarget)
            vgStep = vgStep/2; 
            prevBelowTarget =  true; 
        end
        %now add the previous value to the (go toward 0V)
        presVgVal = (presVgVal - vgStep)*sign(gate.Voff); 
    end

    %check that the present Vg value doesn't exceed some safety limits
    if (presVgVal > gate.Max) || (presVgVal < gate.Min)
        emergencyShutdown(PSU,gate,drain); 
        error('Attempted to set gate voltage out of bounds')
    end

    %if we didn't trigger the error, move forward with setting the gate
    %voltage 
    PSU.set('gate','Voltage',presVgVal); 
    pause(gate.wait); 
end

%% Now close the waitbar if it was origionally requested
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