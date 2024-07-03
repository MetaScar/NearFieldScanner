classdef BaseInstrument2 < handle
    %BASEINSTRUMENT2 This is the basic instrument class that handles the
    %file system and basic message and error warning system of the
    %instrument function
    %   This class is the successor to the BaseInstrument class. 
    
    properties(Access=protected,Abstract)
        name;                    %name of the instrument
        manufacturer;            %name of the manufacturer of the instrument
    end

    properties(Access=protected)
        documents=struct();      %holds the structure that stores all documentation
        printOptions;            %holds the default print options for the instrument
    end

    properties(Constant = true)
        VALID_DOC_TYPES         = {'man','dat','com'};
        DOC_ROOT_PATH           = './assets';
    end

    methods(Static = true)
        function optsOut = DEFAULT_PRINT_OPTIONS
            %% Returns Default Print Options
            optsOut.IssueWarnings   = false;  
            optsOut.VerbosityLevel  = 0; 
            optsOut.MessageInset    = 0;
            optsOut.DisplayName     = false;
        end
    end
    
    methods
        function this = BaseInstrument2(varargin)
            %BASEINSTRUMENT Constructor for the BaseClass Instrument
            %   INPUTS: 
            %    PRINTOPTIONS    - Structure specifying the print options
            %                      of the instrument.
            %   OUTPUTS: 
            
            %initialize the input parser
            p = inputParser; 
            p.KeepUnmatched = true; %allow unmatched arguments

            %add arguments
            addParameter(p,'PrintOptions',...
                         templates.BaseInstrument2.DEFAULT_PRINT_OPTIONS); 

            %parse arguments 
            parse(p,varargin{:}); 
            
            %assign values 
            this.printOptions = p.Results.PrintOptions;

            %attempt to autoregister the specified instrument upon build 
            this.autoRegDocs();

            %now display all found documentation 
            this.issueMessage(1,'Finding Documents for: \n');
            this.issueMessage(1,'Instrument: %s\n',this.name);
            this.issueMessage(1,'Manufacturer: %s\n', this.manufacturer);
            guideReport(this,2)
        end
        function [dataOut] = guideReport(this,vl)
            %% Guides - Returns a string detailing the guides available
            
            if not(exist('vl','var'))
                vl = 0;
            end

            %get data for the documents
            manData = manual(this); 
            comData = commdoc(this); 
            datData = datasheet(this); 
            
            %Build the string to return
            dataOut = this.issueMessage(vl,'%d manuals found\n', ...
                      length(fieldnames(manData))); 
            dataOut = [dataOut,... 
                       this.issueMessage(vl,['%d communication ' ...
                       'guides found\n'],...
                       length(fieldnames(comData)))]; 
            dataOut = [dataOut,... 
                       this.issueMessage(vl,...
                       '%d data sheets found\n',...
                       length(fieldnames(datData)))]; 

            %send the message to the terminal, otherwise report it as a
            %string
            if nargout == 0
                this.issueMessage(vl,dataOut);
                clear("dataOut");
            end
        end
        function [manualsOut] = manual(this,index)
            %% Manual - Finds the manual for the instrument
            
            %index defaults to 1 if not provided 
            if not(exist('index','var'))
                index = 1;
            end

            %get the document fields
            docFields = fieldnames(this.documents); 

            %get matching field names 
            matches = contains(docFields,'man'); 
            iom = find(matches); 
            
            %if this is called with an output return structures for the
            %manuals
            if nargout >= 1
                %get names of the fields to return
                manualsOut = struct; 
                
                %if there aren't any manuals registered to this instrument
                %return a warning
                if isempty(iom)
                    this.issueWarning(['There are no manuals registered to ' ...
                                       'this instrument.'])
                end
                
                %find the matching manual data
                for manualIndex = iom'
                    manualsOut.(docFields{manualIndex}) = ...
                        this.documents.(docFields{manualIndex});
                end
            else
                %otherwise open the manual referred to by index 
                if index == 1 
                    if any(strcmp('man',docFields))
                        open(fullfile(this.documents.man.dir,'man.pdf'));
                    end
                else
                    %try to find the matching manual
                    manualName = sprintf('man%d',index);
                    iom = find(strcmp(docFields,manualName));
                    %if iom isn't empty open the manual
                    if not(isempty(iom))
                        open(fullfile(this.documents.(manualName).dir,...
                            [manualName '.pdf']));
                    else
                        this.issueWarning('%s does not exist.',manualName);
                    end
                end
            end
        end
        function [commsOut] = commdoc(this,index)
            %% Communication document - Finds communications document
            
            %index defaults to 1 if not provided 
            if not(exist('index','var'))
                index = 1;
            end

            %get the document fields
            docFields = fieldnames(this.documents); 

            %get matching field names 
            matches = contains(docFields,'com'); 
            iom = find(matches); 
            
            %if this is called with an output return structures for the
            %manuals
            if nargout >= 1
                %get names of the fields to return
                commsOut = struct; 
                
                %if there aren't any commdocs registered to this instrument
                %return a warning
                if isempty(iom)
                    this.issueWarning(['There are no communication ' ...
                        'documents registered to this instrument.']);
                end
                
                %find the matching manual data
                for comIndex = iom'
                    commsOut.(docFields{comIndex}) = ...
                        this.documents.(docFields{comIndex});
                end
            else
                %otherwise open the commdoc referred to by index 
                if index == 1 
                    if any(strcmp('com',docFields))
                        open(fullfile(this.documents.com.dir,'com.pdf'));
                    else
                        this.issueWarning('com does not exist.');
                    end
                else
                    %try to find the matching manual
                    commName = sprintf('com%d',index);
                    iom = find(strcmp(docFields,commName));
                    %if iom isn't empty open the commDoc
                    if not(isempty(iom))
                        open(fullfile(this.documents.(commName).dir,...
                            [commName '.pdf']));
                    else
                        this.issueWarning('%s does not exist.',commName);
                    end
                end
            end
        end
        function [dataOut] = datasheet(this,index)
            %% Data Sheet - Finds the datasheet
            
            %index defaults to 1 if not provided 
            if not(exist('index','var'))
                index = 1;
            end

            %get the document fields
            docFields = fieldnames(this.documents); 
            
            %get matching field names 
            matches = contains(docFields,'dat'); 
            iom = find(matches); 
            
            %if this is called with an output return structures for the
            %manuals
            if nargout >= 1
                %get names of the fields to return
                dataOut = struct; 
                
                %if there aren't any commdocs registered to this instrument
                %return a warning
                if isempty(iom)
                    this.issueWarning(['There are no communication ' ...
                        'documents registered to this instrument.']);
                end
                
                %find the matching manual data
                for datIndex = iom'
                    dataOut.(docFields{datIndex}) = ...
                        this.documents.(docFields{datIndex});
                end
            else
                %otherwise open the commdoc referred to by index 
                if index == 1 
                    if any(strcmp('dat',docFields))
                        open(fullfile(this.documents.dat.dir,'dat.pdf'));
                    else
                        this.issueWarning('com does not exist.');
                    end
                else
                    %try to find the matching manual
                    datName = sprintf('dat%d',index);
                    iom = find(strcmp(docFields,datName));
                    %if iom isn't empty open the commDoc
                    if not(isempty(iom))
                        open(fullfile(this.documents.(datName).dir,...
                            [datName '.pdf']));
                    else
                        this.issueWarning('%s does not exist.',datName);
                    end
                end
            end
        end
    end

    %% Setup Functions for the Subclasses
    methods(Access=protected)
        function msgOut = issueMessage(this,verbosityLevel,msg,varargin)
            %% Print Message - Prints a standard message to the terminal 
            %   This function will print a standard message to the terminal
            %   to update the user on the status of the function. 

            %make a new message
            msgOut = '';

            %check the present verbosity level 
            if verbosityLevel <= this.printOptions.VerbosityLevel
                %now add on the name and offset 
                strStart = repmat(' ',1,this.printOptions.MessageInset);
                if this.printOptions.DisplayName 
                    strStart = [strStart this.name '>'];
                end
                %now print the message 
                if nargout >= 1 %if stringn was requested instead
                    msgOut = sprintf([strStart msg],varargin{:});
                else %otherwise print to the terminal
                    fprintf([strStart msg],varargin{:});
                end
            end
        end
        function issueWarning(this,msg,varargin)
            %% Issue a Warning  - Issues a warning from the instrument class
            %   This function will print a warning message to the terminal
            %   to update the user on the status of the function.
            %check the present verbosity level 
            if this.printOptions.IssueWarnings
                %now add on the name and offset 
                strStart = repmat(' ',1,this.printOptions.MessageInset);
                if this.printOptions.DisplayName 
                    strStart = [strStart this.name '>'];
                end
                %now print the message 
                warning([strStart msg],varargin{:});
            end
        end
        function autoRegDocs(this)
            %% Attempt to Auto Register Documentation
            %  INPUTS: 
            %   instrManufacturer   [CHAR]  - Manufacturer name
            %   instrName           [CHAR]  - Name of the instrument
            %   printOptions        struct  - Optional, will default to
            %                                 false;
            
            %build grab the instrument name and manufacturer from the class
            instrName           = this.name;
            instrManufacturer   = this.manufacturer;

            %build the initial path to check
            path = fullfile(this.PATH_TO_ROOT, ...
                            templates.BaseInstrument.DOC_ROOT_PATH,...
                            instrManufacturer);
            %check if the manufacturer can be found 
            if not(exist(path,'dir'))
                %issue a warning if manufacturer wasn't found
                this.issueWarning(...
                    ['Could not find the manufacturer: %s.' ...
                        'No documentation added.'],instrManufacturer);
                %return early
                return;
            end
            
            %check if the manufacturer can be found 
            path = fullfile(path,instrName);
            if not(exist(path,'dir'))
                %issue a warning if instrument wasn't found
                this.issueWarning(...
                    ['Could not find the instrument: %s.' ...
                        'No documentation added.'],instrName);
                %return early
                return;
            end
            
            %now check if there is any documentation for this instrument 
            path = fullfile(path,'doc');
            if not(exist(path,'dir'))
                %issue a warning if instrument wasn't found
                this.issueWarning(...
                    ['Manufacturer and instrument found but no ' ...
                     'documenation is available']);
                %return early
                return;
            end

            %now iterate through each type of documentation 
            for docTypeIndex = ...
                    1:length(templates.BaseInstrument.VALID_DOC_TYPES)
                %get the present doctype 
                docType = templates.BaseInstrument.VALID_DOC_TYPES{docTypeIndex};

                %now register all available documentation of this type by
                %index

                docName = docType; docIndex = []; 
                while(exist(fullfile(path,[docName '.pdf']),"file"))
                    %add the document
                    this.registerDoc(docType,path,'');
                    %update the index 
                    if isempty(docIndex)
                        docIndex = 2; 
                    else
                        docIndex = docIndex+1;
                    end
                    %update the document type name 
                    docName = sprintf([docType,'%d'],docIndex);
                end
            end
        end
        function registerDoc(this,type,path,details)
            %% Register Documentation 
            %   type    [char]  - Type of document being added
            %                 ('man'ual,'com'mmunication,'dat'asheet)
            %   path    [char]  - Path to the specified document
            %   details [char]  - This is an optional parameter. This
            %                     defaults to ''
            
            %if not provided assume that the details are an empty string
            if not(exist('details','var'))
                details = '';
            end

            %make sure that the documentation type is valid 
            assert(any(...
                strcmp(type,templates.BaseInstrument.VALID_DOC_TYPES)),...
                '%s is not a valid documenation type.',type);

            %now make sure that the path also exists
            assert(exist(path,'dir'),...
                '%s is not a valid directory.')

            %now check if the field already exists, if it does add an index
            %to the end 
            newType = type; docIndex = [];
            while(strcmp(newType,fieldnames(this.documents)))
                %update the index 
                if isempty(docIndex)
                    docIndex = 2; 
                else
                    docIndex = docIndex+1;
                end
                %now build the new field name
                newType = sprintf([type, '%d'],docIndex);
            end

            %Build the document structure 
            docStruct.dir = path; docStruct.details = details;

            %now add the document structure to the documents property 
            this.documents.(newType) = docStruct;
        end

        function rootPath = PATH_TO_ROOT(this)
            %% Finds the Relative Path to The Assets Folder
            className = [mfilename('fullpath') '.m']; %path and name of class
            classPath = fileparts(className); %gets the path of this class
            rootPath  = fullfile(classPath, '..', '..');  
        end
    end
end