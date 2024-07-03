classdef VisaInstr < handle
    %VISAINSTR Generalized Visa Instrument communication interface class
    %   This class is intended to take the place of both the USBInstr and
    %   GPIB instrument classes. 
    
 properties(Access=private)
        VisaObj
        address

        %% Default Settings for All Visa Instruments 
        COMM_SINGLE_LINE_TERMINATION_CHARS = ';\n';
 end

 properties(Access=protected,Abstract)
     %% Settings and Default Values to Be Defined for Each Instrument
     COMM_NUM_RETRY;        %number of times to resend communications
     COMM_DEBUG;            %for comm-only debugging
 end
    
    methods
        function this = VisaInstr(Vendor,Address,varargin)
            %VISAINSTR Construct an instance of this class
            %   Detailed explanation goes here
            
            %initalize the argument parser 
            p = inputParser(); 
            p.KeepUnmatched=true; 

            %add arguments
            addRequired(p,'Vendor');
            addRequired(p,'Address'); 
            addParameter(p,'Retry',this.COMM_NUM_RETRY); 
            %for debugging the communication with instrument
            addParameter(p,'DebugComm',this.COMM_DEBUG,@(x) islogical(x));  

            %parse the arguments 
            parse(p,Vendor,Address,varargin{:});

            %assign the input arguments for this subclass 
            this.address            = p.Results.Address;
            this.COMM_NUM_RETRY     = p.Results.Retry;
            this.COMM_DEBUG         = p.Results.DebugComm;
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
    
    methods(Abstract)
        %method for getting error from the instrument the response should
        %be [] if there is no error present.
        response = getError(this)
    end
    

    methods(Access=protected)
        %% COMMS Functions
        function errVal = queryError(this,queryString)
            %% This is the actual function for querying an error
            % This is done in this manner to avoid exposing the visa object
            % to other classes. The query string is the instrument-specific
            % query that getError will use to determine if there is an
            % error.
            errVal = query(this.VisaObj,queryString);
        end
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
        function          write(this,txt,varargin)
            %% WRITE -- Send single line command to instrument 
            % The purpose of this command is to present a simplified
            % interface for sending commands to a VISA instrument without
            % running into line-ending issues and provided a convienent
            % means for debugging any communication errors 

            %add line termination to text if it doesn't exit 
            if not(endsWith(txt,this.COMM_SINGLE_LINE_TERMINATION_CHARS))
                txt = strcat(txt,this.COMM_SINGLE_LINE_TERMINATION_CHARS);
            end
            
            %build the message for the instrument
            msg = sprintf(txt,varargin{:}); 
            
            %print the message text before sending if in debug mode 
            if this.COMM_DEBUG
                fprintf('SENDING: %s\n',txt); 
            end

            %sent the command
            if this.isConnected
                fprintf(this.VisaObj,msg);
            else
                warning('Cannot send message. Instrument is not connected.'); 
            end
            
            %if we are in debug mode we will want to print out any errors
            if this.COMM_DEBUG
                %see if there is an error present. 
                response = this.getError(); 
                if not(isempty(response))
                    %print the message 
                    warning('Error encountered: %s',response); 
                end
            end
        end
        function valOut = read(this,txt,varargin)
            %% READ -- Send single line query to the instrument
            % The purpose of this function is to have a function that
            % behaves similarly to the sprintf function--except for
            % querying information rather than just sending it.
            % Additionally, 

            %add line termination to text if it doesn't exit 
            if not(endsWith(txt,this.COMM_SINGLE_LINE_TERMINATION_CHARS))
                txt = strcat(txt,this.COMM_SINGLE_LINE_TERMINATION_CHARS);
            end

            %build the message for the instrument
            msg = sprintf(txt,varargin{:}); 

            %print the message text before sending if in debug mode 
            if this.COMM_DEBUG
                fprintf('SENDING: %s',txt); 
            end
            
            %now send the query 
            if this.isConnected
                valOut = query(this.VisaObj,msg); 
            else
                warning('Cannot send query. Instrument is not connected.'); 
                %set valout to an empty array 
                valout = [];
                return;
            end
            
            %if we are in debug mode we will want to print out any errors
            if this.COMM_DEBUG
                %see if there is an error present. 
                response = this.getError(); 
                if not(isempty(response))
                    %print the message 
                    warning('Error encountered: %s',response); 
                end
            end
        end
    end
end

