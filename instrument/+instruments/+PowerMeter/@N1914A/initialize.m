function initialize(this,varargin)
%INITIALIZE Initializes the power meter 
    %do not continue of the instrument isn't alread connected
    %create input parser 

    if this.isConnected
        %do nothing
    else
        this.issueWarning(['Power meter not connected. ' ...
            'Initialization could not be performed.'])
    end
end

