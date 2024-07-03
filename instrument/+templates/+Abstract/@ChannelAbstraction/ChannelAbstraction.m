classdef ChannelAbstraction < handle
    %CHANNELABSTRACTION This class handles channel abstractions
    %   The purpose of this class is to allow instruments to assign names
    %   to channels and treat them as class properties. Additionally, this
    %   class is capable of "spawning" seperate objects that allow channels
    %   to be treated individually (rather than working directly with an
    %   instrument). 
    
    properties(Access=protected,Abstract)
        NUM_CHANNELS            %Number of channels on the instrument
    end

    properties(Access=protected)
        ChannelAlias            %Structure that maps names of each channel
                                %to thier corresponding index
    end
    
    methods
        function this = ChannelAbstraction(varargin)
            %CHANNELABSTRACTION Construct an abstract reference to the
            %channel
            %   Detailed explanation goes here
            
            %build an input parser 
            p = inputParser;

            %allow all parameters to be passed in (let the parser sort
            %out what to keep and what not to).
            p.KeepUnmatched = true;

            %now generate the parameterized inputs for the number of
            %channels provided 
            for chIndex = 1:this.NUM_CHANNELS
                %build the arguments for the new parameter
                args = {p, ...
                        sprintf('Channel%dName',chIndex),...
                        sprintf('Channel%d',chIndex),...
                        @(x) this.isValidNewChannelName(x)}; 
                addParameter(args{:}); 
            end

            %now parse the input arguments
            parse(p,varargin{:}); 
            
            %initialize the channel variable 
            % this.Channels = templates.Abstract.Channel.empty(0,this.NUM_CHANNELS); 

            %now construct the channel mapping 
            for chIndex = 1:this.NUM_CHANNELS
                this.ChannelAlias.(p.Results.(sprintf('Channel%dName',chIndex))) = chIndex; 
            end

        end

        function tf = isChannel(this,nameIn)
            %% Returns True if Channel Name is Recognized
            tf = any(strcmp(nameIn,fields(this.ChannelAlias)));
        end
        
        function varargout = subsref(this,s)
            %% Subsref Overloading 
            % Hook into subsref for pulling out channel name abstraction. 
            
           if strcmp(s(1).type,'.') && this.isChannel(s(1).subs) 
                %be sure to check that the argument provided first is the
                %'.' operator
                %get the channel index 
                chIndex = this.ChannelAlias.(s(1).subs); 

                %build a pattern for indexing match 
                typePattern = strcat(s(:).type);
                
                % run case statements for index pattern 
                switch typePattern
                    case '..()'
                        %This is the most typical case where a function of
                        %a channel is called. For example
                        %PSU.gate.Voltage(10V) will set the voltage of the
                        %'gate' channel to 10V
                        s(3).subs = [{chIndex} s(3).subs];
                        [varargout{1:nargout}] = ...
                            builtin('subsref',this,s(2:end));
                    case '..'
                        %This is the case where just a channel property is
                        %queried. We still need to pass the channel index
                        %back to the channel in order to process it. 

                        %create the 'fake' index operator
                        s3.subs = {chIndex}; s3.type = '()';
                        %append it to the final argument and pass it 
                        [varargout{1:nargout}] = ...
                            builtin('subsref',this,[s(2) s3]);
                    case '.'
                        %This is the least likely case where the user is
                        %trying to 'spawn' the abstraction of the channel.
                        %In this case, an object will be created that may
                        %be treated as an entity seperate from the supply
                        %that it came from. 

                        [varargout{1:nargout}] = ...
                            templates.Abstract.Channel(this,s(1).subs,chIndex); 

                    otherwise
                        error(['Unable to handle abstraction %s ' ...
                                'pattern not recognized'],typePattern);
                end                 
            else
                %implement passthrough for now 
                [varargout{1:nargout}] = builtin('subsref',this,s); 
            end
        end

        function this = subsasgn(this,s,varargin)
            %% Subsassign Overloading 
            % Overload the subsassign to employ abstract setting for a
            % given channel. 

            %implement passthrough for now 
            this = builtin('subsasgn',this,s,varargin{:}); 
        end
    end

    methods(Access=protected)
        %Validation Functions 
        function tf = isValidNewChannelName(this,nameIn)
            %% Check if the provided channel name is valid upon creation

            methodNames = methods(this); 
            propNames   = properties(this); 
            tf = all(not(strcmp(nameIn,methodNames))) && ...
                 all(not(strcmp(nameIn,propNames))) && ...
                 isvarname(nameIn); 
        end
    end
end

