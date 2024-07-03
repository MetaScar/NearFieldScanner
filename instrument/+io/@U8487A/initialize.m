function initialize(this)
%INITIALIZE Initializes the power meter 
    %do not continue of the instrument isn't alread connected
    if this.isConnected
        %turn autoaveraging off (temporary fix for now)
%         this.write('AVER:COUN:AUTO OFF;\n')
        %perform initial calibration for the meter
        this.zero; 
    else
        this.issueWarning(['Power meter not connected. ' ...
            'Initialization could not be performed.'])
    end
end

