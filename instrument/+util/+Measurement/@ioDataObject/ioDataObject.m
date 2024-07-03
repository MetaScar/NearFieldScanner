classdef ioDataObject < handle
    %Input/Output Data Object Contains metadata on the io data object
    %   Detailed explanation goes here

    properties
        %name of this data stream
        name            = '';   
        %unit, type, and dimensions of the data 
        unit            = '';   %unit of the data     
        unitPrefix      = '';   %prefix of the unit (multiplier)
        dataType        = '';   %type of data (ie real, complexMA, complexRI)
        dataDimension   = [1];  %dimensions of the data (r)
        %Aquisition metadata 
        accessMethod    = '';   %either simulated or measured (nr)
        instrName       = '';   %name of the instrument (sr)
        instrAddress    = '';   %address of the instrument (sr)
        channelName     = '';   %name of the channel (sr)
        %additional flags and data
        mappingName     = '';   %original data name 
        ignoreOnImport  = false;%flag for determining if this data should 
                                %be ignored during the import process
        portNameMatrix;         %matrix of dut port names for the test
        %Below is a point for attaching additional metadata on the i/o
        metadata        = struct;

        %interpretter function pointers
        inputInterpreter; 
        outputInterpreter; 

    end

    properties(Constant)
        VALID_UNITS     = {'NONE','V','A','W','HZ','SP','ZP'}; 

        PREFIX_MAP      = {'f',1e-15;
                           'p',1e-12;
                           'n',1e-9;
                           'u',1e-6;
                           'm',1e-3;
                           '', 1;
                           'k',1e3;
                           'meg',1e6;
                           'gig',1e9;};

        % VALID_DATA_TYPES= {'REAL',...
        %                    'INT',...
        %                    'BOOL',...
        %                    'COMPLEX'};  
        
        DATA_TYPES = struct('INT',...
                                struct('alias',{'integer','0'}),...
                            'REAL',...
                                struct('alias',{'re','r','1'}),...
                            'STRING',...
                                struct('alias',{'str','2'}),...
                            'COMPLEX_R_I',...
                                struct('alias',{'complex','cmplx','3'}),...
                            'COMPLEX_MAG_RAD',...
                                struct('alias',{'cmplx_m_r'}),...
                            'COMPLEX_MAG_DEG',...
                                struct('alias',{'cmplx_m_d'}),...
                            'COMPLEX_DB_RAD',...
                                struct('alias',{'cmplx_d_r'}),...
                            'COMPLEX_DB_DEG',...
                                struct('alias',{'cmplx_d_d'}),...
                            'BOOL',...
                                struct('alias',{'bool','boolean','tf','logical','4'}),...
                            'BINARY',...
                                struct('alias',{'bin','b','5'}),...
                            'OCTAL',...
                                struct('alias',{'oct','6'}),...
                            'HEXIDECIMAL',...
                                struct('alias',{'hex','7'}),...
                            'BYTE16',...
                                struct('alias',{'8'}));
    end

    methods(Static)
        function valOut = VALID_DATA_TYPES()
            valOut = fieldnames(ioDataObject.DATA_TYPES)';
        end
        function [guess,guessIndex] = guessDataType(valIn,notFoundFlag)
            %GUESS DATA TYPE - Attempts to determine the mapped data type
            %based on the input provided. This is a non-case sensitive
            %search. 
            
            %initialize the guess to real (this is the default value)
            guess = 'REAL'; guessIndex = 2; 
            
            %turn the 
            if not(exist('notFoundFlag','var'))
                notFoundFlag = 0; 
            elseif notFoundFlag > 0 %issue warning if not found
                msg = ['%s does not match a known alias of '...
                        'any known data type. Using type REAL instead.']; 
            elseif notFoundFlag < 0 %throw an error if not found
                msg = ['%s does not match a known alias of '...
                        'any known data type.']; 
            end
            
            %get all the valid default data type names 
            
            vdt = ioDataObject.VALID_DATA_TYPES; 
            
            for index = 1:length(vdt)
                %get target field name 
                tfn = vdt{index}; 
                %first grab the target sub structure 
                ss = getfield(ioDataObject.DATA_TYPES,tfn); 
                %create string to compare input too
                p = [vdt(index),{ss.alias}]; 
                %now perform string compare operation 
                if any(strcmpi(valIn,p))
                    guess = tfn; guessIndex = index; 
                    break; 
                elseif notFoundFlag && (index == length(vdt))
                    switch notFoundFlag
                        case -2 %make an error dialog
                            f = errordlg(sprintf(msg,valIn), ...
                                'Data Type Mismatch Error','modal'); 
                            error(msg,valIn); 
                        case -1 %throw an error but only output to cmd line
                            error(msg,valIn); 
                        case 1 %issue waring on command line
                            warning(msg,valIn); 
                        case 2 %make warning dialog
                            f = warndlg(sprintf(msg,valIn),...
                                'Data Type Mismatch Warning','modal');
                    end 
                end
            end
        end

    end

    methods
        function this = ioDataObject(name,unit,unitPrefix, ...
                                    dataType,dataDimension,varargin)
            %I/O Data Object Construct an instance of this class
            %   Detailed explanation goes here

            %initialize the input parser
            p = inputParser; 

            %add inputs 
            addRequired(p,'Name',@(x) isa(x,'char') || isa(x,'string'))
            addRequired(p,'Unit',@(x) this.isValidUnit(x));
            addRequired(p,'UnitPrefix',@(x) this.isValidUnitPrefix(x));
            addRequired(p,'DataType',@(x) this.isValidDataType(x));
            addRequired(p,'DataDimension',@(x) this.isValidDataDimension(x));
            addParameter(p,'AccessMethod',this.accessMethod,@(x) this.isValidAccessMethod(x));
            addParameter(p,'InstrName',this.instrName,@(x) this.isValidInstrumentName(x));
            addParameter(p,'InstrAddress',this.instrAddress,@(x) this.isValidInstrumentAddress(x));
            addParameter(p,'ChannelName',this.channelName,@(x) this.isValidChannelName(x));
            addParameter(p,'MappingName',this.mappingName,@(x) isa(x,'char') || isa(x,'string')); 
            addParameter(p,'IgnoreOnImport',this.ignoreOnImport,@(x) islogical(x)); 
            addParameter(p,'InputInterpreter',...
                @(x) this.DEFAULT_INPUT_INTERPRETER(x),...
                @(x) isa(x,'function_handle')); 
            addParameter(p,'OutputInterpreter',...
                @(x) this.DEFAULT_OUTPUT_INTERPRETER(x),...
                @(x) isa(x,'function_handle'));

            %parse inputs
            p.parse(name,unit,unitPrefix,dataType,dataDimension,varargin{:});

            %assign final values
            this.name           = p.Results.Name; 
            this.unit           = p.Results.Unit; 
            this.unitPrefix     = p.Results.UnitPrefix; 
            this.dataType       = p.Results.DataType; 
            this.dataDimension  = p.Results.DataDimension; 
            this.accessMethod   = p.Results.AccessMethod; 
            this.instrName      = p.Results.InstrName; 
            this.channelName    = p.Results.ChannelName;
            %assign the mapping name (defaults to name)
            if not(isequal(p.Results.MappingName,this.mappingName))
                this.mappingName = p.Results.MappingName; 
            else
                this.mappingName = this.name;
            end
            %set import ignore flag
            this.ignoreOnImport = p.Results.IgnoreOnImport; 
            this.inputInterpreter = p.Results.InputInterpreter; 
            this.outputInterpreter = p.Results.InputInterpreter; 
        end
        function tf = checkValue(this,valIn)
            %Checks if a value complies with the assigned metadata
            %describing it 
            
            %assume that this function passes by default
            tf = true;
            
            try
                %check dimensionality match
                if not(isequal(size(valIn),this.dataDimension))
                    tf = false; return
                end
            catch
                warning(['Unable to check the value provided against ' ...
                        'the available metadata. Returning false.']);
                tf = false; return; 
            end
        end

        function dataOut = readData(this,dataIn)
            %Read Data - Reads textual form of data and returns numerical
            %form
            dataOut = this.inputInterpreter(dataIn); 
        end

        function dataOut = writeData(this,dataIn)
            %Write Data - Turns numerical form of data and returns textual
            %form
            dataOut = this.outputInterpreter(dataIn)
        end
    end

    methods (Access=private)
        function tf = isValidUnit(this,valIn)
            try
                tf = any(strcmp(valIn,ioDataObject.VALID_UNITS));
            catch
                warning('Could not check if unit provided is valid');
                tf = false; 
            end
        end
        function tf = isValidUnitPrefix(this,valIn)
            try
                tf = any(strcmp(valIn,ioDataObject.PREFIX_MAP(:,1))); 
            catch
                warning('Could not check if unit provided is valid');
                tf = false; 
            end
        end
        function tf = isValidDataType(this,valIn)
            try
                tf = any(strcmp(valIn,ioDataObject.VALID_DATA_TYPES)); 
            catch
                warning('Could not check if data type is valid');
                tf = false; 
            end
        end
        function tf = isValidDataDimension(this, valIn)
            try 
                tf = all(isnumeric(valIn)) && ...
                    (length(size(valIn))<=2) && ...
                    not(isempty(valIn));
            catch
                warning('Could not check if dimension type is valid.')
                tf = false; 
            end
        end
        function tf = isValidAccessMethod(this,valIn)
            try 
                tf = isa(valIn,'char') || isa(valIn,'string');
            catch
                warning('Unable to avlidate access method.')
                tf = false; 
            end
        end
        function tf = isValidInstrumentName(this,valIn)
            try 
                tf = isa(valIn,'char') || isa(valIn,'string');
            catch
                warning('Unable to validate access instrument name.')
                tf = false; 
            end
        end
        function tf = isValidInstrumentAddress(this,valIn)
            try 
                tf = isa(valIn,'char') || isa(valIn,'string');
            catch
                warning('Unable to validate instrument address.')
                tf = false; 
            end
        end
        function tf = isValidChannelName(this,valIn)
            try 
                tf = isa(valIn,'char') || isa(valIn,'string');
            catch
                warning('Unable to validate channel name.')
                tf = false; 
            end
        end
        function dataOut = DEFAULT_INPUT_INTERPRETER(this,dataIn)
            %% DEFAULT INPUT INTERPRETER - Interprets Input Data 
            % INPUT: 
            %   dataIn - A matrix of character cells. Rows correspond to
            %   individual data entries. Columns are interpretted as axes
            %   or components of an individual entry. 
            % OUTPUT: 
            %   dataOut- The raw data that will be stored that corresponds
            %   to the interpretted form of dataIn. 

            %first, force the size of the provided data to be at most
            %two-dimensional 
            assert(length(size(dataIn))<=2,['Size of provided data cannot exceed' ...
                'two dimensions.']); 
            
            %if the input is a character array wrap it up in a cell
            if not(iscell(dataIn))
                dataIn = {dataIn};
            end

            %next get the number of rows and columns 
            [numRows,numCols] = size(dataIn); 

            %now handle the provided data depending on the data type
            %provided 
            switch this.dataType
                case 'INT'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for INT data.'); 
                    %import the data (rounding to nearest integer)
                    dataOut = round(str2double(dataIn)); 
                case 'REAL'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for REAL data.');
                    %import the data with double precision 
                    dataOut = str2double(dataIn); 
                case 'STRING'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for STRING data.');
                    %import the data 
                    dataOut = dataIn; 
                case 'COMPLEX_R_I'
                    %the number of columns provided must be 2
                    assert(numCols==2, ...
                        'Number of columns must be 2 for COMPLEX data.');
                    %grab the components of the data
                    re = str2double(dataIn(:,1)); 
                    im = str2double(dataIn(:,2)); 
                    %now add them together to get the desired data 
                    dataOut = re + j.*im; 
                case 'COMPLEX_MAG_RAD'
                    %the number of columns provided must be 2
                    assert(numCols==2, ...
                        'Number of columns must be 2 for COMPLEX data.');
                    %grab the components of the data
                    mag = str2double(dataIn(:,1)); 
                    ang = str2double(dataIn(:,2)); 
                    %now add them together to get the desired data 
                    dataOut = mag.*exp(j.*ang);  
                case 'COMPLEX_MAG_DEG'
                    %the number of columns provided must be 2
                    assert(numCols==2, ...
                        'Number of columns must be 2 for COMPLEX data.');
                    %grab the components of the data
                    mag = str2double(dataIn(:,1)); 
                    ang = str2double(dataIn(:,2)); 
                    %now add them together to get the desired data 
                    dataOut = mag.*exp(j.*deg2rad(ang));  
                case 'COMPLEX_DB_RAD'
                    %the number of columns provided must be 2
                    assert(numCols==2, ...
                        'Number of columns must be 2 for COMPLEX data.');
                    %grab the components of the data
                    mag = str2double(dataIn(:,1)); 
                    ang = str2double(dataIn(:,2)); 
                    %now add them together to get the desired data 
                    dataOut = 10.^(mag./10).*exp(j.*ang);  
                case 'COMPLEX_DB_DEG'
                    %the number of columns provided must be 2
                    assert(numCols==2, ...
                        'Number of columns must be 2 for COMPLEX data.');
                    %grab the components of the data
                    mag = str2double(dataIn(:,1)); 
                    ang = str2double(dataIn(:,2)); 
                    %now add them together to get the desired data 
                    dataOut = 10.^(mag./10).*exp(j.*deg2rad(ang));  
                case 'BOOL'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for BOOL data.'); 
                    %now convert the data to a logical array 
                    dataOut = ismember(lower(dataIn),...
                                {'true','t','enable','1','on'}); 
                case 'BINARY'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for BINARY data.'); 
                    %read the hexidecimal data into double precision data
                    dataOut = bin2dec(dataIn); 
                case 'OCTAL'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for OCTAL data.'); 
                    %read the octal data into double precision data
                    dataOut = oct2dec(dataIn); 
                case 'HEXIDECIMAL'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for HEXIDECIMAL data.'); 
                    %read the hexidecimal data into double precision data
                    dataOut = hex2num(dataIn); 
                case 'BYTE16'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for BYTE16 data.'); 
                    %issue warning as I don't know what I'm doing.
                    warning('BYTE16 data reading may be unreliable. Reading text data as UINT16.')
                    %now read in the data 
                    dataOut = uint16(str2double(dataIn)); 
                otherwise 
                    error('Specified data type %s is not valid.', ...
                        this.dataType);
            end
        end
        function dataOut = DEFAULT_OUTPUT_INTERPRETER(this,dataIn)
            %% DEFAULT OUTPUT INTERPRETER - Takes raw data and converts to a different format
            % INPUT: 
            %   dataIn - A column array of numerical or character data 
            % OUTPUT: 
            %   dataOut- A matrix of character cells based on the input
            %   data 

           %first, force the size of the provided data to be at most
            %two-dimensional 
            assert(length(size(dataIn))<=2,['Size of provided data cannot exceed' ...
                'two dimensions.']); 

            %next get the number of rows and columns 
            [numRows,numCols] = size(dataIn); 

            %now handle the provided data depending on the data type
            %provided 
            switch this.dataType
                case 'INT'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for INT data.'); 
                    %import the data (rounding to nearest integer)
                    dataIn = round(dataIn); 
                    dataOut = cell(size(dataIn)); 
                    for index = 1:length(dataIn)
                        dataOut = [dataOut {num2str(dataIn(index))}]; 
                    end
                case 'REAL'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for REAL data.');
                    %import the data with double precision
                    dataIn = real(dataIn); 
                    dataOut = cell(size(dataIn)); 
                    for index = 1:length(dataIn)
                        dataOut(index) = num2str(dataIn(index)); 
                    end
                case 'STRING'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for STRING data.');
                    %import the data 
                    dataOut = dataIn; 

                case 'COMPLEX_R_I'
                    %the number of columns provided must be 2
                    assert(numCols==1, ...
                        'Number of columns must be 1 for COMPLEX data.');
                    %grab the components of the data
                    re = real(dataIn); 
                    im = imag(dataIn); 
                    %now add them together to get the desired data 
                    dataOut = cell(length(dataIn),2);
                    for index = 1:length(dataIn)
                        dataOut(index,1) = num2str(re); 
                        dataOut(index,2) = num2str(im); 
                    end
                case 'COMPLEX_MAG_RAD'
                    %the number of columns provided must be 2
                    assert(numCols==2, ...
                        'Number of columns must be 2 for COMPLEX data.');
                    %now add them together to get the desired data 
                    dataOut = cell(length(dataIn),2);
                    for index = 1:length(dataIn)
                        dataOut(index,1) = num2str(abs(dataIn(index)));  
                        dataOut(index,2) = num2str(angle(dataIn(index))); 
                    end
                case 'COMPLEX_MAG_DEG'
                    %the number of columns provided must be 2
                    assert(numCols==2, ...
                        'Number of columns must be 2 for COMPLEX data.');
                    %now add them together to get the desired data 
                    dataOut = cell(length(dataIn),2);
                    for index = 1:length(dataIn)
                        dataOut(index,1) = num2str(abs(dataIn(index)));  
                        dataOut(index,2) = num2str(rad2deg(angle(dataIn(index)))); 
                    end
                case 'COMPLEX_DB_RAD'
                    %the number of columns provided must be 2
                    assert(numCols==2, ...
                        'Number of columns must be 2 for COMPLEX data.');
                    %now add them together to get the desired data 
                    dataOut = cell(length(dataIn),2);
                    for index = 1:length(dataIn)
                        dataOut(index,1) = num2str(10.*log10(abs(dataIn(index))));  
                        dataOut(index,2) = num2str(angle(dataIn(index))); 
                    end
                case 'COMPLEX_DB_DEG'
                    %the number of columns provided must be 2
                    assert(numCols==2, ...
                        'Number of columns must be 2 for COMPLEX data.');
                    %grab the components of the data
                    mag = str2double(dataIn(:,1)); 
                    ang = str2double(dataIn(:,2)); 
                    %now add them together to get the desired data 
                    dataOut = cell(length(dataIn),2);
                    for index = 1:length(dataIn)
                        dataOut(index,1) = num2str(10.*log10(abs(dataIn(index))));  
                        dataOut(index,2) = num2str(rad2deg(angle(dataIn(index)))); 
                    end 
                case 'BOOL'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for BOOL data.'); 
                    %now add them together to get the desired data 
                    dataOut = cell(length(dataIn),1);
                    for index = 1:length(dataIn)
                        if dataIn(index) == true
                            dataOut(index) = 'true'; 
                        else
                            dataOut(index) = 'false'; 
                        end
                    end 
                case 'BINARY'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for BINARY data.'); 
                    %read the hexidecimal data into double precision data
                    dataIn = round(dataIn); 
                    dataOut = cell(length(dataIn),1);
                    for index = 1:length(dataIn)
                        dataOut(index) = dec2base(dataIn(index),2); 
                    end 
                case 'OCTAL'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for OCTAL data.'); 
                    %read the hexidecimal data into double precision data
                    dataIn = round(dataIn); 
                    dataOut = cell(length(dataIn),1);
                    for index = 1:length(dataIn)
                        dataOut(index) = dec2base(dataIn(index),8); 
                    end  
                case 'HEXIDECIMAL'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for HEXIDECIMAL data.'); 
                    %read the hexidecimal data into double precision data
                    dataIn = round(dataIn); 
                    dataOut = cell(length(dataIn),1);
                    for index = 1:length(dataIn)
                        dataOut(index) = dec2base(dataIn(index),16); 
                    end  
                case 'BYTE16'
                    %the number of columns provided must be 1
                    assert(numCols==1, ...
                        'Number of columns must be 1 for BYTE16 data.'); 
                    %issue warning as I don't know what I'm doing.
                    warning('BYTE16 data reading may be unreliable. Reading text data as UINT16.')
                    %read the hexidecimal data into double precision data
                    dataIn = round(dataIn); 
                    dataOut = cell(length(dataIn),1);
                    for index = 1:length(dataIn)
                        dataOut(index) = num2str(dataIn(index)); 
                    end  
                otherwise 
                    error('Specified data type %s is not valid.', ...
                        this.dataType);
            end
        end

    end
end