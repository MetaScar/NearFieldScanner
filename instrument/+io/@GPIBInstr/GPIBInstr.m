classdef GPIBInstr < handle
    %GPIBInstr Handles visa GPIB interface for instruments
    %   This class handles the GPIB interface communication between matlab
    %   and the instrument. It allows 
    
    properties(Access=private)
        VisaObj
        address
        numRetry    = 3;       %number of times to resend if timeout is encountered
    end
    
    methods
        function this = GPIBInstr(Vendor,Address,varargin)
            %GPIBInstr Construct an instance of this class
            %   Detailed explanation goes here
            
            %initalize the argument parser 
            p = inputParser(); 
            p.KeepUnmatched=true; 

            %add arguments
            addRequired(p,'Vendor');
            addRequired(p,'Address'); 
            addParameter(p,'Retry',this.numRetry); 

            %parse the arguments 
            parse(p,Vendor,Address,varargin{:});

            %assign the input arguments for this subclass 
            this.address    = p.Results.Address;
            this.numRetry   = p.Results.Retry;
                    
            if not(isempty(this.address)) %if user provided an address
                %create the visa object
                this.VisaObj = visa(p.Results.Vendor,this.address);
                
                %setup the visa object
                this.setupVisa(varargin{:}); 

                %now connect to the instrument 
                this.connect;
            end
        end
    end

    methods(Access=protected)
        %% COMMS Functions (Will probably replace with subclass in future)
        function          setupVisa(this,varargin)
            %% Check and Reshape
            %number of arguments must be even
            assert(mod(length(varargin),2)==0, ...
                'Number of arguments must be even.'); 
            %reshape the data so each row corresponds to a
            %parameter/argument pair 
            args = reshape(varargin,2,length(varargin)/2)';
            %% Parse and Pass Visa Parameters 
            %number of parameter argument pairs
            nPairs = size(args,1); 
            for argIndex = 1:nPairs
                %see if the parameter starts with 'visa'
                iom = strfind(args{argIndex,1},'visa'); 
                %if match found at 1 we can parse and pass the argument to
                %the visa object
                if not(isempty(iom)) && iom == 1
                    %parse the arguments
                    presParam = strrep(args{argIndex,1},'visa',''); 
                    presArg   = args{argIndex,2}; 
                    %now assign it to the visa address 
                    try 
                        this.VisaObj.(presParam) = presArg; 
                    catch
                        warning('Unrecognized parameter %s',presParam);
                    end
                end
            end
        end
        function          connect(this)
            %% Connect - Connects to the visa instrument 
            if not(isempty(this.address))
                %open the object for communication 
                fopen(this.VisaObj); 
            end
        end
        function          disconnect(this)
            %% Disconnect - Disconnects the instrument 
            if isa(this.VisaObj,'visa') && this.isConnected
                fclose(this.VisaObj);
            end
        end
        function tf     = isConnected(this)
            %% Check if Instrument is Connected
            %if visa object is not setup return false
            try 
                if isa(this.VisaObj,'visa') && ...
                        strcmp(this.VisaObj.status,'open')
                    tf = true;
                else
                    tf = false; 
                end
            catch
                tf = false; 
            end
        end
        function          write(this,varargin)
            %% WRITE -- Wrapper for transmitting to the instrument
            if this.isConnected
                fprintf(this.VisaObj,varargin{:});
            else
                warning('Cannot send message. Instrument is not connected.'); 
            end
        end
        function valOut = read(this,varargin)
            %% READ -- Wrapper for querying the instrument
            if this.isConnected
                valOut = query(this.VisaObj,varargin{:}); 
            else
                warning('Cannot send query. Instrument is not connected.'); 
            end
        end
    end
end

