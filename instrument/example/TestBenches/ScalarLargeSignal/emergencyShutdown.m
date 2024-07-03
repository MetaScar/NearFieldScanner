function emergencyShutdown(stageObjects)
%Emergency Shutdown Turns off the each stage of the amplifier 
    %set all drain voltages to 0V
    for index = 1:length(stageObjects)
        %set the voltage to 0V and set compliance current to 0A
        stageObjects(index).drain.PSU.set('Voltage',0,'Current',0); 
    end

    %set turn all stages off 
    for index = 1:length(stageObjects)
        %turn off the drain supply 
        stageObjects(index).drain.PSU.set('State','OFF'); 
        %turn off the gate supply 
        stageObjects(index).gate.PSU.set('State','OFF'); 
    end

    %set gate voltages and currents to 0
    for index = 1:length(stageObjects)
        %set voltage to 0V and current to 0A
        stageObjects(index).gate.PSU.set('Voltage',0,'Current',0);
    end
end