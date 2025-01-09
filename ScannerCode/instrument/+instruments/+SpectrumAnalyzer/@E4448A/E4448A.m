classdef E4448A < handle
    % Author:           Joel P Johnson
    % Desciption:       Creates a wrapper class to access the E4448A 
    %                   Spectrum Analyzer
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
        selectedChannel = 1;
    end
    properties(Access=private)
        connectionCount = 0;
        averageCount = 3;
        mode = "SA"; % SA & CHP & PN & NF
        connected = false;
        minFreq = 3;
        maxFreq = 50e9;
        minPower = -25; % True min is -87
        maxPower = 0; % True max is 20
        maxSmoothing = 16;

        noiseSources = {};
        noiseSource1_PN = "346CK01";
        noiseSource1_SN = "MY62300246";
        noiseSource1_Freq = [1e9:1e9:26e9, 26.5e9 27e9:1e9:50e9];
        noiseSource1_ENR = [18.28, 18.45, 18.14, 18.04, 17.93, 17.83 ...
            , 17.72, 17.51 17.36 17.15 17.08 16.88 16.74 16.6 16.43 ...
            , 16.45 16.29 16.2 16.28 16.05 15.94 16.02 16.11 16.13 ...
            , 15.82 15.84 15.86 15.72 15.7 15.74 15.8 15.79 15.79 15.78 ...
            , 15.86 15.85 15.87 15.72 15.39 15.22 15.31 15.18 14.99 ...
            , 14.61 14.25 13.59 13 12.5 12.23 11.94 11.38];
    end
    
    methods
        function this = E4448A(Address, varargin)
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
            %           Noise", "Noise Figure"(String)(Must be mentioned 
            %           if Trace is expected)
            % "Start_Freq" - 0 (numeric)(Context dependant on SA mode)[Hz]
            % "Center_Freq" - 25e9 (numeric)(Context dependeant)
            % "Stop_Freq" - 50e9 (numeric)(Context dependant on SA
            %               mode)[Hz]
            % "Freq_Sweep_Points" - 100(numeric)(Only valid in noise figure
            %                       mode)
            %                       Sets the number of points in the
            %                       frequency sweep.
            % "Average" - 3 of "OFF" (numeric or string)(When parameter
            %             is numeric then it is assumed that it is 
            %             average count. If string, it is assumed to be
            %             the state of average.)
            % "Smoothing" - "OFF"(string)(Only valid when phase noise 
            %                mode is active.)
            % "Bandwidth" - 2e6(numeric)
            %               Context dependant.
            %               For CHP mode, sets integration bandwidth and
            %               channel power span.
            %               For SA mode, sets span around center frequency.
            % "ENR"       - ""(string)(dummy)
            %               Load ENR table assuming common table is used.
            % "ProductNumber" - "346CK01"(string)(Only when setting ENR)
            %                   The product number of the noise source.
            % "SerialNumber" -  "346CK01"(string)(Only when setting ENR)
            %                   The serial number of the noise source. 
            % "LossBeforeDUT" - [1,2,3] (double)(Only valid when mode set
            %                   as Noise Figure.)
            %                   Loss before DUT in dB. Frequencies must
            %                   also be specified if this parameter is fed.
            % "LossAfterDUT"  - [1,2,3] (double)(Only valid when mode set
            %                   as Noise Figure.)
            %                   Loss before DUT in dB. Frequencies must
            %                   also be specified if this parameter is fed.
            % "Frequencies"   - [1e9, 2e9](double)
            %                   Frequency data points for loss before DUT
            %                   or loss after DUT parameter. Only valid in
            %                   Noise Figure mode for now.
            % "Calibration"   - ""(string)(dummy)
            %                   Set calibration.

            %% Parse input arguments
            p = inputParser(); 
            addParameter(p,'Start_Freq',[]);
            addParameter(p,'Center_Freq',[]);
            addParameter(p,'Stop_Freq',[]);
            addParameter(p,'Mode',[]);
            addParameter(p,'Average',[]);
            addParameter(p,'Smoothing',[]);
            addParameter(p,'Bandwidth',[]);
            addParameter(p,'ENR',[]);
            addParameter(p,'ProductNumber',[]);
            addParameter(p,'SerialNumber',[]);
            addParameter(p,'LossBeforeDUT',[]);
            addParameter(p,'LossAfterDUT',[]);
            addParameter(p,'Frequencies',[]);
            addParameter(p,'Calibration',[]);
            addParameter(p,'Freq_Sweep_Points',[]);
            parse(p,varargin{:});

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

            %% Setting Freq_Sweep_Points
            if not(isempty(p.Results.Freq_Sweep_Points))
                this.setFreqSweepPoints(p.Results.Freq_Sweep_Points);
            end

            %% Setting Mode
            if not(isempty(p.Results.Mode))
                switch p.Results.Mode
                    case "Spectrum Analyzer"
                        this.setModeAsSpecAn;
                    case "Phase Noise"
                        this.setModeAsPhaseNoise;
                    case "Channel Power"
                        this.setModeAsChannelPower;
                    case "Noise Figure"
                        this.setModeAsNoiseFigure;
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
                this.setSmoothing(p.Results.Smoothing);
                this.waitTillOpComplete();
            end

            %% Setting Bandwidth
            if not(isempty(p.Results.Bandwidth))
                this.setBandwidth(p.Results.Bandwidth);
                this.waitTillOpComplete();
            end

            %% Setting ENR
            if not(isempty(p.Results.ENR))
                this.setEnrTable(p.Results.ProductNumber,p.Results.SerialNumber);
            end

            %% Setting LossBeforeDUT
            if not(isempty(p.Results.LossBeforeDUT)) ...
                    && not(isempty(p.Results.Frequencies))
                this.setLossBeforeDUTTable(p.Results.Frequencies, ...
                    p.Results.LossBeforeDUT);
            end

            %% Setting LossAfterDUT
            if not(isempty(p.Results.LossAfterDUT)) ...
                    && not(isempty(p.Results.Frequencies))
                this.setLossAfterDUTTable(p.Results.Frequencies, ...
                    p.Results.LossAfterDUT);
            end

            %% Setting Calibration
            if not(isempty(p.Results.Calibration))
                this.calibrateForNF;
            end


            this.waitTillOpComplete(); % JIC
        end

        function data = get(this, varargin)
            %% Possible name and value pairs
            % "Trace" - "" (string)(dummy)
            % "Start_Freq" - ""(string)(dummy)
            % "Stop_Freq" - ""(string)(dummy)
            % Only one measurement at a time

            %% Parse input arguments
            p = inputParser(); 
            addParameter(p,'Trace',[]);
            addParameter(p,'Start_Freq',[]);
            addParameter(p,'Stop_Freq',[]);
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
            this.connect();
            % Make sure it is connected to the right instrument
            id = this.sendAndRead("*IDN?");
            id = strsplit(id,',');
            if ~(strcmpi(strtrim(id(1)), 'Agilent Technologies') ...
                   && strcmpi(strtrim(id(2)), 'E4448A'))
                this.disconnect();
                error("Please check the address for 54750A. "...
                    + "%s is either incorrect address for HEWLETT-"...
                    + "PACKARD 54750A oscilloscope or the same address "...
                    +"is shared between two instruments.", this.address);
            end
            this.setView();
            currentMode = strtrim(this.sendAndRead("INST?"));
            switch currentMode
                case "SA"
                    conf = strtrim(this.sendAndRead("CONF?"));
                    switch conf
                        case '"CHPower"'
                            this.mode = "CHP";
                        case '"SANalyzer"'
                            this.mode = "SA";
                    end
                case "PNOISE"
                    this.mode = "PN";
            end
            this.disconnect();

            %% Save Noise Sources - Probably Should automate this
            this.noiseSources{1}.pn = this.noiseSource1_PN;
            this.noiseSources{1}.sn = this.noiseSource1_SN;
            this.noiseSources{1}.freq = this.noiseSource1_Freq;
            this.noiseSources{1}.enr = this.noiseSource1_ENR;
        end

        function this = setView(this)
            this.connect();
            this.send("TRAC1:MODE WRIT");
            this.send("TRAC2:MODE BLAN");
            this.send("TRAC3:MODE BLAN");
            this.send("INIT:CONT 0");
            this.send("*CLS");
            this.disconnect();
        end

        function this = setModeAsSpecAn(this)
            this.connect();
            this.send("INST SA");
            this.waitTillOpComplete();
            this.send("CONF:SAN");
            this.waitTillOpComplete();
            this.mode = "SA";
            this.send("*CLS");
            this.disconnect();
        end

        function this = setAverageCount(this, averageCount)
            this.connect();
            switch this.mode
                case "SA"
                    this.send("AVER:COUN " + num2str(averageCount));
                case "PN"
                    this.send("LPL:AVER:COUN " + num2str(averageCount));
                case "CHP"
                    this.send("CHP:AVER:COUN " + num2str(averageCount));
                case "NF"
                    this.send("AVER:COUN " + num2str(averageCount));
                    this.send("AVER 1");
            end
            this.disconnect();
            this.averageCount = averageCount;
        end

        function this = setAverage(this, mode)
            this.connect();
            if mode == 0
                switch this.mode
                    case "SA"
                        this.sendAndWait("AVER 0");
                    case "PN"
                        this.sendAndWait("LPL:AVER 0");
                    case "CHP"
                        this.sendAndWait("CHP:AVER 0");
                    case "NF"
                        this.sendAndWait("AVER 0");
                end
            elseif mode == 1
                switch this.mode
                    case "SA"
                        this.sendAndWait("AVER 1");
                    case "PN"
                        this.sendAndWait("LPL:AVER 1");
                    case "CHP"
                        this.sendAndWait("CHP:AVER 1");
                    case "NF"
                        this.sendAndWait("AVER 0");
                end
            end
            this.disconnect();
        end

        function this = setSmoothing(this, smoothing)
            % Note: Will write to the instrument irrespective of the
            % current mode but is ineffective if log plot in phase
            % noise is not selected.
            if (smoothing >= 0)
                this.send("LPL:SMO " + num2str(min([smoothing, this.maxSmoothing])));
                if smoothing > this.maxSmoothing
                    warning("Required smoothing was more than the "+ ...
                        "maximum smoothing (" + ...
                        num2str(this.maxSmoothing) + ") allowed by" + ...
                        " the instrument. Defaulted to maximum " + ...
                        "allowed value.");
                end
            end
        end

        function this = setModeAsChannelPower(this)
            this.connect();
            this.send("INST SA");
            this.waitTillOpComplete();
            this.send("CONF:CHP");
            this.waitTillOpComplete();
            % this.sendAndWait("INIT:CHP");
            this.mode = "CHP";
            this.send("*CLS");
            this.disconnect();
        end

        function this = setModeAsPhaseNoise(this)
            this.connect();
            this.send("INST PNOISE");
            this.waitTillOpComplete();
            this.send("CONF:LPL");
            this.waitTillOpComplete();
            this.send("MON:POW:ATT:AUTO");
            this.waitTillOpComplete();
            % this.sendAndWait("INIT:LPL"); % Takes too much time
            this.mode = "PN";
            this.send("*CLS");
            this.disconnect();
        end

        function this = setModeAsNoiseFigure(this)
            this.connect;
            this.sendAndWait("INST NFIGURE");
            this.disconnect;
            this.mode = "NF";
        end

        function this = setBandwidth(this, BW)
            this.connect();
            BW1 = this.getIntoScientificForm(this.keepFreqInLimit(1*BW), "Hz");
            BW2 = this.getIntoScientificForm(this.keepFreqInLimit(1*BW), "Hz");
            switch this.mode
                case "SA"
                    this.send("FREQ:SPAN " + BW1);
                case "CHP"
                    this.send("CHP:BAND:INT " + BW1);
                    this.send("CHP:FREQ:SPAN " + BW2);
            end
            this.disconnect();
        end

        function this = setEnrTable(this, productNumber, serialNumber)
            % Assumes common table
            noiseSourceMatchedFlag = false;
            for nsIdx = 1:length(this.noiseSources)
                if strcmpi(productNumber, this.noiseSources{nsIdx}.pn) ...
                        && strcmpi(serialNumber, this.noiseSources{nsIdx}.sn)
                    ns = this.noiseSources{nsIdx};
                    if length(ns.freq) ~= length(ns.enr)
                        error("Number of frequency and ENR data points"+...
                            " do not match for the noise source.");
                    end
                    ns.enr = reshape(ns.enr,1,[]);
                    ns.freq = reshape(ns.freq,1,[]);
                    dataString = reshape([ns.freq; ns.enr],1,[]);
                    dataString = num2str(dataString, "%e ");
                    dataString = strjoin(strsplit(dataString, " "), ", ");
                    this.sendAndWait(":CORR:ENR:COMM 1");
                    this.sendAndWait(":CORR:ENR:CAL:TABL:DATA " + dataString);
                    this.sendAndWait(":CORR:ENR:MEAS:TABL:DATA " + dataString);
                    noiseSourceMatchedFlag = true;
                    break;
                end
            end
            if noiseSourceMatchedFlag == false
                error("No noise source data with matching product "+ ...
                    "number and serial number saved. Please check "+...
                    "the identifications or add the ENR data in the "+...
                    "class definition.");
            end
        end

        function this = calibrateForNF(this)
            this.connect
            this.send("CORR:COLL STAN");
            this.waitTillOpComplete();
            this.disconnect
        end

        function this = setLossBeforeDUTTable(this, freq, loss)
            if length(freq) ~= length(loss)
                error("Number of frequency and loss before DUT"+...
                    " data points do not match.");
            end
            loss = reshape(loss,1,[]);
            freq = reshape(freq,1,[]);
            dataString = reshape([freq; loss],1,[]);
            dataString = num2str(dataString, "%e ");
            dataString = strjoin(strsplit(dataString, " "), ", ");
            this.sendAndWait(":CORR:LOSS:BEF:TABL:DATA " + dataString);
            this.sendAndWait(":CORR:LOSS:BEF:MODE TABL");
            this.sendAndWait(":CORR:LOSS:BEF 1");
        end

        function this = setLossAfterDUTTable(this, freq, loss)
            if length(freq) ~= length(loss)
                error("Number of frequency and loss after DUT"+...
                    " data points do not match.");
            end
            loss = reshape(loss,1,[]);
            freq = reshape(freq,1,[]);
            dataString = reshape([freq; loss],1,[]);
            dataString = num2str(dataString, "%e ");
            dataString = strjoin(strsplit(dataString, " "), ", ");
            this.sendAndWait(":CORR:LOSS:AFT:TABL:DATA " + dataString);
            this.sendAndWait(":CORR:LOSS:BEF:MODE TABL");
            this.sendAndWait(":CORR:LOSS:AFT 1");
        end

        function trace = getTrace(this)
            this.connect();
            this.send("*CLS");
            switch this.mode
                case "PN"
                    this.send("INIT:CONT 0");
                    % this.send("INIT:LPL");
                    this.send("FREQ:CARR:SEAR");
                    this.send("*OPC?");
                case "SA"
                    this.send("INIT:CONT 0");
                    this.send("AVER:CLE");pause(0.5);
                    this.send("INIT:IMM");pause(0.5);
                    this.send("*OPC?");
                case "CHP"
                    this.send("INIT:CONT 0");
                    this.send("AVER:CLE");pause(0.5);
                    this.send("INIT:IMM");pause(0.5);
                    this.send("*OPC?");
                case "NF"
                    this.send("INIT:IMM");pause(0.5);
                    this.send("*OPC?");
            end
            % Inititiate and complete measurement
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

            switch this.mode
                case "SA"
                    d = this.sendAndRead("TRAC:DATA? TRACE1");
                    d = strsplit(d, ',');
                    d = str2double(d);
                    x = linspace(this.getStartFreq, this.getStopFreq, length(d));
                    trace.freq = x';
                    trace.spectrum = d';
                case "PN"
                    try
                        d = this.sendAndRead("FETC:LPL1?");
                    catch ME
                        if strcmpi(ME.identifier, ...
                                'instrument:interface:visa:operationTimedOut')
                            % Means that it was not able to find carrier
                            this.send("*CLS");
                            trace.cPower = [];
                            trace.cFreq = [];
                            trace.freq = [];
                            trace.pNoise = [];
                            this.disconnect();
                            return;
                        end
                    end
                    d = split(d,',');
                    d = str2double(d);
                    trace.cPower = d(1);
                    trace.cFreq = d(2);
                    d = this.sendAndRead("FETC:LPL3?");
                    d = split(d,',');
                    d = str2double(d);
                    trace.freq = d(1:2:end);
                    trace.pNoise = d(2:2:end);
                case "CHP"
                    d = this.sendAndRead("FETC:CHP:CHP?");
                    trace.cPower = str2double(strtrim(d));
                case "NF"
                    d = this.sendAndRead("FETC:CORR:NFIG?");
                    trace.nf = str2double(strsplit(d,","));
                    trace.freq = linspace(this.getStartFreq,...
                                this.getStopFreq,...
                                length(trace.nf));
                    d = this.sendAndRead("FETC:CORR:GAIN?");
                    trace.gain = str2double(strsplit(d,","));
            end
            this.disconnect();
        end

        function f = getStartFreq(this)
            this.connect();
            switch this.mode
                case "SA"
                    f = str2double(this.sendAndRead("FREQ:STAR?"));
                case "PN"
                    f = str2double(this.sendAndRead("LPL:FREQ:OFFS:STAR?"));
                case "CHP"
                    f = str2double(this.sendAndRead("CHP:FREQ:STAR?"));
                case "NF"
                    f = str2double(this.sendAndRead("FREQ:STAR?"));
            end
            this.disconnect();
        end

        function setStartFreq(this, f)
            this.connect();
            f = this.getIntoScientificForm(this.keepFreqInLimit(f), "Hz");
            switch this.mode
                case "SA"
                    this.send("FREQ:STAR " + f);
                case "PN"
                    this.send("LPL:FREQ:OFFS:STAR " + f);
                case "CHP"
                    this.send("CHP:FREQ:STAR " + f);
                case "NF"
                    this.send("FREQ:STAR " + f);
            end
            this.disconnect();
        end

        function setCenterFreq(this, f)
            this.connect();
            f = this.getIntoScientificForm(this.keepFreqInLimit(f), "Hz");
            switch this.mode
                case "SA"
                    this.send("FREQ:CENT " + f);
                case "PN"
                    this.send("FREQ:CARR " + f);
                case "CHP"
                    this.send("FREQ:CENT " + f);
            end
            this.disconnect();
        end

        function f = getStopFreq(this)
            this.connect();
            switch this.mode
                case "SA"
                    f = str2double(this.sendAndRead("FREQ:STOP?"));
                case "PN"
                    f = str2double(this.sendAndRead("LPL:FREQ:OFFS:STOP?"));
                case "CHP"
                    f = str2double(this.sendAndRead("CHP:FREQ:STOP?"));
                case "NF"
                    f = str2double(this.sendAndRead("FREQ:STOP?"));
            end
            this.disconnect();
        end

        function setStopFreq(this, f)
            this.connect();
            f = this.getIntoScientificForm(this.keepFreqInLimit(f), "Hz");
            switch this.mode
                case "SA"
                    this.send("FREQ:STOP " + f);
                case "PN"
                    this.send("LPL:FREQ:OFFS:STOP " + f);
                case "CHP"
                    this.send("CHP:FREQ:STOP " + f);
                case "NF"
                    this.send("FREQ:STOP " + f);
            end
            this.disconnect();
        end

        function setFreqSweepPoints(this, sweepPoints)
            this.sendAndWait("SWE:POIN " + num2str(sweepPoints));
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
            this.disconnect();
        end
    end
end