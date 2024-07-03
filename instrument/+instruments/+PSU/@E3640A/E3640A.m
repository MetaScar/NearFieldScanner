classdef E3640A < templates.BaseInstrument & ...
                  io.GPIBInstr & ...
                  templates.Abstract.ChannelAbstraction
    %E3649A Dual Output DC Power Supply
    %   This class acts as an interface for the E3649A dual output power
    %   supply. 

    properties(Access=protected)
        NUM_CHANNELS = 2;
    end

    properties
        %default properties go here 
        outputAlias                 %structure mapping names to channels
    end

    properties(Constant) 
        %define the default properties for this instrument
        DEFAULT_CURRENT_LIM = 0.01; %Default Current Limit
    end

    methods
        function this = E3640A(varargin)
            %E3649A Construct an instance of this class
            %   Detailed explanation goes here
            
            %initialize the argument parser 
            p = inputParser(); 
            p.KeepUnmatched = true; 
            
            %add optional arguments 
            addParameter(p,'Address','');
            addParameter(p,'Output1Name','');
            addParameter(p,'Output2Name','');
            addParameter(p,'Initialize',true,@(x) islogical(x)); 

            %parse the input arguments
            parse(p,varargin{:});
            
            %Initialize the base instrument interface 
            this = this@templates.BaseInstrument('E3649A','Keysight');
            this = this@io.GPIBInstr('Keysight',p.Results.Address,...
                                     'visaInputBufferSize',  20000);
            this = this@templates.Abstract.ChannelAbstraction(varargin{:}); 

            %set the channel 1 alias
            if not(isempty(p.Results.Output1Name))
                this.outputAlias.(p.Results.Output1Name) = 1; 
            end

            %set the Output 2 alias
            if not(isempty(p.Results.Output2Name))
                this.outputAlias.(p.Results.Output2Name) = 2; 
            end
            
            %initialize the instrument
            if p.Results.Initialize
                this.initialize();
            end
        end

        function set(this,outputName,varargin)
            %% Set Properties for Specified Channel
            % This function sets specific properties for a specific
            % channel. Channel aliases may be used to clarify syntax if
            % set up appropriately. The order of operations (when 
            % requested) will be to turn off the output, set the current 
            % limit, set the voltage, and turn on the output. 
            %  INPUTS: 
            %    outputName - This may be either 1 or 2 (corresponding to
            %    the index of the output) or may be the aliases for the
            %    channels that are assigned by outputAlias.
            %    Voltage    - This is an optional parameter argument that
            %    will set the voltage of the output. 
            %    Current    - This is an optional parameter argument that
            %    will set the current limit of the output. 
            %    State      - This may be either 'ON' or 'OFF'. 

            %only run if the current instrument is connected 
            if not(this.isConnected); return; end 

            %initialize the argument parser
            p = inputParser(); 

            %add optional arguments 
            addRequired(p,'OutputName',@(x) this.isValidOutputName(x));
            addParameter(p,'Voltage',[]);
            addParameter(p,'Current',[]);
            addParameter(p,'State','');

            %parse the arguments
            parse(p,outputName,varargin{:}); 

            %now handle the arguments 
            %first get the channel name from the mapping or as a channel
            %index
            if not(isnumeric(p.Results.OutputName))
                %get the specific index of the channel
                index = this.outputAlias.(p.Results.OutputName); 
            else
                index = p.Results.OutputName;
            end
            
            %first, turn off the supply if requested 
            if strcmpi(p.Results.State,'OFF')
                this.disable; 
            end

            %second, set the current limit appropriately 
            if not(isempty(p.Results.Current))
                this.setCurrentLimit(p.Results.Current);
            end

            %next, set the voltage of the power supply 
            if not(isempty(p.Results.Voltage))
                this.setVoltage(p.Results.Voltage);
            end

            %finally, enable the supply (if requested) 
            if strcmpi(p.Results.State,'ON')
                this.enable; 
            end
        end

        function varargout = get(this,outputName,varargin)
            %% Get Reading From Output
            % This function sets specific properties for a specific
            % channel. Channel aliases may be used to clarify syntax if
            % set up appropriately. The order of operations (when 
            % requested) will be to turn off the output, set the current 
            % limit, set the voltage, and turn on the output.
            % Currently the recognized property names are the following: 
            % 'STATE' - Returns boolean indicating whether the output is on
            %           or off
            % 'VOLTAGE'-Returns the voltage read by the power supply 
            % 'CURRENT'-Returns the current read by the power supply
            
            %only run if the current instrument is connected 
            if not(this.isConnected); return; end 

            %check if the number of output arguments is less than that of
            %the input arguments (and inform the user);
            if length(varargin)>nargout
                this.issueWarning(['The number of output arguments is ' ...
                    'less than the number of input arguments']);
            end
            
            %initialize the argument parser
            p = inputParser(); 

            %add optional arguments 
            addRequired(p,'OutputName',@(x) this.isValidOutputName(x));

            %parse the arguments
            parse(p,outputName);

            %first get the channel name from the mapping or as a channel
            %index
            if not(isnumeric(p.Results.OutputName))
                %get the specific index of the channel
                index = this.outputAlias.(p.Results.OutputName); 
            else
                index = p.Results.OutputName;
            end

            %next we will just iterate through all the additional variable
            %input arguments for data requests     
            for reqIndex = 1:nargout
                switch lower(varargin{reqIndex})
                    case 'state'
                        varargout{reqIndex} = this.getState; 
                    case 'voltage'
                        varargout{reqIndex} = this.readVoltage;
                    case 'current'
                        varargout{reqIndex} = this.readCurrent; 
                    otherwise
                        warning('Unrecognized command %s',...
                                    varargin{reqIndex});
                        varagout{reqIndex} = [];
                end
            end
        end

    end


    methods(Access=private)
        
        %% Call This Upon Clearing this Object
        function delete(this)
            %% Make Sure to Disconnect the Instrument 
            this.shutdown;
            this.disconnect; 
        end
        
        function this = initialize(this)
            %% Initialize - Initializes the instrument for use
            %only run if the instrument is connected
            if not(this.isConnected); return; end
            %setup the channel
            this.disable;
            this.setVoltage(0); 
            this.setCurrentLimit(instruments.PSU.E3649A.DEFAULT_CURRENT_LIM);
        end

        function shutdown(this)
            %% Shutdown Operations Go Here
        end

        %% Validation Functions
        function tf = isValidOutputName(this,valIn)
            %% Is Valid Output Name -- Validation Function for Output Name
            if isnumeric(valIn) && length(valIn)==1 %is this an index
                tf = any(valIn==1:instruments.PSU.E3649A.NUMBER_OF_OUTPUTS); 
            elseif all(ischar(valIn)) || isstring(valIn) %or an alias
                tf = isfield(this.outputAlias,valIn);
            end
        end
        %% Operations
        function enable(this)
            % Enables the presently selected output
            % fprintf(this.VisaObj,'OUTP ON;\n'); 
            this.write('OUTP ON;\n');
        end

        function disable(this)
            % Disables the presently selected output
            % fprintf(this.VisaObj,'OUTP OFF;\n'); 
            this.write('OUTP OFF;\n');
        end

        function setCurrentLimit(this,limVal)
            %% Set Current Limit - Applies the current limit to the supply
            this.write(['CURR ' num2str(limVal) ';\n']);
        end

        function iOut = readCurrent(this)
            %% Get Current - Reads the Current Value for Present Output
            iOut = str2double(this.read('MEAS:CURR?;\n'));
        end

        function setVoltage(this,val)
            %% Set the Voltage of the Presently Selected Channel
            this.write(['VOLT ' num2str(val) ';\n']);
        end

        function vOut = readVoltage(this)
            %% Get Voltage - Reads the Voltage Value for Present Output
            vOut = str2double(this.read('MEAS:VOLT?;\n'));
        end

        function stateOut = getState(this)
            %% Return the State of the Presently Selected Output 
            %will return true if 'ON' is returned--otherwise this function
            %will return false.
            stateOut = strcmpi(this.read('OUTP?;\n'),'ON');
        end
    end
end
