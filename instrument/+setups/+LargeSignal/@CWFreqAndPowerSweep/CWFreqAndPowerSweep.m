classdef CWFreqAndPowerSweep < handle
    %CWFREQANDPOWERSWEEP Bench for managing CW frequency and power sweep of
    % power amplifier
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        function obj = CWFreqAndPowerSweep(varargin)
            %CWFREQANDPOWERSWEEP Construct an instance of this class
            %   Detailed explanation goes here
            

            %initialize the input parser 
            p = inputParser(); 
            
            %add parameters 
            addParameter(p,'InputPowerMeter',[])
            addParameter(p,'OutputPowerMeter',[])
            addParameter(p,'AmplifierSupply',[])
            addParameter(p,'DriverSupply',[])
            addParameter(p,'')
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

