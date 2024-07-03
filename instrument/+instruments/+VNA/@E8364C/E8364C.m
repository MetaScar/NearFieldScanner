classdef E8364C < handle
    % Author: Joel P Johnson
    % Desciption: Creates a wrapper class to access the good-old E8364C PNA
    % that keeps on living.
    % Prerequisites:    Keysight Connection Expert (tested with 2023)
    %                   Keysight IVI drivers for the PNA (tested with
    %                       IVI driver for Agilent Network Analyzers,
    %                       1.2.3.0, 32/64-bit, IVI-C/IVI-COM)
    % To-Do:    Make sure S21 and S12 are correct in getS2P
    %           Remove %#ok<SPERR>

    properties(Access=public)
        address
        visaObj
        averageCount
        freqPoints
        numOfPorts = 2
    end
    properties(Access=private)
        minPower = -25; % True min is -87
        maxPower = 0; % True max is 20
    end
    
    methods
        function this = E8364C(Address, varargin)
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
                if strcmpi(p.Results.View, "V1") %#ok<IFBDUP>
                    this.setView();
                elseif strcmpi(p.Results.View, "V2")
                    this.setView();
                else
                    this.setView(); % Default
                end
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
            % "S2P" - "" (Dummy)
            % Only one parameter at a time

            %% Parse input arguments
            p = inputParser(); 
            addParameter(p,'S1P',[]);
            addParameter(p,'S2P',[])
            parse(p,varargin{:});

            if not(isempty(p.Results.S1P))
                data = this.getS1P(p.Results.S1P);
                return;
            end

            if not(isempty(p.Results.S2P))
                data = this.getS2P();
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
                   && strcmpi(id(2), 'E8364C'))
                this.disconnect();
                error(sprintf("Please check the address for E8364C. "...
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

        function this = setView(this)
            this.connect();
            % Add functionality where it finds all windows and then deletes
            % all windows.
            this.send("DISP:WIND1:TRAC1:DEL");
            this.send("DISP:WIND1:TRAC2:DEL");
            this.send("DISP:WIND1:TRAC3:DEL");
            this.send("DISP:WIND1:TRAC4:DEL");
            this.send("DISP:WIND2:TRAC1:DEL");
            this.send("DISP:WIND2:TRAC2:DEL");
            this.send("DISP:WIND2:TRAC3:DEL");
            this.send("DISP:WIND2:TRAC4:DEL");
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
            this.send("DISP:WIND4:TRAC2:FEED 'S12'");
            this.send("CALC:PAR:SEL 'S12'");
            this.send("CALC:FORM MLOG");
            this.disconnect();
        end

        function this = setAverageCount(this, count)
            this.averageCount = count;
            this.connect();
            this.sendAndWait("SENS:AVER:COUN " + num2str(count));
            this.disconnect();
        end

        function sParam = getS2P(this)
            this.connect();
            this.send( "TRIG:SOUR MAN");
            this.send( "SENS:SWE:MODE SING");
            for sweepCount = 1:(this.averageCount+1)
               this.sendAndWait("INIT:IMM");
            end
            data = this.sendAndRead("CALC:DATA:SNP:PORTS? '1,2'");
            this.send("SENS:SWE:MODE CONT");
            this.send("TRIG:SOUR IMM");
            this.disconnect();

            data = strsplit(data, ",");
            tData = zeros(1, length(data));
            for iLength = 1:length(data)
                tData(iLength) = str2double(data(iLength));
            end

            data = tData; clear tData;
            this.freqPoints = length(data)/9;
            freq = data(1:this.freqPoints);
            S11 = data(1*this.freqPoints+(1:this.freqPoints)) + 1i*data(2*this.freqPoints+(1:this.freqPoints));
            S21 = data(3*this.freqPoints+(1:this.freqPoints)) + 1i*data(4*this.freqPoints+(1:this.freqPoints));
            S12 = data(5*this.freqPoints+(1:this.freqPoints)) + 1i*data(6*this.freqPoints+(1:this.freqPoints));
            S22 = data(7*this.freqPoints+(1:this.freqPoints)) + 1i*data(8*this.freqPoints+(1:this.freqPoints));
            s = zeros(2,2,length(freq));
            s(1,1,:) = S11;
            s(2,1,:) = S21;
            s(1,2,:) = S12;
            s(2,2,:) = S22;
            sParam = sparameters(s, freq);
        end

        function sParam = getS1P(this, port)
            this.connect();
            this.send( "TRIG:SOUR MAN");
            this.send( "SENS:SWE:MODE SING");
            for sweepCount = 1:(this.averageCount+1)
               this.sendAndWait("INIT:IMM");
            end
            data = this.sendAndRead("CALC:DATA:SNP:PORTS? '" + num2str(port) + "'");
            this.send("SENS:SWE:MODE CONT");
            this.send("TRIG:SOUR IMM");
            this.disconnect();

            data = strsplit(data, ",");
            tData = zeros(1, length(data));
            for iLength = 1:length(data)
                tData(iLength) = str2double(data(iLength));
            end

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