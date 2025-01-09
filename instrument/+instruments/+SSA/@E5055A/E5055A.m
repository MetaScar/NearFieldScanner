classdef E5055A < handle
    % Author:           Joel P Johnson
    % Desciption:       Creates a wrapper class to access the E5055A 
    %                   SSA
    % Prerequisites:    Keysight Connection Expert (tested with 2023)
    %                   Keysight IVI drivers for the PNA (tested with
    %                   IVI driver for Agilent Network Analyzers,
    %                   1.2.3.0, 32/64-bit, IVI-C/IVI-COM)
    % To-Do:            Add Res_BW functionality
    %                   Make sendAndWait use waitTillOpComplete
    %                   Configure setModeAsNoiseFigure
    %           

    properties(Access=public)
        address
        visaObj
        % selectedChannel = 1;
    end
    properties(Access=private)
        connectionCount = 0;
        averageCount = 3;
        averageStatus = 0;
        mode = "SA"; % VNA & PN & RES & SA & TR & VCO
        connected = false;
        minFreq = 3;
        maxFreq = 8e9;
        minPower = -25; % True min is -87
        maxPower = 0; % True max is 20
        maxSmoothing = 0.25; % Fraction of total data points
        range = "1"; % Frequency range identifier for PN
        meas_ID = "1";
        dc_ID = "VControl";
        sNoise_ID = "1";
    end
    
    methods
        function this = E5055A(Address, varargin)
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
            % "Mode" - "Spectrum Analyzer", "Channel Power", "Phase
            %           Noise", "Residual Phase Noise"(String)(Must be 
            %           mentioned if Trace is expected)
            % "Start_Freq" - 0 (numeric)[Hz]
            % "Center_Freq" - 25e9 (numeric)
            % "Stop_Freq" - 50e9 (numeric)[Hz]
            % "Average" - 3 or "OFF" (numeric or string)(When parameter
            %             is numeric then it is assumed that it is 
            %             average count. If string, it is assumed to be
            %             the state of average.)
            % "Smoothing" - "OFF"(string)(Only valid when phase noise 
            %                mode is active.)
            %               For SA mode, sets span around center frequency.
            % "Correlation_Count" - 1(numeric)
            %                       correlation count number for phase 
            %                       noise measurements.
            % "DC_Supply_ID" - "Control"(string)
            %                   Select the Supply. Options: "Control",
            %                   "Supply 1", "Supply 2"
            % "DC_State" - 1(numeric)
            %              1 - turns on all DC supplies
            %              0 - turns off all DC supplies
            % "DC_LowNoiseMode" - 1(numeric)
            %                     Sets low noise mode for "DC Control" only
            % "Voltage" - 1(numeric)
            %             Sets voltage for the selected supply ID.
            % "SNoise_ID" - 1(numeric)
            %               Sets spot noise ID.
            % "SNoise_Freq" - 1(numeric)
            %               Sets frequency for the selected spot noise ID.
            % "SNoise_ID_State" - 1(numeric)
            %                     Enables or disables the selected spot 
            %                     noise ID.
            % "setSNoise_State" - 1(numeric)
            %                     Enables or disables spot noise
            %                     measurement.

            %% Parse input arguments
            p = inputParser(); 
            addParameter(p,'Start_Freq',[]);
            addParameter(p,'Center_Freq',[]);
            addParameter(p,'Stop_Freq',[]);
            addParameter(p,'Mode',[]);
            addParameter(p,'Average',[]);
            addParameter(p,'Smoothing',[]);
            addParameter(p,'Channel',[]);
            addParameter(p,'Port',[]);
            addParameter(p,'Range',[]);
            addParameter(p,'Meas_ID',[]);
            addParameter(p,'Correlation_Count',[]);
            addParameter(p,'DC_Supply_ID',[]);
            addParameter(p,'DC_State',[]);
            addParameter(p,'DC_LowNoiseMode',[]);
            addParameter(p,'Voltage',[]);
            addParameter(p,'SNoise_ID',[]);
            addParameter(p,'SNoise_Freq',[]);
            addParameter(p,'SNoise_ID_State',[]);
            addParameter(p,'setSNoise_State',[]);
            parse(p,varargin{:});

            %% Connect
            this.connect;
            %% Setting Range
            if not(isempty(p.Results.Range))
                this.range = num2str(p.Results.Range);
            end
            %% Setting Start Frequency
            if not(isempty(p.Results.Start_Freq))
                this.setStartFreq(p.Results.Start_Freq);
                this.waitTillOpComplete();
            end

            %% Setting Center Frequency
            if not(isempty(p.Results.Center_Freq))
                this.setCenterFreq(p.Results.Center_Freq);
                this.waitTillOpComplete();
            end

            %% Setting Stop Frequency
            if not(isempty(p.Results.Stop_Freq))
                this.setStopFreq(p.Results.Stop_Freq);
                this.waitTillOpComplete();
            end

            %% Setting Mode
            if not(isempty(p.Results.Mode))
                switch p.Results.Mode
                    case "Spectrum Analyzer"
                        this.setModeAsSpecAn;
                    case "Phase Noise"
                        this.setModeAsPhaseNoise;
                end
                this.connect;
                this.waitTillOpComplete();
                this.disconnect;
            end

            %% Setting Average
            if not(isempty(p.Results.Average))
                if isstring(p.Results.Average)
                    if strcmpi(p.Results.Average, "OFF")
                        this.setAverage(0);
                    elseif strcmpi(p.Results.Average, "ON")
                        this.setAverage(1);
                    else
                        this.setAverage(0);
                        warning("Incorrect average parameter given. Average turned off!");
                    end
                elseif isnumeric(p.Results.Average)
                        this.setAverageCount(p.Results.Average);
                else
                    error("Average parameter must either be numeric or string.")
                end
                this.waitTillOpComplete();
            end

            %% Setting Smoothing
            if not(isempty(p.Results.Smoothing))
                if strcmpi(p.Results.Smoothing,"OFF")
                    p.Results.Smoothing = 0;
                end
                this.setSmoothing(p.Results.Smoothing);
                this.waitTillOpComplete();
            end

            %% Setting Meas_ID
            if not(isempty(p.Results.Meas_ID))
                this.meas_ID = num2str(p.Results.Meas_ID);
            end

            %% Setting Correlation Count
            if not(isempty(p.Results.Correlation_Count))
                this.setCorrCount(p.Results.Correlation_Count);
                this.waitTillOpComplete;
            end

            %% Setting DC Supply ID
            if not(isempty(p.Results.DC_Supply_ID))
                if strcmpi(p.Results.DC_Supply_ID, "Control")
                    this.dc_ID = "VControl";
                elseif strcmpi(p.Results.DC_Supply_ID, "Supply 1") 
                    this.dc_ID = "VSupply1";
                elseif strcmpi(p.Results.DC_Supply_ID, "Supply 2") 
                    this.dc_ID = "VSupply2";
                else
                    error("Incorrect DC Supply ID.");
                end
            end

            %% Setting DC Status
            if not(isempty(p.Results.DC_State))
                this.setDCMode(p.Results.DC_State);
            end

            %% Setting DC Control Mode
            if not(isempty(p.Results.DC_LowNoiseMode))
                this.setLNO(p.Results.DC_LowNoiseMode);
                if ~strcmpi(this.dc_ID,"VControl")
                    warning("Supply 1 or 2 is currently selected and "+...
                        "low-noise mode is not supported in these "+ ...
                        "outputs. As default, Control supply was set "+...
                        "to low-noise node.");
                end
            end

            %% Setting DC Voltage
            if not(isempty(p.Results.Voltage))
                this.setVoltage(p.Results.Voltage);
            end

            %% Setting SNoise_ID
            if not(isempty(p.Results.SNoise_ID))
                if sNoiseID<0 || sNoiseID>7
                    warning("Spot noise ID is outside limits. "+...
                        "Defaulting to 1");
                    p.Results.SNoise_ID = 1;
                end
                this.sNoise_ID = num2str(p.Results.SNoise_ID);
            end
          
            %% Setting SNoise_Freq
            if not(isempty(p.Results.SNoise_Freq))
                this.setSNoiseFreq(p.Results.SNoise_Freq);
            end

            %% Setting setSNoiseID_State
            if not(isempty(p.Results.SNoise_ID_State))
                this.setSNoiseID_State(p.Results.SNoise_ID_State);
            end

            %% Setting setSNoise_State
            if not(isempty(p.Results.setSNoise_State))
                this.setSNoise_State(p.Results.setSNoise_State);
            end

            %% Disconnect if still connected
            this.waitTillOpComplete;
            this.disconnect;
        end

        function data = get(this, varargin)
            %% Possible name and value pairs
            % "Trace" - "" (string)(dummy)
            %               Here, it return log mag plot.
            % "Start_Freq" - ""(string)(dummy)
            %               Offset start frequency
            % "Stop_Freq" - ""(string)(dummy)
            %               Offset stop frequency
            % "Voltage" - ""(string)(dummy)
            %               Voltage at the DC port.
            % "Current" - ""(string)(dummy)
            %               Current drawn at the DC port.
            % "Spot_Noise" - ""(string)(dummy)
            %               Spot noise of the set spot noise ID.
            % Only one measurement at a time

            %% Parse input arguments
            p = inputParser(); 
            addParameter(p,'Trace',[]);
            addParameter(p,'Start_Freq',[]);
            addParameter(p,'Stop_Freq',[]);
            addParameter(p,'Voltage',[]);
            addParameter(p,'Current',[]);
            addParameter(p,'Spot_Noise',[]);
            parse(p,varargin{:});

            this.waitTillOpComplete(); % JIC
            %% Getting Trace
            if not(isempty(p.Results.Trace))
                data = this.getTrace();
                return;
            end

            %% Getting Start Frequency
            if not(isempty(p.Results.Start_Freq))
                data = this.getStartFreq();
                return;
            end

            %% Getting Stop Frequency
            if not(isempty(p.Results.Stop_Freq))
                data = this.getStopFreq();
                return;
            end

            %% Getting Voltage
            if not(isempty(p.Results.Voltage))
                data = this.getVoltage();
                return;
            end

            %% Getting Current
            if not(isempty(p.Results.Current))
                data = this.getCurrent();
                return;
            end

            %% Getting SNoise data
            if not(isempty(p.Results.Spot_Noise))
                data = this.getSNoise();
                return;
            end
        end

        function this = giveMeAccess(this)
            % A testing function
            this.connect;
            s = "Exiting giveMeAccess Mode.";
            disp(s);
            this.disconnect;
        end
    end

    methods(Access=private)
        function this = initialize(this)
            this.connect;
            % Make sure it is connected to the right instrument
            id = this.sendAndRead("*IDN?");
            id = strsplit(id,',');
            if ~(strcmpi(strtrim(id(1)), 'Keysight Technologies') ...
                   && strcmpi(strtrim(id(2)), 'E5055A'))
                this.disconnect;
                error("Please check the address for E5055A. "...
                    + "%s is either incorrect address for Keysight "...
                    + "Tech. E5055A SSA or the same address "...
                    +"is shared between two instruments.", this.address);
            end
            this.send("CALC:MEAS:DEL:ALL");

            this.send("SYST:DC:ENAB 0");
            this.dc_ID = "VControl";
            this.send("SOUR:DC:OUTP """+this.dc_ID+ """, DEF");
            this.send("SYST:DC:DEF:OUTP:STAT """+this.dc_ID+ """, 1");
            this.set("Voltage",0);
            this.dc_ID = "VSupply1";
            this.send("SOUR:DC:OUTP """+this.dc_ID+ """, DEF");
            this.send("SYST:DC:DEF:OUTP:STAT """+this.dc_ID+ """, 1");
            this.set("Voltage",0);
            this.dc_ID = "VSupply2";
            this.send("SOUR:DC:OUTP """+this.dc_ID+ """, DEF");
            this.send("SYST:DC:DEF:OUTP:STAT """+this.dc_ID+ """, 1");
            this.set("Voltage",0);

            this.disconnect;
        end

        function this = setView(this)
            % this.connect;
            % this.send("TRAC1:MODE WRIT");
            % this.send("TRAC2:MODE BLAN");
            % this.send("TRAC3:MODE BLAN");
            % this.send("INIT:CONT 0");
            % this.send("*CLS");
            % this.disconnect;
        end

        function this = setModeAsSpecAn(this)
            % this.connect;
            % this.send("INST SA");
            % this.waitTillOpComplete();
            % this.send("CONF:SAN");
            % this.waitTillOpComplete();
            % this.mode = "SA";
            % this.send("*CLS");
            % this.disconnect;
        end

        function this = setAverageCount(this, averageCount)
            this.connect;
            switch this.mode
                case "SA"
                    % this.send("AVER:COUN " + num2str(averageCount));
                case "PN"
                    this.send("SENS:AVER:COUN " + num2str(averageCount));
            end
            this.disconnect;
            this.averageCount = averageCount;
            this.send("SENS:SWE:GRO:COUN " ...
                + num2str(this.averageCount));
        end

        function this = setAverage(this, mode)
            this.connect;
            if mode == 0
                switch this.mode
                    case "SA"
                        % this.sendAndWait("AVER 0");
                    case "PN"
                        this.sendAndWait("SENS:AVER OFF");
                end
                this.averageStatus = 0;
            elseif mode == 1
                switch this.mode
                    case "SA"
                        % this.sendAndWait("AVER 1");
                    case "PN"
                        this.sendAndWait("SENS:AVER ON");
                end
                this.averageStatus = 1;
                this.send("SENS:SWE:GRO:COUN " ...
                    + num2str(this.averageCount));
            end
            this.disconnect;
        end

        function this = setSmoothing(this, smoothing)
            % Note: Will write to the instrument irrespective of the
            % current mode but is ineffective if log plot in phase
            % noise is not selected.
            this.connect;
            if (smoothing > 0)
                this.send("CALC:MEAS"+this.meas_ID+":SMO ON");
                noPoints = length(split(this.sendAndRead("CALC:MEAS"+this.meas_ID+":X?"),","));
                if smoothing/100 > this.maxSmoothing
                    warning("Required smoothing was more than the "+ ...
                        "maximum smoothing (" + ...
                        num2str(this.maxSmoothing) + ") allowed by" + ...
                        " the instrument. Defaulted to maximum " + ...
                        "allowed value.");
                end
                smoothing = min(smoothing/100,this.maxSmoothing);
                this.send("CALC:MEAS"+this.meas_ID+":SMO:POIN " ...
                    + max(1,floor(smoothing*noPoints)));
            else
                this.send("CALC:MEAS:SMO OFF");
            end
            this.disconnect;
        end

        function this = setPort(this, portNumber)
            this.connect;
            this.send("SENS:PN:PORT " + num2str(portNumber));
            this.disconnect;
        end

        function this = setVoltage(this, voltage)
            this.connect;
            % this.send("CONT:DC:OUTP:VOLT """+this.dc_ID+ ...
            %             ""","+num2str(voltage));

            % this.send("SYST:DC:DEF:OUTP:STAT """+this.dc_ID+ """, 1");
            % this.send("SOUR:DC:OUTP """+this.dc_ID+ """, DEF");
            this.send("SYST:DC:DEF:OUTP:VOLT """+this.dc_ID+ ...
                        ""","+num2str(voltage));

            % this.send("SOUR:DC:OUTP """+this.dc_ID+ """, ON");
            % this.send("SYST:DC:DEF:OUTP:STAT """+this.dc_ID+ """, 1");
            % this.send("SYST:DC:DEF:OUTP:VOLT """+this.dc_ID+ ...
            %             ""","+num2str(voltage));
            this.disconnect;
        end

        function this = setDCMode(this, status)
            this.connect;
            this.send("SYST:DC:ENAB "+num2str(status));
            % if status
            %     this.send("SYST:DC:DEF:OUTP:STAT """+this.dc_ID+ """, 1");
            % else
            %     this.send("SYST:DC:DEF:OUTP:STAT """+this.dc_ID+ """, 0");
            % end
            this.disconnect;
        end

        function this = setLNO(this, mode)
            if mode
                this.send("SOUR:DC:LNO ""VControl"",1");
            else
                this.send("SOUR:DC:LNO ""VControl"",0");
            end
        end

        function this = setSNoiseID_State(this, state)
            this.connect;
            if state
                this.send("CALC:MEAS:PN:SNO:USER"+this.sNoise_ID+":STAT ON");
            else
                this.send("CALC:MEAS:PN:SNO:USER"+this.sNoise_ID+":STAT OFF");
            end
            this.disconnect;
        end

        function this = setSNoiseFreq(this, freq)
            this.connect;
            this.send("CALC:MEAS:PN:SNO:USER"+this.sNoise_ID+":X "+num2str(freq));
            this.disconnect;
        end

        function voltage = getVoltage(this)
            this.connect;
            voltage = str2num(this.sendAndRead("CONT:DC:OUTP:VOLT? """ ...
                +this.dc_ID+""""));
            this.disconnect;
        end

        function current = getCurrent(this)
            this.connect;
            current = str2num(this.sendAndRead("CONT:DC:INP:CURR? """ ...
                +this.dc_ID+""""));
            this.disconnect;
        end

        function this = setCorrCount(this, corrCount)
            this.connect;
            this.send("SENS:PN:CORR:COUN " + num2str(corrCount));
            this.disconnect;
        end

        function this = setModeAsPhaseNoise(this)
            this.connect;
            this.send("CALC:MEAS"+this.meas_ID+":DEF ""PN:Phase Noise""");
            this.send("DISP:MEAS"+this.meas_ID+":FEED 1");
            this.send("SENS:PN:NTYPE PNO");
            this.disconnect;
            this.mode = "PN";
        end

        function this = setSNoise_State(this, state)
            this.connect;
            if state
                this.send("CALC:MEAS:PN:SNO:STAT ON");
                this.send("DISP:WIND:TABL:SNO:ENAB ON");
            else
                this.send("CALC:MEAS:PN:SNO:STAT OFF");
                this.send("DISP:WIND:TABL:SNO:ENAB ON");
            end
            this.disconnect;
        end

        function trace = getTrace(this)
            this.connect;
            this.send("*CLS");
            % Initiate the measurement
            switch this.mode
                case "PN"
                    this.send("SENS:AVER:CLE");
                    if this.averageStatus
                        this.send("SENS:SWE:MODE GRO");
                        % pause(1+this.averageCount*timePerSweep);
                    else
                        this.send("SENS:SWE:MODE SING");
                    end
                case "RES"
                    % this.send("SENS:PN:ADJ:CONF:FREQ:CHEC OFF");
                    % this.send("SENS:PN:ADJ:CONF:FREQ:CHEC ON");
                    % this.send("CALC:MEAS"+this.meas_ID+":PN:INT:RANGE1:DATA? IPN");
                case "SA"
                    % this.send("INIT:CONT 0");
                    % this.send("AVER:CLE");pause(0.5);
                    % this.send("INIT:IMM");pause(0.5);
            end
            this.send("*OPC?");
            % Wait for measurement to complete
            while true
                try
                    if exist('response', 'var')
                        if str2double(strtrim(response))
                            break;
                        end
                    end
                    response = readline(this.visaObj);
                catch ME
                    if not(strcmp(ME.identifier, ...
                            'instrument:interface:visa:operationTimedOut'))
                        rethrow(ME);
                    elseif exist('response', 'var')
                        if str2double(strtrim(response))
                            break;
                        end
                    end
                end
            end
            % Read data and process it
            switch this.mode
                case "SA"
                    % d = this.sendAndRead("TRAC:DATA? TRACE1");
                    % d = strsplit(d, ',');
                    % d = str2double(d);
                    % x = linspace(this.getStartFreq, this.getStopFreq, length(d));
                    % trace.freq = x';
                    % trace.spectrum = d';
                case "PN"
                    try
                        d = this.sendAndRead("CALC:MEAS:DATA:FDATA?");
                    catch ME
                        if strcmpi(ME.identifier, ...
                                'instrument:interface:visa:operationTimedOut')
                            % Means that it was not able to find carrier
                            this.send("*CLS");
                            trace.cPower = [];
                            trace.cFreq = [];
                            trace.freq = [];
                            trace.pNoise = [];
                            this.disconnect;
                            return;
                        end
                    end
                    trace.pNoise = str2double(split(d,","));
                    trace.freq = this.sendAndRead("CALC:MEAS"+this.meas_ID+":X?");
                    trace.freq = str2double(split(trace.freq,","));
            end
            this.disconnect;
        end

        function data = getSNoise(this)
            this.connect;
            this.send("SENS:AVER:CLE");
            if this.averageStatus
                this.send("SENS:SWE:MODE GRO");
                % pause(1+this.averageCount*timePerSweep);
            else
                this.send("SENS:SWE:MODE SING");
            end
            this.waitTillOpComplete;
            data.freq = str2double(this.sendAndRead("CALC:MEAS:PN:SNO:USER"+this.sNoise_ID+":X?"));
            data.pNoise = str2double(this.sendAndRead("CALC:MEAS:PN:SNO:USER"+this.sNoise_ID+":Y?"));
            this.disconnect;
        end

        function f = getStartFreq(this)
            this.connect;
            switch this.mode
                case "SA"
                    % f = str2double(this.sendAndRead("FREQ:STAR?"));
                    f = 0;
                case "PN"
                    f = str2double(this.sendAndRead("SENS:FREQ:STAR?"));
                case "CHP"
                    % f = str2double(this.sendAndRead("CHP:FREQ:STAR?"));
                    f = 0;
                case "NF"
                    % f = str2double(this.sendAndRead("FREQ:STAR?"));
                    f = 0;
            end
            this.disconnect;
        end

        function setStartFreq(this, f)
            this.connect;
            f = this.getIntoScientificForm(this.keepFreqInLimit(f), "Hz");
            switch this.mode
                case "SA"
                    % this.send("FREQ:STAR " + f);
                case "PN"
                    this.send("SENS:FREQ:STAR " + f);
                case "CHP"
                    % this.send("CHP:FREQ:STAR " + f);
                case "NF"
                    % this.send("FREQ:STAR " + f);
            end
            this.disconnect;
        end

        function setCenterFreq(this, f)
            this.connect;
            fmin = this.getIntoScientificForm(this.keepFreqInLimit(0.95*f), "Hz");
            fmax = this.getIntoScientificForm(this.keepFreqInLimit(1.05*f), "Hz");
            f = this.getIntoScientificForm(this.keepFreqInLimit(f), "Hz");
            switch this.mode
                case "SA"
                    % this.send("FREQ:CENT " + f);
                case "PN"
                    % this.send("FREQ:CARR " + f);
                    this.send("SENS:PN:SWE:CARR:FREQ " + f);
                    this.send("SENS:PN:ADJ:CONF:FREQ:LIM:LOW " + fmin);
                    this.send("SENS:PN:ADJ:CONF:FREQ:LIM:HIGH " + fmax);
                    this.send("SENS:PN:ADJ:CONF:FREQ:CHEC ON");
                case "CHP"
                    % this.send("FREQ:CENT " + f);
            end
            this.disconnect;
        end

        function f = getStopFreq(this)
            this.connect;
            switch this.mode
                case "SA"
                    % f = str2double(this.sendAndRead("FREQ:STOP?"));
                case "PN"
                    % f = str2double(this.sendAndRead("LPL:FREQ:OFFS:STOP?"));
                    f = str2double(this.sendAndRead("SENS:FREQ:STOP?"));
                case "CHP"
                    % f = str2double(this.sendAndRead("CHP:FREQ:STOP?"));
                case "NF"
                    % f = str2double(this.sendAndRead("FREQ:STOP?"));
            end
            this.disconnect;
        end

        function setStopFreq(this, f)
            this.connect;
            f = this.getIntoScientificForm(this.keepFreqInLimit(f), "Hz");
            switch this.mode
                case "SA"
                    % this.send("FREQ:STOP " + f);
                case "PN"
                    this.send("SENS:FREQ:STOP " + f);
            end
            this.disconnect;
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

        function waitTillOpComplete(this)
            readAttemptCount1 = 10; % Number of times response is checked 
                                    % before *OPC is sent.
            readAttemptCount2 = 5; % Number of times *OPC is sent
            
            readAttemptCountdown1 = readAttemptCount1;
            readAttemptCountdown2 = readAttemptCount2;
            this.send("*OPC?");
            while true
                if exist('response', 'var')
                    if str2double(strtrim(response))
                        break;
                    end
                end
                try
                    response = readline(this.visaObj);
                catch ME
                    if not(strcmp(ME.identifier, ...
                            'instrument:interface:visa:operationTimedOut'))
                        rethrow(ME);
                    else
                        if readAttemptCountdown2 < 0
                            % rethrow(ME);
                            readAttemptCountdown2 = readAttemptCount2;
                        end
                        if readAttemptCountdown1 < 0
                            this.send("*OPC?");
                            readAttemptCountdown2 = readAttemptCountdown2 - 1;
                            readAttemptCountdown1 = readAttemptCount1;
                        end
                        if exist('response', 'var')
                            if str2double(strtrim(response))
                                break;
                            end
                        end
                        readAttemptCountdown1 = readAttemptCountdown1 - 1;
                    end
                end
            end
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
                    this.visaObj = [visadev(this.address)];
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
            this.disconnect;
        end
    end
end