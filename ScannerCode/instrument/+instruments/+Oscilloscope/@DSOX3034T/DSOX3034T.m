classdef DSOX3034T < handle
    % Authors: Joel P Johnson and Jacob Stewart
    % Desciption: Creates a wrapper class to access the DSO-X 3034T Oscilloscope
    % Prerequisites:    Keysight Connection Expert (tested with 2023)
    %                   Keysight IVI drivers for the Oscilloscope (tested with
    %                       IVI driver for Agilent Network Analyzers,
    %                       1.2.3.0, 32/64-bit, IVI-C/IVI-COM)
    % To-Do:      Remove 'Traces' parameters and intepret channels as array
    %           to allow multiple channels to be measured. 
    %             Figure out how to display a certain channel
    %             Remove %#ok<SPERR>
    %             Fix getTrace to function on 

    properties(Access=public)
        address
        visaObj
        selectedChannel = 1;
        points = 62500; % default is max* number of points for Normal mode
    end
    properties(Access=private)
        minPower = -25; % True min is -87
        maxPower = 0; % True max is 20
    end
    
    methods
        function this = DSOX3034T(Address, varargin)
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
            % "Points" - 62500 (numeric)(Notes if any.)

            %% Parse input arguments
            p = inputParser(); 
            addParameter(p,'Channel',[]);
            addParameter(p, 'Points', []);
            parse(p,varargin{:});

            %% Selecting Channel
            if not(isempty(p.Results.Channel))
                if ~isnumeric(p.Results.Channel)
                    error("Channel number must be a number");
                end
                this.selectedChannel = p.Results.Channel;
                this.selectChannel(this.selectedChannel);
            end

            %% Seting number of points
            if not(isempty(p.Results.Points))
                if ~isnumeric(p.Results.Points)
                    error("Points must be a number");
                end
                this.points = p.Results.Points;
                this.setPoints(this.points);
            end


        end

        function data = get(this, varargin)
            %% Possible name and value pairs
            % "Trace" - "" (string)(dummy)
            % "Traces" - "" (string)(dummy) Will only get data from channels 1 and 2
            % "Channel" - 1 (numeric)(Channel number for trace)
            % Only one parameter at a time

            %% Parse input arguments
            p = inputParser(); 
            addParameter(p,'Trace',[]);
            addParameter(p,'Traces',[]);
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
                    data = this.getFastTrace(p.Results.Trace);
                    this.selectChannel(origChannel);
                    this.disconnect();
                else
                    this.connect();
                    data = this.getFastTrace();
                    this.disconnect();
                end
                return;
            end
            if not(isempty(p.Results.Traces))
                this.connect();
                data = this.getChannels12();
                this.disconnect();
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
            if ~(strcmpi(id(1), 'KEYSIGHT TECHNOLOGIES') ...
                   && strcmpi(id(2), 'DSO-X 3034T'))
                this.disconnect();
                error(sprintf("Please check the address for 54750A. "...
                    + "%s is either incorrect address for KEYSIGHT "...
                    + "TECHNOLOGIES DSO-X 3034T oscilloscope or the same address "...
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
            % WARNING: Function does not function for DSOX3034T
            % Oscilloscope. Should use getFastTrace unless you need ASCii
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

        function traces = getChannels12(this)
            this.connect();
            this.send("SING");
            preamble = this.sendAndRead(":WAV:PRE?");
            preamble = str2double(strsplit(preamble, ","));
            format = preamble(1); % 0 for Byte, 1 for Word, 4 for ASCii
            % type = preamble(2); % 3 for HRESolutions, 2 for Average, 0 for Normal
            pre_points = preamble(3); % Number of data points
            % count = preamble(4); % number of values averaged
            xincrement = preamble(5); 
            xorigin = preamble(6);
            xref = preamble(7);
            yincrement = preamble(8);
            yorigin = preamble(9);
            yref = preamble(10);

            time_points = 0:(pre_points-1);
            traces.time = ((time_points - xref) .* xincrement) + xorigin;

            % make sure data format is byte
            if (format ~= 0)
                this.send(":WAV:FORM BYTE");
            end

            this.sendAndWait(":WAV:SOUR CHAN1");
            this.send(":WAV:DATA?");
            data = readbinblock(this.visaObj);
            traces.voltage1 = ((data - yref) .* yincrement) + yorigin;
            this.sendAndWait(":WAV:SOUR CHAN2");
            this.send(":WAV:DATA?");
            data = readbinblock(this.visaObj);
            traces.voltage2 = ((data - yref) .* yincrement) + yorigin;


            % reset 
            this.sendAndWait(":WAV:SOUR CHAN" +  num2str(this.selectedChannel));
            % switch format to original
            switch format
                case 0
                    % do nothing; already in byte
                case 1
                    this.send(":WAV:FORM WORD");
                case 4
                    this.send(":WAVE:FORM ASC");
                otherwise
                    error("Unexpected format detected! Check on getChannels12 function.");
            end
            this.disconnect();

        end

        function trace = getFastTrace(this)
            this.connect();
            this.send("SING");
            preamble = this.sendAndRead(":WAV:PRE?");
            preamble = str2double(strsplit(preamble, ","));
            format = preamble(1); % 0 for Byte, 1 for Word, 4 for ASCii
            % type = preamble(2); % 3 for HRESolutions, 2 for Average, 0 for Normal
            pre_points = preamble(3); % Number of data points
            % count = preamble(4); % number of values averaged
            xincrement = preamble(5); 
            xorigin = preamble(6);
            xref = preamble(7);
            yincrement = preamble(8);
            yorigin = preamble(9);
            yref = preamble(10);

            time_points = 0:(pre_points-1);
            trace.time = ((time_points - xref) .* xincrement) + xorigin;

            % make sure data format is byte
            if (format ~= 0)
                this.send(":WAV:FORM BYTE");
            end

            this.send(":WAV:DATA?");
            data = readbinblock(this.visaObj);
            trace.voltage = ((data - yref) .* yincrement) + yorigin;

            % switch format to original
            switch format
                case 0
                    % do nothing; already in byte
                case 1
                    this.send(":WAV:FORM WORD");
                case 4
                    this.send(":WAV:FORM ASC");
                otherwise
                    error("Unexpected format detected! Check on getFastTrace function.");
            end
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
            % Might do something; untested
            if(channelNumber < 1 || channelNumber > 4)
                error(sprintf("The selected channel is not an available channel " + ...
                    "for the DSO-X 3034T Oscilloscope. " + ...
                    "Please choose a channel in the range of 1-4."));
            end
            this.sendAndWait(":WAV:SOUR CHAN" + num2str(channelNumber));
            this.disconnect();
        end

        function setPoints(this, points)
            this.connect();
            this.sendAndWait(":WAV:POIN " + num2str(points));
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
                        sprintf("Could not connect to the DSO-X 3034T Oscilloscope\n"));
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