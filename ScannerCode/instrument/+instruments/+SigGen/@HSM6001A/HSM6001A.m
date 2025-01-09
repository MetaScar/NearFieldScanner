classdef HSM6001A < handle
    % Author:           Joel P Johnson
    % Desciption:       Creates a wrapper class to access the HSM6001A 
    %                   RF Synthesizer
    % Prerequisites:    Keysight Connection Expert (tested with 2023)
    %                   Keysight IVI drivers for the PNA (tested with
    %                   IVI driver for Agilent Network Analyzers,
    %                   1.2.3.0, 32/64-bit, IVI-C/IVI-COM)
    % To-Do:            Verify ability to set port number
    %           

    properties(Access=public)
        address
        visaObj
    end
    properties(Access=private)
        connectionCount = 0;
        connected = false;
        minFreq = 0.25e6;
        maxFreq = 6e9;
        minPower = -25; % True min is -87
        maxPower = 0; % True max is 20
    end
    
    methods
        function this = HSM6001A(Address, varargin)
            p = inputParser();
            addParameter(p, 'Address', 'GPIB', @isstring);
            addParameter(p, 'Port_Number', 9760, @isnumeric);
            parse(p, Address, varargin{:});
            this.address = p.Results.Address;
            this.portNumber = p.Results.portNumber;
            this.initialize();
        end
    end

    methods(Access = public)
        function set(this, varargin)
            %% Possible name and value pairs
            % "Freq" -  1e9 (numeric)[Hz]
            %           Output frequency.
            % "Power" - -5 (numeric)[dBm]
            %           Output power.
            % "State" - 1 (numeric)[dBm]
            %           Enable or disable state.

            %% Parse input arguments
            p = inputParser(); 
            addParameter(p,'Freq',[]);
            addParameter(p,'Power',[]);
            addParameter(p,'State',[]);
            parse(p,varargin{:});

            %% Setting Output Frequency
            if not(isempty(p.Results.Freq))
                this.setOutputFreq(p.Results.Freq);
            end

            %% Setting Output Power
            if not(isempty(p.Results.Power))
                this.setOutputPower(p.Results.Power);
            end

            %% Setting State
            if not(isempty(p.Results.State))
                if strcmpi(p.Results.State, "OFF")
                    this.turnOff;
                elseif strcmpi(p.Results.State, "ON")
                    this.turnOn;
                else
                    error("Invalid state for HSM6001A.");
                end
            end

        end

        function data = get(this, varargin)
            %% Possible name and value pairs
            % "Min_Freq" -  ""(string)(dummy)
            %               Minimum settable frequency.
            % "Max_Freq" - ""(string)(dummy)
            %               Maximum settable frequency.
            % "Out_Freq" - ""(string)(dummy)
            %               Currently set output frequency.
            % "Min_Power" -  ""(string)(dummy)
            %               Minimum settable power.
            % "Max_Power" - ""(string)(dummy)
            %               Maximum settable power.
            % "Out_Power" - ""(string)(dummy)
            %               Currently set output power.
            % Only one measurement at a time

            %% Parse input arguments
            p = inputParser(); 
            addParameter(p,'Min_Freq',[]);
            addParameter(p,'Out_Freq',[]);
            addParameter(p,'Max_Freq',[]);
            addParameter(p,'Min_Power',[]);
            addParameter(p,'Out_Power',[]);
            addParameter(p,'Max_Power',[]);
            parse(p,varargin{:});

            %% Getting Min Frequency
            if not(isempty(p.Results.Min_Freq))
                data = this.getMinFreq();
                return;
            end

            %% Getting Output Frequency
            if not(isempty(p.Results.Out_Freq))
                data = this.getOutputFreq();
                return;
            end

            %% Getting Max Frequency
            if not(isempty(p.Results.Max_Freq))
                data = this.getMaxFreq();
                return;
            end

            %% Getting Min Power
            if not(isempty(p.Results.Min_Power))
                data = this.getMinPower();
                return;
            end

            %% Getting Output Power
            if not(isempty(p.Results.Out_Power))
                data = this.getOutputPower();
                return;
            end

            %% Getting Max Power
            if not(isempty(p.Results.Max_Power))
                data = this.getMaxPower();
                return;
            end
        end

        function this = giveMeAccess(this)

            % A testing function
            this.connect();
            s = "Exiting giveMeAccess Mode.";
            disp(s);
            this.disconnect();
        end

    end

    methods(Access=private)
        function this = initialize(this)
            this.connect;
            % Make sure it is connected to the right instrument
            id = this.sendAndRead(":IDN?");
            id = strsplit(id,',');
            if ~(strcmpi(strtrim(id(1)), 'Holzworth') ...
                   && strcmpi(strtrim(id(2)), 'HSM6001A'))
                this.disconnect;
                error("Please check the address for HSM6001A. "...
                    + "%s is either incorrect address for Holzworth "...
                    + "Instrumentation HSM6001A oscilloscope or the "...
                    + "same address is shared between two instruments.",...
                    this.address);
            end
            this.minFreq = this.getMinFreq;
            this.maxFreq = this.getMaxFreq;
            this.minPower = this.getMinPower;
            this.maxPower = this.getMaxPower;
            this.disconnect;
        end

        function turnOn(this)
            this.connect;
            this.send(":PWR:RF:ON");
            this.disconnect;
        end

        function turnOff(this)
            this.connect;
            this.send(":PWR:RF:OFF");
            this.disconnect;
        end

        function f = getMaxFreq(this)
            this.connect;
            f = this.sendAndRead(":FREQ:MAX?");
            f = this.convFromScientificForm(f, "Hz");
            this.disconnect;
        end

        function f = getOutputFreq(this)
            this.connect;
            f = this.sendAndRead(":FREQ?");
            f = this.convFromScientificForm(f, "Hz");
            this.disconnect;
        end

        function f = getMinFreq(this)
            this.connect;
            f = this.sendAndRead(":FREQ:MIN?");
            f = this.convFromScientificForm(f, "Hz");
            this.disconnect;
        end

        function f = getMaxPower(this)
            this.connect;
            f = this.sendAndRead(":PWR:MAX?");
            f = this.convFromScientificForm(f, "dBm");
            this.disconnect;
        end

        function f = getOutputPower(this)
            this.connect;
            f = this.sendAndRead(":PWR?");
            f = str2double(f);
            this.disconnect;
        end

        function f = getMinPower(this)
            this.connect;
            f = this.sendAndRead(":PWR:MIN?");
            f = this.convFromScientificForm(f, "dBm");
            this.disconnect;
        end

        function setOutputFreq(this, f)
            this.connect;
            f = this.getIntoScientificForm(this.keepFreqInLimit(f), "Hz");
            this.send(":FREQ:"+f);
            this.disconnect;
        end

        function setOutputPower(this, pow)
            this.connect;
            pow = this.getIntoScientificForm(this.keepPowerInLimit(pow), "dBm");
            this.send(":PWR:"+pow);
            this.disconnect;
        end
      
        function setReference(this, mode, freq)
            this.connect;
            if strcmpi(mode, "INT") || strcmpi(mode, "internal")
                this.send(":REF:INT");
            elseif strcmpi(mode, "EXT") || strcmpi(mode, "external")
                if freq == 10e6
                    this.send(":REF:EXT:10MHZ");
                elseif freq == 100e6
                    this.send(":REF:EXT:100MHZ");
                else
                    error("Invalid external reference frequency.");
                end
            else
                error("Invalid reference.");
            end
            this.disconnect;
        end

        function num = convFromScientificForm(~, text, unit)
            % Split and precision digits
            splitPieces = strsplit(text," ");
        
            % Error checks
            if isscalar(splitPieces) || abs(length(splitPieces{2})-strlength(unit))>1
                error("Incorrect unit.");
            elseif ~strcmpi(splitPieces{2}(1+length(splitPieces{2})-strlength(unit):end),unit)
                error("Incorrect data unit.");
            end
            
            % Find Value
            mult = splitPieces{2}(1);
            switch (mult)
                case"f"
                    mult = -15;
                case "p"
                    mult = -12;
                case "n"
                    mult = -9;
                case "u"
                    mult = -6;
                case "m"
                    mult = -3;
                case ""
                    mult = 0;
                case "K"
                    mult = 3;
                case "M"
                    mult = 6;
                case "G"
                    mult = 9;
                otherwise
                    mult = 0;
            end
            num = str2double(splitPieces{1}) * 10^mult;
        end

        function text = getIntoScientificForm(~, num, unit)
            if num == 0
                text = "0" + unit;
                return;
            end
            t = 3*floor(floor(log10(num))/3);
            switch (t)
                case -15
                    text = "f";
                case -12
                    text = "p";
                case -9
                    text = "n";
                case -6
                    text = "u";
                case -3
                    text = "m";
                case 0
                    text = "";
                case 3
                    text = "K";
                case 6
                    text = "M";
                case 9
                    text = "G";
                otherwise
                    text = "";
            end
            text = num2str(num/(10^t)) + text + unit;
        end

        function f = keepFreqInLimit(this, f)
            f = min(f, this.maxFreq);
            f = max(f, this.minFreq);
        end

        function f = keepPowerInLimit(this, f)
            f = min(f, this.maxPower);
            f = max(f, this.minPower);
        end

        function this = connect(this)
            if this.connected == true
                this.connectionCount = this.connectionCount + 1;
                return;
            end
            try
                if strcmpi(class(this.visaObj), 'visalib.GPIB')
                    return
                else
                    this.visaObj = [tcpclient(this.address, 9760)];
                end
            catch ME
                if strcmpi(ME.identifier, 'instrument:interface:visa:unableToDetermineInterfaceType')
                    ME2 = MException('instrument:interface:visa:unableToDetermineInterfaceType', ...
                        sprintf("Could not connect to the E4448A SA\n"));
                    throw(ME2);
                end
            end
            this.connected = true;
            this.connectionCount = this.connectionCount + 1;
        end

        function this = disconnect(this)
            if this.connected == false
                this.connectionCount = 0;
                return;
            end
            if this.connectionCount > 1
                this.connectionCount = this.connectionCount - 1;
                return;
            end
            this.visaObj = [];
            this.connected = false;
        end

        function send(this, command)
            if ~isempty(this.visaObj)
                writeline(this.visaObj,command);
            else
                error("Device not connected");
            end
        end

        function reply = sendAndRead(this, command)
            if ~isempty(this.visaObj)
                reply = writeread(this.visaObj,command);
            else
                error("Device not connected");
            end
        end

        function delete(this)
            this.disconnect();
        end
    end
end