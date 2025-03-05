classdef N5224A < handle
    % Author: Joel P Johnson
    % Desciption: Creates a wrapper class to access the good-new N5224A PNA
    % that keeps on begging for more money.
    % Prerequisites:    Keysight Connection Expert (tested with 2023)
    %                   Keysight IVI drivers for the PNA (tested with
    %                       IVI driver for Agilent Network Analyzers,
    %                       1.2.3.0, 32/64-bit, IVI-C/IVI-COM)
    % To-Do:    Remove %#ok<SPERR>

    properties(Access=public)
        address
        visaObj
        averageCount
        freqPoints
        numOfPorts = 4
    end
    properties(Access=private)
        minPower = -25; % True min is -87
        maxPower = 0; % True max is 20
    end
    
    methods
        function this = N5224A(Address, varargin)
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
            % "Port_Power" - 1 (numeric)(0 for all ports or the port number.)
            % "Port" - 1 (numeric)(0 for all ports or the port number. Must be specified if Port_power is specified.)
            % "View" - "Default" (string)(Add as necessary.)
            % "Average_Count" - 5 (numeric)
            % "Port_Count" - 2 (numeric)(Count of all active ports.)

            %% Parse input arguments
            p = inputParser(); 
            addParameter(p,'Port_Power',[]);
            addParameter(p,'Port',[]);
            addParameter(p,'View',[])
            addParameter(p,'Average_Count',[]);
            addParameter(p,'Port_Count',[]);
            parse(p,varargin{:});

            %% Handling Port_Power and Port parameters
            if not(isempty(p.Results.Port_Power))
                if p.Results.Port == 0
                    this.setPower(p.Results.Port_Power);
                elseif p.Results.Port < 0
                    error("Port number must not be negative.");
                else
                    if p.Results.Port <= this.numOfPorts
                        this.setPowerAtPort(p.Results.Port, p.Results.Port_Power);
                    else
                        error("Specified port number exceeds the " + ...
                            "number of active ports.");
                    end
                end
            end

            %% Handling View parameter
            if not(isempty(p.Results.View))
                this.setView(p.Results.View);
            end

            %% Handling Average_Count parameter
            if not(isempty(p.Results.Average_Count))
                this.setAverageCount(p.Results.Average_Count);
            end

            %% Handling Port_Count parameter
            if not(isempty(p.Results.Port_Count))
                this.numOfPorts = p.Results.Port_Count;
            end

        end

        function data = get(this, varargin)
            %% Possible name and value pairs
            % "S1P" - 1 (numeric)(Port number.)
            % "SNP" - {1,2,3} (Dummy)
            % Only one parameter at a time

            %% Parse input arguments
            p = inputParser(); 
            addParameter(p,'S1P',[]);
            addParameter(p,'SNP',{})
            parse(p,varargin{:});

            if not(isempty(p.Results.S1P))
                data = this.getS1P(p.Results.S1P);
                return;
            end

            if not(isempty(p.Results.SNP))
                data = this.getSNP(p.Results.SNP);
                return;
            end
        end

        function this = s(this)
            % A testing function
            this.connect();
            this.disconnect();
        end
    end

    methods(Access=private)
        function this = initialize(this)
            this.connect();

            % Make sure it is connected to the right instrument
            id = this.sendAndRead("*IDN?");
            id = strsplit(id,',');
            if ~(strcmpi(id(1), 'Agilent Technologies') ...
                   && strcmpi(id(2), 'N5224A'))
                this.disconnect();
                error(sprintf("Please check the address for N5224A. "...
                    + "%s is either incorrect address for Agilent "...
                    + "Technologies E8364C PNA or the same address is "...
                    +"shared between two instruments.", this.address)); %#ok<SPERR>
            end

            % Save measurement names
            this.send("CALC:PAR:DEL:ALL");
            this.send("CALC:PAR:EXT 'S11', 'S1_1'");
            this.send("CALC:PAR:EXT 'S22', 'S2_2'");
            this.send("CALC:PAR:EXT 'S21', 'S2_1'");
            this.send("CALC:PAR:EXT 'S12', 'S1_2'");

            this.disconnect();
            this.averageCount = 3;
        end

        function this = setView(this, view)
            this.connect;

            winNumbs = this.sendAndRead("DISP:CAT?");
            winNumbs = str2double(strsplit(erase(winNumbs,""""),","));

            for winIdx = winNumbs
                traceNumbs = this.sendAndRead("DISP:WIND"+num2str(winIdx)+":CAT?");
                traceNumbs = str2double(strsplit(erase(traceNumbs,""""),","));
                if isnan(traceNumbs)
                    continue;
                else
                    for traceIdx = traceNumbs
                        this.send("DISP:WIND"+num2str(winIdx)+ ...
                            ":TRAC"+num2str(traceIdx)+":DEL");
                    end
                end
            end

            switch view
                case "Default_S2P"
                    this.sendAndWait("DISP:ARR QUAD");
        
                    this.send("CALC:PAR:DEL:ALL");
                    this.send("CALC:PAR:EXT 'S11', 'S1_1'");
                    this.send("CALC:PAR:EXT 'S22', 'S2_2'");
                    this.send("CALC:PAR:EXT 'S21', 'S2_1'");
                    this.send("CALC:PAR:EXT 'S12', 'S1_2'");
        
                    this.send("DISP:WIND1:TRAC1:FEED 'S11'");
                    this.send("CALC:PAR:SEL 'S11'");
                    this.send("CALC:FORM SMIT");
                    this.send("DISP:WIND2:TRAC1:FEED 'S22'");
                    this.send("CALC:PAR:SEL 'S22'");
                    this.send("CALC:FORM SMIT");
                    this.send("DISP:WIND3:TRAC1:FEED 'S21'");
                    this.send("CALC:PAR:SEL 'S21'");
                    this.send("CALC:FORM MLOG");
                    this.send("DISP:WIND4:TRAC1:FEED 'S12'");
                    this.send("CALC:PAR:SEL 'S12'");
                    this.send("CALC:FORM MLOG");

                case "Default_S1P_P1"
                    this.sendAndWait("DISP:ARR STAC");
        
                    this.send("CALC:PAR:DEL:ALL");
                    this.send("CALC:PAR:EXT 'S11_1', 'S1_1'");
                    this.send("CALC:PAR:EXT 'S11_2', 'S1_1'");
        
                    this.send("DISP:WIND1:TRAC1:FEED 'S11_1'");
                    this.send("CALC:PAR:SEL 'S11_1'");
                    this.send("CALC:FORM SMIT");
                    this.send("DISP:WIND2:TRAC1:FEED 'S11_2'");
                    this.send("CALC:PAR:SEL 'S11_2'");
                    this.send("CALC:FORM MLOG");

                case "Default_S1P_P2"
                    this.sendAndWait("DISP:ARR STAC");
        
                    this.send("CALC:PAR:DEL:ALL");
                    this.send("CALC:PAR:EXT 'S22_1', 'S2_2'");
                    this.send("CALC:PAR:EXT 'S22_2', 'S2_2'");
        
                    this.send("DISP:WIND1:TRAC1:FEED 'S22_1'");
                    this.send("CALC:PAR:SEL 'S22_1'");
                    this.send("CALC:FORM SMIT");
                    this.send("DISP:WIND2:TRAC1:FEED 'S22_2'");
                    this.send("CALC:PAR:SEL 'S22_2'");
                    this.send("CALC:FORM MLOG");
            end
            this.disconnect();
        end

        function this = setAverageCount(this, count)
            this.averageCount = count;
            this.connect();
            this.sendAndWait("SENS:AVER:COUN " + num2str(count));
            this.sendAndWait("SENS:SWE:GRO:COUN " + num2str(count));
            this.disconnect();
        end

        function sParam = getSNP(this, ports)
            % Parameter validation
            ports = cell2mat(ports);
            if length(ports) ~= length(unique(ports))
                error("A port number specified more than once!");
            end
            if isempty(ports)
                error("Port number not specified!");
            end
            for port = ports
                if port<1 || port>this.numOfPorts
                    error("Invalid port number %d specified!",port);
                end
            end

            % Suffix for the SCPI command
            portCommSuffix = "'";
            for port = ports
                portCommSuffix = portCommSuffix + num2str(port) + ",";
            end
            portCommSuffix = portCommSuffix + "'";
            portCommSuffix = replace(portCommSuffix, ",'", "'");

            % Retrieve data
            this.connect();
            this.send( "TRIG:SOUR IMM");    % trigger only once
            this.send("SENS:SWE:MODE GRO"); % not sure; seems to allow multiple triggers
            this.waitTillOpComplete;
            this.send("MMEM:STOR:TRAC:FORM:SNP RI"); % S params as real and imaginary
            data = this.sendAndRead("CALC:DATA:SNP:PORTS? " ...
                    + portCommSuffix);
            this.disconnect();

            % Sort data
            data = strsplit(data, ",");
            tData = zeros(1, length(data));
            for iLength = 1:length(data)
                tData(iLength) = str2double(data(iLength));
            end

            % Convert to sparam obj
            data = tData; clear tData;
            this.freqPoints = length(data)/(1+(2*(length(ports)^2)));
            freq = data(1:this.freqPoints);
            s = zeros(length(ports),length(ports),length(freq));
            dataIdx = 1;
            for jIdx = 1:length(ports)
                for iIdx = 1:length(ports)
                    s(iIdx,jIdx,:) = ...
                        data(dataIdx*this.freqPoints+(1:this.freqPoints))...
                        + 1i*data((dataIdx+1)*this.freqPoints+(1:this.freqPoints));
                    dataIdx = dataIdx + 2;
                end
            end
            sParam = sparameters(s, freq);
        end

        function sParam = getS1P(this, port)
            % Parameter validation
            if port<1 || port>this.numOfPorts
                error("Invalid port number %d specified!",port);
            end

            % Retrieve data
            this.connect;
            this.send( "TRIG:SOUR IMM");
            this.send("SENS:SWE:MODE GRO");
            this.waitTillOpComplete;
            this.send("MMEM:STOR:TRAC:FORM:SNP RI");
            data = this.sendAndRead("CALC:DATA:SNP:PORTS? '" + num2str(port) + "'");
            this.disconnect;

            % Sort data
            data = strsplit(data, ",");
            tData = zeros(1, length(data));
            for iLength = 1:length(data)
                tData(iLength) = str2double(data(iLength));
            end

            % Convert to sparam obj
            data = tData; clear tData;
            this.freqPoints = length(data)/3;
            freq = data(1:this.freqPoints);
            S11 = data(1*this.freqPoints+(1:this.freqPoints)) + 1i*data(2*this.freqPoints+(1:this.freqPoints));
            s = zeros(1,1,length(freq));
            s(1,1,:) = S11;
            sParam = sparameters(s, freq);
        end

        function this = setPower(this, powerLevel)
            this.connect();
            for portIdx = 1:this.numOfPorts
                this.sendAndWait("SOUR:POW" + num2str(portIdx) +" "+ sprintf("%0.2f",powerLevel));
            end
            this.disconnect();
        end

        function this = setPowerAtPort(this, port, powerLevel)
            this.connect();
            if powerLevel<this.minPower
                powerLevel = this.minPower;
            end
            if powerLevel>this.maxPower
                powerLevel = this.maxPower;
            end
            this.sendAndWait("SOUR:POW" + num2str(port) +" "+ sprintf("%0.2f",powerLevel));
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

        function this = send(this, command)
            if ~isempty(this.visaObj)
                writeline(this.visaObj,command);
            else
                error("Device not connected");
            end
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