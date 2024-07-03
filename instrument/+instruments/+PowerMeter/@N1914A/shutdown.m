function shutdown(this)
%SHUTDOWN (Emergency) shutdown method for the power meter
%   Do nothing 
    if this.isConnected
        %run shutdown procedures for the power meter here.
    else
        %do nothing
    end
end

