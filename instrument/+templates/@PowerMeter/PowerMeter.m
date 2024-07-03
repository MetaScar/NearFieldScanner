classdef PowerMeter < handle
    %POWERMETER This is a abstract template class for all power meters
    %   The purpose of this class is to define a uniform framework for all
    %   power meters included in this workspace. The following
    %   components are assumed to be common amongst all powermeters:
    %   ATTRIBUTES: 
    %    Channels       - Power meters may have multiple channels
    %    TriggerSource  - Source that will trigger the calibration 
    %    NumOfAverages  - Number of averages that a meter will take
    %    Frequency      - Frequency of the power meter's signal
    %   METHODS: 
    %    Calibration    - Power meters must be calibrated before use 
    %    Measure        - All meters must measure a given input signal
    %    Initialize     - A general routine for initializing the power
    %                     meter
    
    properties(Access=protected,Abstract)
        %These are properties that must be defined by the subclass
        %Defaults for the specified meter
        DEFAULT_FREQ
        DEFAULT_TRIG_SOURCE
        DEFAULT_NUM_OF_AVERAGES

        %Properties of the meter
        NUM_CHANNELS
        FreqMin
        FreqMax
        NOAMin
        NOAMax
        

        %Lists of Valid Inputs
        VALID_TRIG_SOURCE %cell array of valid trigger source types for the instrument
    end

    properties
        
    end
    
    methods
        function this = PowerMeter(varargin)
            %POWERMETER Construct an instance of this class
            %   This class definition will call the initialize function at
            %   the end so make sure that the constructor for the
            %   communication class has been called first

            %build the argument parser 
            p = inputParser;        %for parsing the input flow of this class
            p.KeepUnmatched = true; %allow for arguments that don't match

            %add the arguments for this class 
            addParameter(p,'Frequency',this.DEFAULT_FREQ,...
                @(x) this.FrequencyIsValid(x));
            addParameter(p,'TrigSource',this.DEFAULT_TRIG_SOURCE,...
                @(x) this.TrigSourceIsValid(x)); 
            addParameter(p,'Averages',this.DEFAULT_NUM_OF_AVERAGES,...
                @(x) this.NumOfAveragesIsValid(x));

            %parse the input arguments 
            parse(p,varargin{:}); 

            %now assign the outputs 
            this.frequency(p.Results.Frequency); 
            this.averages(p.Results.Averages); 
            this.triggersource(p.Results.TrigSource); 

            %now run the initialization procedure 
            this.initialize; 
        end
        
        %instrument access methods (High Level)
        function valOut = frequency(this,valIn)
            %% Function for Setting or Getting Frequency
            %  If a return value is requested then the frequency of the
            %  instrument will be queried and returned. If valIn is
            %  specified then the new frequency (in the default Units) will
            %  be checked and passed on to the instrument 
            
            %if the user is trying to set a new frequency value 
            if exist('valIn','var')
                assert(this.FrequencyIsValid(valIn),...
                    'Provided frequency is not valid.')
                %if we passed the check set the new frequency 
                this.setFrequency(valIn);
            end

            %if the user is requesting the frequency
            if nargout == 1
                valOut = this.getFrequency(); 
            end
        end    
        function valOut = averages(this,valIn)
            %% Function for Setting or Getting Averages
            %  If a return value is requested then the averages of the
            %  instrument will be queried and returned. If input value is
            %  specified the function will check the input and then set the
            %  instrument. If valout is specified then the number of
            %  averages will be queried from the instrument. 
            if exist('valIn','var')
                if isnumeric(valIn)
                    assert(this.NumOfAveragesIsValid(valIn),...
                        'Provided number of averages is not valid.')
                    %if we passed the check set the new frequency 
                    this.setAverages(valIn);
                elseif strcmpi(valIn,'on') || strcmpi(valIn,'off')
                    
                end
            end

            %if the user is requesting the number of averages
            if nargout == 1
                valOut = this.getAverages(); 
            end
        end
        function valOut = averagingMode(this,valIn)
            %% Function for Setting the Averaging Mode
            %  If a return value is requested then the averaging mode of 
            %  the instrument will be queried and returned. If input value 
            %  is specified the function will check the input and then set 
            %  the instrument. If valout is specified then the number of
            %  averages will be queried from the instrument. 

            %if user input argument provided set the averaging mode
            if exist('valIn','var') 
                this.setAveragingMode(valIn); 
            end

            %if the user is trying to get the averaging mode 
            if nargout == 1
                valOut = this.getAveragingMode(); 
            end
        end
        function valOut = triggersource(this,valIn)
            %% Function for Setting or Getting Trigger Source
            %  If a return value is requested then the trigger of the
            %  instrument will be queried and returned. If input value is
            %  specified the function will check the input and then set the
            %  instrument. If valout is specified then the number of
            %  averages will be queried from the instrument. 
            %if the user is trying to set a new frequency value 
            if exist('valIn','var')
                assert(this.TrigSourceIsValied(valIn),...
                    'Provided trigger source is not valid.')
                %if we passed the check set the new frequency 
                this.setTriggerSource(valIn);
            end

            %if the user is requesting the frequency
            if nargout == 1
                valOut = this.getTriggerSource(); 
            end
        end
    end

    methods(Access=protected)
        function tf = FrequencyIsValid(this,freqIn)
            %Checks if number of channels argument is valid.
            tf = isnumeric(freqIn) && ...
                 length(freqIn)==1 && ...
                 freqIn >= this.FreqMin && ...
                 freqIn <= this.FreqMax;
        end

        function tf = TrigSourceIsValied(this,tsIn)
            %Checks if the provided trigger source is valid 
            tf = any(strcmp(tsIn,this.VALID_TRIG_SOURCE)); 
        end

        function tf = NumOfAveragesIsValid(this,noaIn)
            %Checks if the number of averages is valid
            tf = isnumeric(noaIn) && ...
                 length(noaIn)==1 && ...
                 noaIn   >= this.NOAMin && ...
                 noaIn   <= this.NOAMax;
        end
    end
    
    %Define abstract access methods for all power meters 
    methods(Abstract)
        result = measure(this)
        calibrate(this)
        zero(this)
    end
    
    %interfaces with instrument must be defined on a case-by-case basis
    methods(Access=protected,Abstract)
        %methods for initializing and shutting down the meter
        initialize(this)
        shutdown(this)
        %setter and getter for averages property
        setAverages(this,noaIn)
        result = getAverages(this)
        %setter and getter for averaging mode property
        setAveragingMode(this,modeIn)
        result = getAveragingMode(this)
        %setter and getter for frequency property
        setFrequency(this,freqIn)
        result = getFrequency(this)
        %setter and getter for the trigger source property 
        setTriggerSource(this,tsIn)
        result = getTriggerSource(this)
    end

end
