classdef BiasController < handle
    %BIASCONTROLLER This is a general object for controlling the bias of a
    %single stage of an amplifier. 
    
    properties
        SMUs
        Meters
    end
    
    methods
        function this = BiasController(varargin)
            %BIASCONTROLLER Construct an instance of this class
            %   Inputs: 
            %    SMU        - Handle of the first power supply
            %    Vmeter     - Handle of the voltage measurement instrument
            %                 for SMU1. If empty (or not set) this object
            %                 will use SMU's internal voltage measurement.
            %    Imeter     - Handle of the current measurement instrument
            %                 for SMU1. If empty (or not set) the 
            %                 controller will use the internal current
            %                 measurement function of the corresponding
            %                 SMU. 
        end
    end

    methods(Abstract)
        biasOn(this);
        biasOff(this);
        shutdown(this);
    end
end

