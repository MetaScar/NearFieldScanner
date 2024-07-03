classdef Channel < handle
    %CHANNEL Simple class for handling arguments for channel abstractions
    %   Detailed explanation goes here
    
    properties(Access = private)
        Name
        Index
        Instrument
    end
    
    methods
        function this = Channel(Instrument,Name,Index)
            %CHANNEL Construct an instance of this class
            %   Detailed explanation goes here
            this.Instrument     = Instrument; 
            this.Name           = Name; 
            this.Index          = Index; 
        end

        function varargout = subsref(this,s)
            %% Overload The Subsref Function for the Channel 
            %update the final argument
            %have to use the builtin subsref function 
            
            if strcmp(s(1),'.') && any(strcmp(s(1).subs,{'Instrument','Name','Index'}))
                %this allows access to the key 
                [varargout{1:nargin}] = builtin('subsref',this,s);
            else
                if strcmp(s(end).type,'()')
                    s(end).subs = [{this.Index} s(end).subs];
                else
                    sEnd.type = '()'; sEnd.subs = {this.Index}; 
                    s = [s,sEnd];
                end
                %now send it to the base instrument
                [varargout{1:nargout}] = builtin('subsref',this.Instrument,s); 
            end
        end
    end
end

