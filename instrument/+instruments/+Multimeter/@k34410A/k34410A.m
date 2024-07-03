classdef k34410A < templates.BaseInstrument & io.GPIBInstr
    %K34410A 6.5 digit precision multimeter
    %   This class acts an interface for the k34410A digital multimeter
    
    properties
        %default properties go here 
    end

    properties(Constant)
        
    end
    
    methods
        function this = k34410A(varargin)
            %K34410A Construct an instance of this class
            %   Detailed explanation goes here
            %initialize the argument parser 
            p = inputParser(); 
            
            %add optional arguments 
            addParameter(p,'Address','');

            %parse the input arguments
            parse(p,varargin{:});
            
            %Initialize the base instrument interface 
            this = this@templates.BaseInstrument('34401A','Keysight');
            this = this@io.GPIBInstr('Keysight',p.Results.Address,...
                                     'visaInputBufferSize',200000);

            %assign parameters unique to this instrument 

            
            %connect to the instrument and initialize it 
            this.initialize();
        end
       
        
        function varargout = get(this,varargin)
            %% Get Specified Data from Instrument

            %only run if the current instrument is connected 
            if not(this.isConnected); return; end 

            %issue warning if the number of requested arguments is greatter
            %than the number of input arguments
            if length(varargin)>nargout
                this.issueWarning(['The number of output arguments is ' ...
                    'less than the number of input arguments']);
            end
            
            %iterate through every request by the user
            for argIndex = 1:nargout
                switch(lower(varargin{argIndex}))
                    case 'voltage'
                        varargout{argIndex} = this.getVoltage; 
                    case 'current'
                        varargout{argIndex} = this.getCurrent; 
                    otherwise
                        this.issueWarning('Unrecognized request %s',...
                            varargin{argIndex});
                end
            end
        end
        
    end

    methods(Access=private)
        %% COMMS Functions (Will probably replace with subclass in future)
        function delete(this)
            % shutdown and disconnect the instrument 
            this.shutdown;
            this.disconnect; 
        end

        function initialize(this)
            %% Initialize the Instrument
            %don't run the sequence if not connected
            if not(this.isConnected); return; end
            %setup autorange
            this.setVoltageAutoRange;
            this.setCurrentAutoRange;
        end

        function shutdown(this)
            %% Shutdown Operations for the Present Instrument
        end

        %% Validation Functions

        %% Operations
        %for sensing 
        function vout = getVoltage(this,measType)
            %% Returns The Voltage Measured by the Meter
            if not(exist('type','var'))
                measType = 'DC'; 
            end
            switch lower(measType)
                case 'dc'
                    vout = str2double(this.read('MEAS:VOLT:DC?;\n'));
                case 'ac'
                    vout = str2double(this.read('MEAS:VOLT:AC?;\n'));
                otherwise 
                    this.issueWarning('Unrecognized command %s',measType);
                    vout = [];
            end
        end
        function iout = getCurrent(this,measType)
            %% Returns The Current Measured by the Meter
            if not(exist('type','var'))
                measType = 'DC'; 
            end
            switch lower(measType)
                case 'dc'
                    iout = str2double(this.read('MEAS:CURR:DC?;\n'));
                case 'ac'
                    iout = str2double(this.read('MEAS:CURR:AC?;\n'));
                otherwise 
                    this.issueWarning('Unrecognized command %s',measType);
                    iout = [];
            end
        end
        %for ranging 
        function setVoltageAutoRange(this,on)
            %% Sets the Voltage Range of the Meter

            %default to turning autorange on 
            if not(exist('on','var'))
                on = true; 
            end
            
            %turn autorange on or off
            if on
                this.write('SENS:VOLT:DC:RANG:AUTO ON;\n');
            else
                this.write('SENS:VOLT:DC:RANG:AUTO OFF;\n')
            end
        end
        function setCurrentAutoRange(this,on)
            %% Sets the Curent Range of the Meter

            %default to turning autorange on 
            if not(exist('on','var'))
                on = true; 
            end
            
            %turn autorange on or off
            if on
                this.write('SENS:CURR:DC:RANG:AUTO ON;\n');
            else
                this.write('SENS:CURR:DC:RANG:AUTO OFF;\n')
            end
        end

    end
end

