classdef O_54750A < handle
    % Author: Joel P Johnson
    % Desciption: Creates a wrapper class to access the 54750A Oscilloscope
    % Prerequisites:    Keysight Connection Expert (tested with 2023)
    %                   Keysight IVI drivers for the PNA (tested with
    %                       IVI driver for Agilent Network Analyzers,
    %                       1.2.3.0, 32/64-bit, IVI-C/IVI-COM)
    % To-Do:    Figure out how to display a certain channel
    %           Remove %#ok<SPERR>

    properties(Access=public)
        address
        visaObj
        selectedChannel = 1;
    end
    properties(Access=private)
        minPower = -25; % True min is -87
        maxPower = 0; % True max is 20
    end
    
    methods
        function this = O_54750A(Address, varargin)
            p = inputParser();
            addParameter(p, 'Address', 'GPIB', @isstring);
            parse(p, Address, varargin{:});
            this.address = p.Results.Address;
            this.initialize();
        end
    end

    methods(Access = public)
        function set(this, varargin)
            %% Possible name and value pairs
            % "Channel" - 1 (numeric)(Notes if any.)

            %% Parse input arguments
            p = inputParser(); 
            addParameter(p,'Channel',[]);
            parse(p,varargin{:});

            %% Selecting Channel
            if not(isempty(p.Results.Channel))
                if ~isnumeric(p.Results.Channel)
                    error("Channel number must be a number");
                end
                this.selectedChannel = p.Results.Channel;
                this.selectChannel(this.selectedChannel);
            end

        end

        function data = get(this, varargin)
            %% Possible name and value pairs
            % "Trace" - "" (string)(dummy)
            % "Channel" - 1 (numeric)(Channel number for trace)
            % Only one parameter at a time

            %% Parse input arguments
            p = inputParser(); 
            addParameter(p,'Trace',[]);
            addParameter(p,'Channel',[]);
            parse(p,varargin{:});

            if not(isempty(p.Results.Trace))
                if not(isempty(p.Results.Channel)) ...
                        && p.Results.Channel ~= this.selectedChannel
                    if not(isnumeric(p.Results.Channel))
                        error("Channel number must be a number");
                    end
                    this.connect();
                    origChannel = this.selectedChannel;
                    this.selectChannel(p.Results.Channel);
                    data = this.getTrace(p.Results.Trace);
                    this.selectChannel(origChannel);
                    this.disconnect();
                else
                    this.connect();
                    data = this.getTrace();
                    this.disconnect();
                end
                return;
            end
        end

        function this = giveMeAccess(this)
            % A testing function
            this.connect();
            x = 0;
            this.disconnect();
        end
    end

    methods(Access=private)
        function this = initialize(this)
            this.connect();

            % Make sure it is connected to the right instrument
            id = this.sendAndRead("*IDN?");
            id = strsplit(id,',');
            if ~(strcmpi(id(1), 'HEWLETT-PACKARD') ...
                   && strcmpi(id(2), '54750A'))
                this.disconnect();
                error(sprintf("Please check the address for 54750A. "...
                    + "%s is either incorrect address for HEWLETT-"...
                    + "PACKARD 54750A oscilloscope or the same address "...
                    +"is shared between two instruments.", this.address)); %#ok<SPERR>
            end

            this.disconnect();
        end

        function this = setView(this)
            this.connect();
            % Add functionality where it finds all windows and then deletes
            % all windows.
            this.send()
            this.disconnect();
        end

        function this = setAverageCount(this, count)
            this.averageCount = count;
            this.connect();
            this.sendAndWait("SENS:AVER:COUN " + num2str(count));
            this.disconnect();
        end

        function trace = getTrace(this)
            this.connect();
            this.send("SING")
            d = this.sendAndRead("WAV:DATA?");
            d = strsplit(d, ',');
            d = str2double(d);
            xdataFirst = str2double(this.sendAndRead("WAV:XOR?"));
            xdataRange = str2double(this.sendAndRead("WAV:XRAN?"));
            xdataStep = str2double(this.sendAndRead("WAV:XINC?"));
            x = xdataFirst + xdataStep*(0:(-1+xdataRange/xdataStep));
            trace.voltage = d';
            trace.time = x';
            this.disconnect();
        end

        function setTimeStart(this, t)
            if not(isnumeric(t))
                error("Time position must be number");
            end
            this.connect();
            this.sendAndWait("TIM:POS " + num2str(t));
            this.disconnect();
        end

         function t = getTimeStart(this)
            this.connect();
            t = str2double(this.sendAndRead("TIM:POS?"));
            this.disconnect();
         end

         function setTimeRange(this, t)
            if not(isnumeric(t))
                error("Time range must be number");
            end
            this.connect();
            this.sendAndWait("TIM:RANG " + num2str(t));
            this.disconnect();
         end

         function t = getTimeRange(this)
            this.connect();
            t = str2double(this.sendAndRead("TIM:RANG?"));
            this.disconnect();
         end

         function t = getTimeStep(this)
            this.connect();
            t = str2double(this.sendAndRead("TIM:XINC?"));
            this.disconnect();
         end

        function selectChannel(this, channelNumber)
            this.connect();
            % Does nothing for now. Fix later.
            this.sendAndWait("DISP:ASS CHAN" + num2str(channelNumber) + ",UPP");
            this.disconnect();
        end

        function this = connect(this)
            try
                if strcmpi(class(this.visaObj), 'visalib.GPIB')
                    return
                else
                    this.visaObj = [visadev(this.address)];
                end
            catch ME
                if strcmpi(ME.identifier, 'instrument:interface:visa:unableToDetermineInterfaceType')
                    ME2 = MException('instrument:interface:visa:unableToDetermineInterfaceType', ...
                        sprintf("Could not connect to the E8364C PNA\n"));
                    throw(ME2);
                end
            end
        end

        function this = disconnect(this)
            this.visaObj = [];
        end

        function send(this, command)
            if ~isempty(this.visaObj)
                writeline(this.visaObj,command);
            else
                error("Device not connected");
            end
        end

        function this = sendAndWait(this, command)
            if ~isempty(this.visaObj)
                writeread(this.visaObj,command + ";*OPC?");
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