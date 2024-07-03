function stage = biasOn(stage,useWaitBar)
%Bias On Function (V1) biases on the selected stage described by stageObject
% This function is designed to perform the biasing operation for a single
% stage. For this function, a single stage is defined by having 

%% Make sure the stage is off 
assert(strcmpi(stage.state,'off'),['Stage is already flagged as on. ' ...
    'Cannot bias up.']); 

%% Handle useWaitbar Variable 
if not(exist('useWaitBar','var'))
    useWaitBar = false; 
else
    wtbr = waitbar(0,sprintf('Beginning Bias-On Sequence...')); 
end

%% Set Compliance Currents in Supplies
%make sure all supplies are off and that the state is 
%turn both power supplies off 
stage.drain.PSU.set('State','OFF','Voltage',stage.drain.Voff,'Current',stage.drain.Ilim); 
stage.gate.PSU.set('State','OFF','Voltage',0,'Current',stage.gate.Ilim); 

%turn supplies on 
stage.gate.PSU.set('State','ON'); 
stage.drain.PSU.set('State','ON'); 

%% Pinchoff the Gate 
%calcualte the steps we will ste the gate voltage at
    VgSteps = 0:(sign(stage.gate.Voff-0)*stage.gate.NomStep):...
             stage.gate.Voff; 
    %now slowly pinch off the gate voltage
    numSteps = length(VgSteps); 
    for iVg = 1:length(VgSteps)
        %get the setpoint for the gate voltage 
        VgSet = VgSteps(iVg); 
        %set the value 
        stage.gate.PSU.set('Voltage',VgSet); 
        %check if we are current limiting 
        if isCurrentLimiting()
            %shutdown this stage now
            % emergencyShutdown(stage)
            %close the waitbar 
            close(wtbr); 
            %return an error 
            error(['Current limiting encountered during gate pinch off ' ...
                'procedure on DUT stage %s'],stage.name); 
        elseif useWaitBar
            %update the waitbar 
            waitbar(iVg/numSteps,wtbr,sprintf('Biasing Gate... Vg = %0.3fV',VgSet)); 
        end
        %wait for gate to settle 
        pause(stage.gate.wait); 
    end

%% Bring Drain Voltage Up 
    %calculate the steps we will set the drain voltage at
    VdSteps = stage.drain.Voff:...
      (sign(stage.drain.Von-stage.drain.Voff)*stage.drain.NomStep):...
      stage.drain.Von; 
    %now slowly bring up the drain voltage
    numSteps = length(VdSteps); 
    for iVd = 1:length(VdSteps)
        %get the setpoint for the gate voltage
        VdSet = VdSteps(iVd); 
        %set the drain voltage 
        stage.drain.PSU.set('Voltage',VdSet); 
        %check if we are current limiting 
        if isCurrentLimiting()
            %shutdown this stage now
            % emergencyShutdown(stage);
            %close the waitbar 
            close(wtbr); 
            %return an error 
            error(['Current limiting encountered during gate pinch off ' ...
                'procedure on DUT stage %s'],stage.name); 
        elseif useWaitBar
            %update the waitbar
            waitbar(iVd/numSteps,wtbr, ...
                sprintf('Biasing Drain... Vd = %0.3fV',VdSet)); 
        end
        %wait for drain to settle 
        pause(stage.drain.wait)
    end

%% Begin Biasing On the DUT 
    qCurrHigh = stage.IqTarget.Value + stage.IqTarget.Tol; 
    qCurrLow  = stage.IqTarget.Value - stage.IqTarget.Tol; 
    vgStep = stage.gate.NomStep; prevBelowTarget = true; 
    presVgVal = abs(stage.gate.Voff); 
    %for determining the waitbar position
    maxTolErr = abs(stage.IqTarget.Tol)./stage.IqTarget.Value; 
    
    %slowly bring gate voltage up until final conditions are met
    while true
        %get the drain current
        iDrain = stage.drain.PSU.get('Current');
    
        %update the waitbar if it's available 
        if useWaitBar
            %get the percent error of the present current
            pctErr = abs(iDrain - stage.IqTarget.Value)./stage.IqTarget.Value; 
            %calculate the progress
            progress = min(max(maxTolErr./pctErr,0),1); 
            %update the waitbar
            waitbar(progress,wtbr, ...
                sprintf('Measured Current: %0.3e A, relErr: %0.1f%%', ...
                iDrain, pctErr.*100)); 
        end
        
        if isCurrentLimiting()
            %if we're current limiting shut everything down now
            % emergencyShutdown(stage);
            %close the waitbar 
            close(wtbr); 
            %return an error 
            error(['Current limiting encountered during bias on ' ...
                'procedure on DUT stage %s'],stage.name); 
        elseif (iDrain >= qCurrLow) && (iDrain <= qCurrHigh)
            %update user we are going to wait 
            if useWaitBar
                %update the waitbar
                waitbar(progress,wtbr, ...
                    sprintf('Waiting %0.1f seconds for current to settle...', ...
                    stage.IqTarget.SettleTime)); 
            end
            
            %wait for current to settle
            pause(stage.IqTarget.SettleTime)

            %recheck to see if we are still within bounds 
            iDrain = stage.drain.PSU.get('Current'); 
            
            %now recheck to see if we are within bounds
            if (iDrain >= qCurrLow) && (iDrain <= qCurrHigh)
                %we've settled to the appropriate quiescent current limit 
                break; 
            elseif  iDrain > qCurrHigh
                %if we were previously below the target
                if prevBelowTarget
                    vgStep = vgStep/2; 
                    prevBelowTarget = false; 
                end
                %now add step to current voltage value (move away from 0V)
                presVgVal = (presVgVal + vgStep)*sign(stage.gate.Voff); 
            else
                %if we were previously above the target 
                if not(prevBelowTarget)
                    vgStep = vgStep/2; 
                    prevBelowTarget =  true; 
                end
                %now add the previous value to the (go toward 0V)
                presVgVal = (presVgVal - vgStep)*sign(stage.gate.Voff); 
            end
        elseif iDrain > qCurrHigh
            %if we were previously below the target
            if prevBelowTarget
                vgStep = vgStep/2; 
                prevBelowTarget = false; 
            end
            %now add step to current voltage value (move away from 0V)
            presVgVal = (presVgVal + vgStep)*sign(stage.gate.Voff); 
        else
            %if we were previously above the target 
            if not(prevBelowTarget)
                vgStep = vgStep/2; 
                prevBelowTarget =  true; 
            end
            %now add the previous value to the (go toward 0V)
            presVgVal = (presVgVal - vgStep)*sign(stage.gate.Voff); 
        end
    
        %check that the present Vg value doesn't exceed some safety limits
        if (presVgVal > stage.gate.Max) || (presVgVal < stage.gate.Min)
            % emergencyShutdown(stage); 
            error('Attempted to set gate voltage out of bounds')
        end
    
        %if we didn't trigger the error, move forward with setting the gate
        %voltage 
        stage.gate.PSU.set('Voltage',presVgVal); 
        pause(stage.gate.wait); 
    end

%% Close the waitbar 
close(wtbr); 

%% Flag the stage as on 
    stage.state = 'on';     

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

