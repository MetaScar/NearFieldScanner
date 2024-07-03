classdef DMFetBiasController < handle
    %Depletion Mode Fet bias Controller A bias controller for depletion
    %mode type FETs. 
    %   Detailed explanation goes here
    
    properties
        %gate data sources
        gateSMU
        gateVmeter      =   [];
        gateImeter      =   [];

        %drain data sources
        drainSMU
        drainVmeter     =   [];
        drainImeter     =   [];

        %% Global Settings 
        %limits on the gate and drain SMUs
        vgMax           =   5;      
        igMax           =   0.01; %current limit is specified in A 
        vdMax           =   30;
        idMax           =   0.01; %current limit is specified in A
        
            
        %% Initialization Settings
        initVd          =   0; 
        initVg          =   0; 
        
        %% Pinchoff Settings 
        poVgOff         =   3; 
        poVgStep        =   0.5; 
        poVgWait        =   0; 
        poVdOn          =   10; 
        poVdStep        =   0.5; 

        %% On Settings 
        onIq
        onVgStep        =   0.025; 
    end
    
    methods
        function obj = DMFetBiasController(gateSMU,drainSMU,Vd,Iq,varargin)
            %GANFETBIASCONTROLLER Construct an instance of this class
            %   Detailed explanation goes here
            
            
        end
        
        function initialize(this)
            %% Initialize this Stage
            %turn both SMUs off 
            this.drainSMU.set('State','OFF');
            this.gateSMU.set('State','OFF'); 
            %apply the inital voltage value and current limit 
            this.drainSMU.set('Voltage',this.initVd,'Current',this.idMax); 
            this.gateSMU.set('Voltage',this.initVg,'Current',this.igMax); 
            %turn the supplies back on 
            this.gateSMU.set('State','ON'); 
            this.drainSMU.set('State','ON'); 
        end

        function biasOn(this)
            %% Bias on Procedure for this FET 
            
            %Step 1: Pinch off the gate 

            %Step 2: Turn on the drain supply

            %Step 3: Bring the gate back up 

            %Step 4: Let the Drain Current Settle

            %Step 5: Adjust the Gate Voltage
        end

        function biasOff(this)
            %% Bias Off Procedure for this FET
            
            %Step 1: Turn the Drain Off

            %Step 2: Bring the Gate Back to Initial State 

            %Step 3: Turn Supplies Off 

        end

        function shutdown(this)
            %% Emergency Shutdown Procedure for this FET
            
        end
        
        %functions for reading the state of the gate and drain
        function gv = gateVoltage(this)
            %% Returns the Gate Voltage
            if isempty(this.gateVmeter)
                gv = this.gateSMU.get('Voltage');
            else
                gv = this.gateVmeter.get('Voltage'); 
            end
        end
        function gc = gateCurrent(this)
            if isempty(this.gateImeter)
                gc = this.gateSMU.get('Current'); 
            else
                gc = this.gateImeter.get('Current'); 
            end
        end
        function dv = drainVoltage(this)
            %% Returns the Gate Voltage
            if isempty(this.gateVmeter)
                dv = this.drainSMU.get('Voltage');
            else
                dv = this.drainVmeter.get('Voltage'); 
            end
        end
        function dc = drainCurrent(this)
            if isempty(this.drainImeter)
                dc = this.drainSMU.get('Current'); 
            else
                dc = this.drainImeter.get('Current'); 
            end
        end
    end
end

