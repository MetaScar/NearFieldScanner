classdef U8487A < templates.BaseInstrument & ...
                  io.USBInstr & ...
                  templates.PowerMeter
    %U8487A A 10 MHz to 50 GHz
    %   Detailed explanation goes here
    
    properties(Access = protected)
        %instrument defaults
        DEFAULT_FREQ                =   1; 
        DEFAULT_TRIG_SOURCE         =   'IMM';
        DEFAULT_NUM_OF_AVERAGES     =   32; 
        DEFAULT_FREQ_SUFFIX         =   'GHz';
        DEFAULT_AVERAGE_MODE        =   'AUTO';
        %comm debug mode queries for an error every time a message or query
        %would be sent. This should be false under normal operation.
        COMM_DEBUG_MODE             =   false; 
        
        %Power meter properties 
        FreqMin                     =   10e-3;      %10 MHz
        FreqMax                     =   50;         %50 GHz
        NOAMin                      =   0;          %averaging off
        NOAMax                      =   1024;       %1024 averages
        AveragingModes              =   {'AUTO','MANUAL'};

        %List of Valid Inputs       
        VALID_TRIG_SOURCE           =  {'BUS','EXT','HOLD','IMM'}
    end

    properties
        %main class properties go here
        offsetVals                 =    [];
        offsetFreqs                =    [];         
        useOffset                  =    false; 
    end
    
    methods
        function this = U8487A(varargin)
            %U8487A Construct an instance of this class
            %   Detailed explanation goes here
            %initialize the argument parser 
            p = inputParser(); 
            
            %add optional arguments 
            addParameter(p,'Address','');

            %parse the input arguments
            parse(p,varargin{:});
            
            %Initialize the base instrument interface 
            this = this@templates.BaseInstrument('U8487A','Keysight');
            %Setup and connect to the instrument
            this = this@io.USBInstr('Keysight',p.Results.Address,...
                                     'visaInputBufferSize',  20000,...
                                     'visaTimeout',60);
            %setup and initialize the power meter (pass all input
            %arguments)
            this = this@templates.PowerMeter(varargin{:});
        end  
        function valOut = measure(this,resolution)
            %% Performs a Simple Measurement
            if not(exist('resolution','var'))
                valOut = str2double(this.read(['MEAS?;\n']));
            else
                %get coarse estimated power level from initial read 
                pEst = round(str2double(this.read('MEAS? DEF, 1;\n'))); 
                %now make a more precise measurement  
                valOut = str2double(this.read(sprintf(['MEAS? %dDBM,' ...
                                num2str(resolution) ';\n'],pEst)));
            end

            %% Apply the offset if requested
            if this.useOffset
                presentFrequency = str2double(this.frequency);
                valOut = valOut + ...
                    interp1(this.offsetFreqs, ...
                    this.offsetVals,presentFrequency,"linear","extrap");
            end
        end
        function calibrate(this,type)
            %% Run A Cailbration 
            if not(exist("type",'var'))
                type = 'INT';
            end

            switch lower(type)
                case 'int'
                    %run an internal calibration
                    result = this.read('CAL?;\n');
                    if result == 0
                        this.issueWarning('Calibration was unsuccessful.');
                    end
                otherwise
                    this.issueWarning('Unrecognized calibration type %s', ...
                        type);
            end
        end
        function zero(this)
            %% Zero out the power meter
            this.write('CAL:ZERO:AUTO ONCE;\n');
        end
        function msgOut = getError(this)
            %% Get Error Message from the Power Meter
            %turn off debug mode temporarily            
            %query the error (it is important that this does not use the
            %read function)
            msgOut = query(this.VisaObj,'SYST:ERR?;\n');
            if strcmp(msgOut,sprintf('+0,"No error"\n'))
                msgOut = [];
            end
        end
    end

  methods(Access=protected)
        
        %% Call This Upon Clearing this Object
        function delete(this)
            %% Make Sure to Disconnect the Instrument 
            this.shutdown;
            this.disconnect; 
        end
        %methods for initializing or shutting down the power meter
        initialize(this);
        shutdown(this);

        %% Validation Functions
        
        %% Operations
        %functions for accessing the averages of the power meter
        function valOut = getAverages(this)
            if this.isConnected
                %return zero if averaging is off
                if str2double(this.read('SENS:AVER:STAT?;\n'))
                    valOut = str2num(this.read('SENS:AVER:COUN?;\n'));
                else %if not return the numeric value 
                    valOut = 0; 
                end
            else 
                this.issueWarning(['Instrument is not connected. ' ...
                    'Cannot get the number of averages.'])
                valOut = [];
            end
        end
        function setAverages(this,valIn)
            if this.isConnected
                %if the value of valin is >0 turn on and set it to the 
                %value indicated
                if valIn
                    %turn averaging on 
                    this.write('SENS:AVER:STAT ON;\n');
                    %set it to the value indicated
                    %update the averaging number
                    this.write('SENS:AVER:COUN %d;\n',valIn);
                else
                    %turn averaging off 
                    this.write('SENS:AVER:STAT OFF;\n')
                end
            else
                this.issueWarning(['Instrument is not connected. ' ...
                                   'Cannot set the number of averages.'])
            end
        end
        %setter and getter for averaging mode property
        function setAveragingMode(this,modeIn)
            switch lower(modeIn)
                case 'manual'
                    %set averaging mode to manual
                    this.write('AVER:COUN:AUTO OFF;\n');
                case 'auto'
                    %set averaging mode to automatic
                    this.write('AVER:COUN:AUTO ON;\n');
                otherwise 
                    %notify the user that the requested mode does not exist
                    warning(['Mode %s unrecognized. ' ...
                        'Averaging mode not set.'],modeIn); 
            end
        end
        function result = getAveragingMode(this)
            %get the response from the power meter 
            isAuto = str2double(this.read('AVER:COUN:AUTO?;\n'));
            %format the response for the user
            if isAuto
                result = 'AUTO';
            else
                result = 'MANUAL';
            end
        end
        %functions for accessing the frequency of the power meter 
        function valOut = getFrequency(this)
            if this.isConnected
                valOut = this.read('FREQ?;\n');
            else
                this.issueWarning(['Instrument not connected. ' ...
                    'Cannot query frequency.'])
                valOut = [];
            end
        end
        function setFrequency(this,valIn)
            if this.isConnected
               this.write(['FREQ ' num2str(valIn) ' ' this.DEFAULT_FREQ_SUFFIX ';\n']);
            else
                this.issueWarning(['Instrument not connected. ' ...
                    'Cannot set frequency.'])
            end
        end
        %functions for accessing the trigger of the power meter
        function valOut = getTriggerSource(this)
            %get the trigger source from the instrument
            if this.isConnected
               valOut = this.read('TRIG:SOUR?;\n');
            else
                this.issueWarning(['Instrument not connected. ' ...
                    'Cannot get trigger source.'])
            end
        end
        function setTriggerSource(this,valIn)
            %send the trigger source to the instrument
            if this.isConnected
               this.write('TRIG:SOUR %s;\n',valIn); 
            else
                this.issueWarning(['Instrument not connected. ' ...
                    'Cannot set trigger source.'])
            end
        end
  
  end


end



