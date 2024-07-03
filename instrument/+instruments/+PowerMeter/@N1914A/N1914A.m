classdef N1914A < templates.PowerMeter2 & ...
                  io.VisaInstr
    %N1914A This is a dual-channel power meter that is compatible with all
    %N8480, 8480, and E-Series (except the E9320 family) power sensors,
    %U2000/U8480 Series and U2050 X-Series USB power sensors provide
    %average power measurements from -70 to + 44dBm, DC to 120 GHz
    %   Detailed explanation goes here
    
    %% Initialize Abstract and Protected Properties 
    properties(Access=protected)
        name                        = 'N1914A';                             % defined in templates.BaseInstrument2
        manufacturer                = 'Keysight';                           
        %Power Meter Abstract Properties
        DEFAULT_FREQ                = 1;                                    % defined in templates.PowerMeter
        DEFAULT_TRIG_SOURCE         = 'IMM'; 
        DEFAULT_NUM_OF_AVERAGES     = 32; 
        DEFAULT_FREQ_SUFFIX         = 'GHz';
        DEFAULT_POWER_SUFFIX        = 'DBM';
        DEFAULT_AVERAGE_MODE        = 'AUTO';                               
        FreqMin                     = 0; 	                                
        FreqMax          	        = 120;                                  
        NOAMin           	        = 0;                                    
        NOAMax           	        = 1024;                                 
        VALID_TRIG_SOURCE	        = {'BUS','EXT','HOLD','IMM'};           
        NUM_CHANNELS                = 4;                                    % defined in templates.Abstract.ChannelAbstraction
        COMM_NUM_RETRY              = 3;                                    % defined in io.VisaInstr
        COMM_DEBUG                  = false                                 
    end

    properties
        %none yet
    end
    
    methods
        function this = N1914A(varargin)
            %N1914A Construct an instance of this class
            %   Detailed explanation goes here
            
            %initialize the input parser 
            p = inputParser(); 
            p.KeepUnmatched = true;

            %add optional arguments
            addParameter(p,'Address',''); 

            %parse the input arguments 
            parse(p,varargin{:}); 

            %call power meter constructor
            this = this@templates.PowerMeter2(varargin{:}); 
            
            %setup and connect to the instrument 
            this = this@io.VisaInstr('Keysight',p.Results.Address,...
                                     'visaInputBufferSize', 20000,...
                                     'visaTimeout',60,varargin{:}); 
            
            %initialize the power meter 
            this.initialize(varargin{:}); 
        end

        function valOut = measure(this,chNum,varargin)
            %% MEASURE - Performs a simple measurement from the power meter 
            
            %make a new input parser
            p = inputParser; 

            %add arguments
            addParameter(p,'ExpectedPower','DEF');
            addParameter(p,'ExpectedPowerUnit',this.DEFAULT_POWER_SUFFIX);
            addParameter(p,'Resolution','DEF'); 
            addParameter(p,'WindowNum',1,@(x) any(x==[1,2]));

            %parse input parameters
            parse(p,varargin{:}); 

            %now build the expected power string
            if not(isequal(p.Results.ExpectedPower,'DEF'))
                pwrStr = [num2str(p.Results.ExpectedPower) ...
                                upper(p.ExpectedPowerUnit)];
            else
                pwrStr = 'DEF'; 
            end

            %build the expected resolution string 
            if not(isequal(p.Results.Resolution,'DEF'))
                resStr = num2str(p.Results.Resolution);
            else
                resStr = 'DEF';
            end

            %now send the command 
            valOut = this.read('MEAS%d:POW:AC? %s,%s,(@%d)', ...
                         p.Results.WindowNum,pwrStr,resStr,chNum);
            %convert character response to a numeric value
            valOut = str2double(valOut); 
        end
        function msgOut = getError(this)
            %% Get Error Message from the Power Meter
            %turn off debug mode temporarily            
            %query the error (it is important that this does not use the
            %read function)
