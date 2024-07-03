classdef k83650A < templates.BaseInstrument & io.GPIBInstr
    %k83050A 10MHz to 50 GHz Signal Sweeper
    %   Detailed explanation goes here
    
    properties
%         VisaObj                     %Object pointing to the visa device
%         address                     %address of the object
    end

    properties(Constant)
        %define the default properties for this instrument
        DEFAULT_INIT_POWER     = -40; 
    end
    
    methods
        function this = k83650A(varargin)
            %k83050A Construct an instance of this class
            %   Detailed explanation goes here
            %initialize the argument parser 
            p = inputParser(); 
            
            %add optional arguments 
            addParameter(p,'Address','GPIB1:16:INSTR', @isstring);

            %parse the input arguments
            parse(p,varargin{:});
            
            %Initialize the base instrument interface 
            this = this@templates.BaseInstrument('83650A','Keysight');
            this = this@io.GPIBInstr('Keysight',p.Results.Address,...
                                     'visaInputBufferSize',  50000,...
                                     'visaOutputBufferSize', 50000);

            %assign parameters

            %connect to the instrument and initialize it 
            this.initialize();
        end

        function set(this,varargin)
            
            %only run if the current instrument is connected 
            if not(this.isConnected); return; end 

            %initialize the argument parser 
            p = inputParser(); 
            
            %add optional arguments 
            addParameter(p,'Power',[]);
            addParameter(p,'PowerUnit','dBm')
            addParameter(p,'Frequency',[]);
            addParameter(p,'FrequencyUnit','GHz'); 
            addParameter(p,'State',''); 
            
            
            %parse the input arguments
            parse(p,varargin{:});
            
            %first handle the case where we wish to turn the sweeper off 
            if strcmpi(p.Results.State,'off')
                this.disable; 
            end
            
            %next, handle the case where we wish to adjust the power 
            if not(isempty(p.Results.Power))
                this.setPower(p.Results.Power,p.Results.PowerUnit);
            end

            %next, handle the case where we wish to adjust the frequency
            if not(isempty(p.Results.Frequency))
                this.setCWFrequency(p.Results.Frequency, ...
                    p.Results.FrequencyUnit);
            end

            %next, handle the case where we wish to turn on the sig gen 
            if strcmpi(p.Results.State,'on')
                this.enable;
            end
        end
    end
    
    methods(Access=private)
        %% Call This Upon Clearing this Object
        function delete(this)
            %% Make Sure to Disconnect the Instrument 
            this.disconnect; 
        end
        %% COMMS Functions (Will probably replace with subclass in future)
        function this = initialize(this)
            %% Initialize - Initializes the instrument for use
            %only run if the current instrument is connected 
            if not(this.isConnected); return; end 
            
            %turn the output off
            this.disable; 
            this.enablePowerCorrection;
            this.setPower(instruments.SigGen.k83650A.DEFAULT_INIT_POWER); 

            %need to figure these out later
            this.write('PULS:SOUR INT;\n');
            this.write('PULS:STAT OFF;\n')
        end

        %% Validation Functions

        %% Operations

        function enable(this)
            %% Turns the Power ON
            this.write('POW:STAT ON;\n');
        end
        function disable(this)
            %% Turns the Output OFF
            this.write('POW:STAT OFF;\n');
        end
        function setPower(this,val,suf)
            %% Set the Power Level
            if not(exist('suf','var'))
                suf = 'dBm'; 
            end
            
            %set the power level to the specified value 
            this.write(['POW:LEVEL ' num2str(val) ' ' suf ';\n']); 
        end
        function enablePowerCorrection(this)
            %% Turn Correction On
            this.write('CORR:STAT ON;\n');
        end
        function disablePowerCorrection(this)
            %% Turn Correction Off
            this.write('CORR:STAT OFF;\n')
        end
        function setCWFrequency(this,val,suf)
            %% Sets the CW Frequency of the sweeper
            %handle the case where the frequency hasn't been assigned 
            if not(exist('suf','var'))
                suf = 'GHz';
            end

            %set the frequency to the specified value 
            this.write(['FREQ:CW ' num2str(val) ' ' suf ';\n']);
        end
    end
end




