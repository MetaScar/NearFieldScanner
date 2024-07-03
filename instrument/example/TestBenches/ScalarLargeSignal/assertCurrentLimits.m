function assertCurrentLimits(stages)
%Assert Current Limits Checks Checks the gate and drain(s) of each stage
%and throws an error if the limits are exceeded by 95%
    
    %check the gate and drain of each stage
    for index = 1:length(stages)

        %check the gate first 
        gateCurrent = stages(index).gate.PSU.get('Current'); 

        %check if the current is limiting 
        assert(gateCurrent < 0.95*(stages(index).gate.Ilim), ...
            sprintf('Current limit reached on %s gate.',stages(index).name)); 

        %check each drain for the stage 
        for drainIndex = 1:length(stages(index).drain.PSU)
            %get the current drain current 
            drainCurrent = ...
                stages(index).drain.PSU(drainIndex).get('Current'); 
            
            %if a single current limit is given, use that for all stages
            if length(stages(index).drain.Ilim) == 1
                drainIlim = stages(index).drain.Ilim; 
            else %otherwise use a per-drain current limit 
                drainIlim = stages(index).drain.Ilim(drainIndex); 
            end

            %now assert that the drain current for the present meter is not
            %limiting 
            assert(drainCurrent < 0.95*drainIlim,...
                sprintf('Current limit reached on drain%d of %s',...
                drainIndex,stages(index).name)); 
        end

    end
end