%             msgOut = this.read('SYST:ERR?;\n'); 
%             if strcmp(msgOut,sprintf('+0,"No error"\n'))
%                 msgOut = [];
%             end
            msgOut = this.queryError('SYST:ERR?;\n'); 
            if strcmp(msgOut,sprintf('+0,"No error"\n'))
                msgOut = [];
            end
        end
        function zero(this,chNum)
            %% Zero the Current Channel 
            this.write('CAL%d:ZERO:AUTO ONCE;\n',chNum); 
        end
        function calibrate(this,chNum,type)
            %% Run a Calibration on the Current Channel
            if not(exist("type",'var'))
                type = 'ext';
            end

            %for now, type will not be implemented, just run a standard
            %calibration 
            result = this.read('CAL%d:ALL?;\n',chNum); 
            if result == 0
                this.issueWarning('Calibration was unsuccessful.'); 
                disp(this.getError()); 
            end
        end
    end

    methods(Access=protected)
        function delete(this)
            %% Make Sure to Disconnect the Instrument 
            this.shutdown;
            this.disconnect; 
        end
        %methods for initializing and shutting down the meter
        initialize(this,varargin)
        shutdown(this)
        %setter and getter for averages property
        function setAverages(this,chNum,noaIn)
            %% Set the Averages for the Meter
            if noaIn
                %turn averaging on 
                this.write('SENS%d:AVER:STAT ON;\n',chNum,valIn); 
                %set the number of averages to the value indicated
                this.write('SENS%d:AVER:COUN %d;\n',chNum,valIn); 
            else
                %turn averagin off 
                this.write('SENS%d:AVER:COUN %d;\n',chNum,noaIn); 
            end
        end
        function result = getAverages(this,chNum)
            %% Get the Number of Averages for a Given Channel
            if str2double(this.read('SENS%d:AVER:STAT?;\n',chNum))
                result = str2num(this.read('SENS%d:AVER:COUN?;\n',chNum));
            else
                result = 0; 
            end
        end
        %setter and getter for averaging mode property
        function setAveragingMode(this,chNum,modeIn)
            %% Set Averaging Mode for Channel
            switch lower(modeIn)
                case 'manual'
                    this.write('SENS%d:AVER:COUN:AUTO OFF;\n',chNum);
                case 'auto'
                    this.write('SENS%d:AVER:COUN:AUTO ON;\n',chNum);
                otherwise 
                    warning(['Mode %s unrecognized. ' ...
                        'Averaging mode not set.'],modeIn); 
            end

        end
        function result = getAveragingMode(this,chNum)
            %% Get Averaging Mode for Channel
            %get the response from power meter
            isAuto = str2double(this.read('SENS%d:AVER:COUN:AUTO?',chNum)); 
            %format the response for the user
            if isAuto
                result = 'AUTO'; 
            else
                result = 'MANUAL';
            end
        end
        %setter and getter for frequency property
        function setFrequency(this,chNum,freqIn)
            %% Set Channel Frequency
            % warning('setFrequency Not Implemented Yet'); 
            this.write(['SENS%d:FREQ ' num2str(freqIn) ' ' ...
                this.DEFAULT_FREQ_SUFFIX ';\n'],chNum); 
        end
        function result = getFrequency(this,chNum)
            %% Get Channel Frequency
            % warning('getFrequency Not Implemented Yet'); 
            result = str2double(this.read('SENS%d:FREQ?;\n',chNum)); 
        end
        %setter and getter for the trigger source property 
        function setTriggerSource(this,chNum,tsIn)
            %% Set Channel Trigger Source
            % warning('setTriggerSource Not Implemented Yet'); 
            this.write('TRIG%d:SOUR %s;\n',chNum,tsIn);
        end
        function result = getTriggerSource(this,chNum)
            %% Get Channel Trigger Source
            % warning('getTriggerSource Not Implemented Yet'); 
            result = this.read('TRIG%d:SOUR?;\n',chNum); 
        end
    end
end

