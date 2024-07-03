classdef PowerMeter2 < templates.BaseInstrument2 &...
                       templates.Abstract.ChannelAbstraction
    %POWERMETER This is a abstract template class for all power meters
    %   This is an updated form of the Power Meter class that will subclass
    %   the base instrument and channel abstraction superclasses. This is
    %   intended as a long-term replacement for the PowerMeter class --
    %   even in the cases where only a single channel is used. 
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
        DEFAULT_POWER_SUFFIX;
        DEFAULT_AVERAGE_MODE;
 

        %Properties of the meter
        FreqMin
        FreqMax
        NOAMin
        NOAMax

        %Lists of Valid Inputs
        VALID_TRIG_SOURCE %cell array of valid trigger source types for the instrument
        
        %% INHERITED ABSTRACT PROPERTIES
        %from Base Instrument Class 
        %name;
        %manufacturer; 

        %from ChannelAbstraction Class
        NUM_CHANNELS; 
    end
    
    methods
        function this = PowerMeter2(varargin)
            %POWERMETER Construct an instance of this class
            %   This constructor will passthrough any unrecognized
            %   arguments to the superclass constructors. The specifically
            %   required arguments for this function are: 

            %Call Superclass Constructors 
            this = this@templates.BaseInstrument2(varargin{:}); 
            this = this@templates.Abstract.ChannelAbstraction(varargin{:}); 
        end
        
        %instrument access methods (High Level)
        function valOut = frequency(this,chIndex,valIn)
            %% Function for Setting or Getting Frequency
            %  If a return value is requested then the frequency of the
            %  instrument will be queried and returned. If valIn is
            %  specified then the new frequency (in the default Units) will
            %  be checked and passed on to the instrument 
            

            %if chIndex & valIn - User is specifying channel index & value
            %if valIn and NCHANNELS == 1 - User is specifying valin for
            %   only channel
            %if chIndex & NCHANNELS ~= 1 - User is requesting value of
            %   channel at chIndex
            %if none - User is requesting the value of the first channel

            %the purpose of this function is to determine if the user is
            %attempting to set or get a specific channel value 
            

            %if the user is trying to set a new frequency value 
            if exist('valIn','var')
                assert(this.FrequencyIsValid(valIn),...
                    'Provided frequency is not valid.')
                %if we passed the check set the new frequency 
                this.setFrequency(chIndex,valIn);
            end

            %if the user is requesting the frequency
            if nargout == 1
                valOut = this.getFrequency(chIndex); 
            end
        end    
        function valOut = averages(this,chIndex,valIn)
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
                    this.setAverages(chIndex,valIn);
                elseif strcmpi(valIn,'on') || strcmpi(valIn,'off')
                    
                end
            end

            %if the user is requesting the number of averages
            if nargout == 1
                valOut = this.getAverages(chIndex); 
            end
        end
        function valOut = averagingMode(this,chIndex,valIn)
            %% Function for Setting the Averaging Mode
            %  If a return value is requested then the averaging mode of 
            %  the instrument will be queried and returned. If input value 
            %  is specified the function will check the input and then set 
            %  the instrument. If valout is specified then the number of
            %  averages will be queried from the instrument. 

            %if user input argument provided set the averaging mode
            if exist('valIn','var') 
                this.setAveragingMode(chIndex,valIn); 
            end

            %if the user is trying to get the averaging mode 
            if nargout == 1
                valOut = this.getAveragingMode(chIndex); 
            end
        end
        function valOut = triggersource(this,chIndex,valIn)
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
                this.setTriggerSource(chIndex,valIn);
            end

            %if the user is requesting the frequency
            if nargout == 1
                valOut = this.getTriggerSource(chIndex); 
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
