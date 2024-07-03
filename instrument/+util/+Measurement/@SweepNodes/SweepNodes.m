classdef SweepNodes < handle
    %Measurement Sweep container for swept measurement data 
    %   This class contains metadata on the performed sweep. A summary of
    %   the important metadata is as follows: 
    %   DEPTH           - This is the number of nested input sweeps. 
    %   SWEEPBINDINGS   - This 

    properties
        Children=SweepNodes.empty();      %Sweeps nested below this one
        Parent;                           %Parent of this node
        Value;                            %Value of the stimuli for this 
                                          % sweep node
        response;                         %Handle of response data node; 
    end

    methods
        function this = SweepNodes(p,v)
            %Sweep Makes a new sweep class
            %   Detailed explanation goes here
            %do nothing at this point
            this.Parent = p; 
            this.Value  = v; 
        end
        
        % function registerStimuli(this,stimuli,value)
        %     %Register Stimuli - Registers a new stimulus with a value to
        %     %this sweep. 
        %     %   INPUTS: 
        %     %    STIMULI - Handle of stimuli io object.  
        %     %    VALUE   - Value of the stimulus response. 
        % 
        %     %first, check that the io data object is valid
        %     assert(isa(stimuli,'ioDataObject'),...
        %         'Provided stimuli is not a valid data object.'); 
        %     %second, check that the provided value of the data object is
        %     %acceptable 
        %     assert(stimuli.checkValue(value),...
        %         ['Value or dimensionality of data provided is not the ' ...
        %         'same as the type registered to this input.'])
        %     %if both checks are passed we can register the stimuli
        %     this.stimuli = [this.stimuli; {stimuli,value}]; 
        % end
        
        % function registerResponse(this,response,value)
        %     %Register Stimuli - Registers a new stimulus with a value to
        %     %this sweep. 
        %     %   INPUTS: 
        %     %    RESPONSE - Handle of response io object.  
        %     %    VALUE    - Value of the stimulus response. 
        % 
        %     %first, check that the io data object is valid
        %     assert(isa(response,'ioDataObject'),...
        %         'Provided stimuli is not a valid data object.'); 
        %     %second, check that the provided value of the data object is
        %     %acceptable 
        %     assert(response.checkValue(value),...
        %         ['Value or dimensionality of data provided is not the ' ...
        %         'same as the type registered to this input.'])
        %     %if both checks are passed we can register the response
        %     this.response = [this.response; {response,value}]; 
        % end

        function addChild(this,varargin)
            %Add Sub Sweep - Adds a sub sweep to the measurement 

            %initialize input parser 
            p = inputParser; 

            %now add parameters for adding a sub sweep 
            addParameter(p,'Sweep', SweepNodes(), @(x) this.isValidSubSweep(x)); 
            addParameter(p,'Index', 'end', @(x) this.isValidSubSweepLocation(x));
            
            %parse the input arguments
            p.parse(varargin{:}); 

            %now process the input arguments 
            loc = p.Results.Index; swp = p.Results.Sweep; 

            if ~isnumeric(loc) 
                %if 'end' was requested 
                this.Children = [this.Children,swp]; 
            else
                %now handle the case where a number was requested
                if loc == 1
                    %if 1 is requested we just add this to the first
                    %element
                    this.Children = [swp this.Children];
                else
                    %otherwise we insert the this new sweep before the
                    %specified index
                    this.Children = [this.Children(1:(loc-1)), ...
                                      swp,...
                                      this.Children(loc:end)]; 
                end
            end
        end
        function addMeasurement(this,inputVals,outputVals,dataTypes)
            %Add Measurement - Adds a single measurement data point. 
            % INPUTS: 
            %   inputVals - A list of cell specifying the specific input
            %   values that the data was captured with. The order of this
            %   data must match that of the inputs io data object
            %   outputData- A cell array of output data values. This cell
            %   array must correspond to the order of outputs specified in
            %   the iodataobject

            %get the present input value
            presentIV   = inputVals{1}; 
            presentDT   = dataTypes{1};
            
            if length(inputVals)>1
                inputVals = inputVals(2:end); 
                dataTypes = dataTypes(2:end);
            else
                inputVals = [];
                dataTypes = [];
            end

            %find the child node that has the value we are looking for
            targetNode = SweepNodes.empty();
            if not(isempty(this.Children))
                targetNode = this.findChildByValue(presentIV,presentDT);
            end
            
            %if we didn't find the node of interest add a new one 
            if isempty(targetNode)
                targetNode = SweepNodes(this,presentIV); 
                this.Children = [this.Children targetNode];
            end
            
            %either attach the data or move into the next node if there
            %isn't a new set of input values to send in
            if isempty(inputVals) %if this is the end of the line
                targetNode.response = outputVals; 
            else%if we still have more data to add
                targetNode.addMeasurement(inputVals,outputVals,dataTypes);
            end
            
        end
        function swp = popSubSweep(this,varargin)
            %Remove Sub Sweep - Removes a sub sweep to the measurement 
            
            %assign an initial value to the response
            swp = [];

            %first check that there's something to return 
            if isempty(this.Children)
                warning(['Cannot pop the sub sweep as' ...
                    ' there are no sweeps present.']);
                return;
            end

            %initialize input parser 
            p = inputParser; 

            %now add parameters for adding a sub sweep 
            addParameter(p,'Index', 'end', ...
                @(x) this.isValidSubSweepLocation(x));
            
            %parse the input arguments
            p.parse(varargin{:}); 

            %now process the input arguments 
            loc = p.Results.Index; 
            
            %get the sweep to return 
            if not(isnumeric(loc))
                %if 'end' was provided as an argument
                swp = this.Children(end); 
                this.Children = this.Children(1:(end-1));
            else
                swp = this.Children(loc);      %
                this.Children(loc) = [];       %set value at location to empty
            end
        end
        function childNode = findChildByValue(this,valIn,dtIn)
            %default return value 
            childNode = SweepNodes.empty();

            %search through all child nodes at this node and return it if
            %found
            if isequal(dtIn,'STRING')
                vals    = {this.Children.Value};
                iom     = find(strcmp(vals,valIn));
            else
                vals    = [this.Children.Value]; 
                iom     = find(valIn==vals); 
            end
            
            %if the node was found return it
            if not(isempty(iom))
                childNode = this.Children(iom);
            end         
        end
        function numChildren = hasChild(this)
            %% Has Child - Returns the number of children that this node 
            numChildren = length(this.Children);
        end
        function sortChildren(this,direction)
            %% Function Sorts Children by Value
            % This function will sort the children of the object based on
            % their values. 
            %   INPUTS: 
            %    direction - optional argument that can either be 'ascend'
            %    or 'descend'. Will default to ascend if no argument is
            %    provided or if the input argument is wrong.
            %handle
            
            %only continue if this node has children
            if not(this.hasChild)
                return
            end

            %handle the case where the direction variable is not provided
            %or isn't recognized.
            if not(exist('direction','var'))
                direction = 'ascend'; 
            elseif not(strcmpi(direction,{'ascend','descend'}))
                warning(['Sorting argument provided, %s, ' ...
                         'is neither ascend nor descend. ' ...
                         'Using ascend instead.'],direction);
                direction = 'ascend'; 
            end
            
            %capture all values 
            vals = {this.Children(:).Value}; 
            v1 = vals{1};
            %the data may be either numeric, logical, or character
            if isnumeric(v1) || islogical(v1)
                %convert cell array to numeric (or logical) array
                vals = cell2mat(vals); 
                %next sort the data getting the updated indices
                [~,I] = sort(vals,direction); 
            else
                %convert cell array to numeric (or logical) array
                vals = string(vals); 
                %next sort the data getting the updated indices
                [~,I] = sort(vals,direction); 
            end

            %now reassign children based off of the index table that was
            %provided 
            this.Children = this.Children(I); 
        end
        function recursiveSort(this,sortArgs)
            %% Recursive Sorting - Sorts all levels of the heirarchy
            this.sortChildren(sortArgs{1})%sort all children first
            if not(length(sortArgs)==1)%if this isn't the final node
                for childIndex = 1:this.hasChild() %call this operation on all children
                    this.Children(childIndex).recursiveSort(sortArgs(2:end)); %only pass next args
                end
            end
        end
        function [numChildren,minVals,maxVals] = indexMetadata(this)
            %% Returns indexing metadata of this and any children
            try
            nc = this.hasChild(); 
            mnv = min(cell2mat({this.Children.Value})); 
            mxv = max(cell2mat({this.Children.Value}));
            catch
                disp('pause')
            end
            %set up variables for comparing children dimensions with one
            %another
            if this.Children(1).hasChild()
                best_nc = 0; best_mnv = inf; best_mxv = -inf; 
                pres_nc = {}; pres_mnv = {}; 
                for childIndex = 1:this.hasChild()
                    [pres_nc,pres_mnv,pres_mxv] = this.Children(childIndex).indexMetadata(); 
                    %update the best values
                    best_nc = max([pres_nc{1},best_nc]); 
                    best_mnv = min([pres_mnv{1},best_mnv]); 
                    best_mxv = max([pres_mxv{1},best_mxv]);
                end
                
                %handle the case where the depth is 2 or more
                if length(pres_nc)>1 
                    pres_nc = [{best_nc} pres_nc(2:end)]; 
                    pres_mnv = [{best_mnv} pres_mnv(2:end)]; 
                    pres_mxv = [{best_mxv} pres_mxv(2:end)]; 
                else
                    pres_nc = {best_nc};
                    pres_mnv = {best_mnv}; 
                    pres_mxv = {best_mxv}; 
                end
                
                %return the results at the present node
                numChildren = [{nc} pres_nc];
                minVals = [{mnv} pres_mnv];
                maxVals = [{mxv} pres_mxv];
            else
                numChildren = {nc};
                minVals = {mnv};
                maxVals = {mxv};
            end
        end
    end

    methods (Access = private)
        function tf = isValidSubSweep(this,valIn)
            try
                tf = isa(valIn,'Sweep');
            catch
                warning(['Error in isValidSubSweep. ' ...
                    'Could not check if object provided ' ...
                    'is a instance of the sweep class.'])
                tf = false; 
            end
        end
        function tf = isValidSubSweepLocation(this,valIn)
            try
                if isa(valIn,'char') || isa(valIn,'string')
                    %check if end was provided
                    tf = strcmpi(valIn,'end'); 
                elseif isnumeric(valIn) 
                    %check if numeric value was provided
                    tf = any(valIn == 1:length(this.Children)); 
                end
            catch
                warning(['Error in isValidSubSweepLocation. ' ...
                    'Could not check if object provided ' ...
                    'is a valid location in the sub sweep array.'])
                tf = false; 
            end
        end
    end
end

