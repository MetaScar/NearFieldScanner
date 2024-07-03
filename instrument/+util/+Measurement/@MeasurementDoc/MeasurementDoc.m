classdef MeasurementDoc < handle
    %Measurement General class for storing measured/simulated data
    %   The purpose of this class is to store swept measured data and
    %   metadata necissary for analysis, reading, and writing files. 

    properties  
        Children    = SweepNodes.empty();   %container for sweep data 
                                            %(inputs and outputs)
        inputs      = ioDataObject.empty(); %handles of input metadata objects 
        outputs     = ioDataObject.empty(); %handles of output metadata objects
        parameters  = ioDataObject.empty(); %container for parameter metadat objects
        maps        = struct; 
    end

    methods


        function this = Measurment(varargin)
            %Measurement Class constructor
            %   This builds a container for measurement data and metadata 
        end

        function addMeasurement(this,inputVals,outputData)
            %Add Measurement - Adds a single measurement data point. 
            % INPUTS: 
            %   inputVals - A list of cell specifying the specific input
            %   values that the data was captured with. The order of this
            %   data must match that of the inputs io data object
            %   outputData- A cell array of output data values. This cell
            %   array must correspond to the order of outputs specified in
            %   the iodataobject
            
            %get all of the possible datatypes for the inputs
            dataTypes = {this.inputs.dataType};

            %get the present input value
            presentIV   = inputVals{1}; 
            presentDT   = dataTypes{1};
            
            %remove the current value from the array of cells
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

            %next move into the target node to either add the output data
            %or recursively build out the tree. 
            targetNode.addMeasurement(inputVals,outputData,dataTypes);
            
        end

        function childNode = findChildByValue(this,valIn,dtIn)
            %set dtIn if not provided by the user
            if not(exist('dtIn','var')) 
                dtIn = this.inputs(1).dataType; %assume its the first 
            end
            
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
            %Has Child - Returns the number of children contained by the
            %document
            numChildren = length(this.Children); 
        end    

        function initRecursiveSort(this,varargin)
            %% Initiate a Recursive Sort of All Children
            
            %grab all input variable names
            inputNames = {this.inputs.name};
            %assign default arguments (all will be ascending order
            sortArgs = repmat({'ascend'},1,length(inputNames));
            
            %build argument parser
            p = inputParser(); 

            %iteratively add optional arguments
            validationFcn = @(x) any(strcmp(x,{'ascend','descend'}));
            addParameter(p,'all','', ...
                @(x) any(strcmp(x,{'','ascend','descend'})));
            for nameIndex = 1:length(inputNames)
                addParameter(p,inputNames{nameIndex}, ...
                               sortArgs{nameIndex}, ...
                               validationFcn);
            end

            %now parse the input arguments
            parse(p,varargin{:});

            %now iteratively pull the input arguments from the results
            %table of the parser
            if strcmp(p.Results.all,{'descend','ascend'})
                sortArgs = repmat(p.Results.all,1,length(inputNames));
            else
                %iterate through each argument and assign the sort
                %arguments
                for nameIndex = 1:length(inputNames)
                    %assign the results by name 
                    sortArgs{nameIndex} = p.Results.(inputNames{nameIndex});
                end
            end

            %now perform the recursive sort operation 
            this.sortChildren(sortArgs{1});
            if not(length(sortArgs)==1) %if this isnt the final node
                for childIndex = 1:this.hasChild()
                    this.Children(childIndex).recursiveSort(sortArgs(2:end));
                end
            end
        end
        
        function [dimensions,minVals,maxVals] = buildIndexMetaData(this)

            assert(this.hasChild, ['Document needs to have children ' ...
                                    'to build indexing metadata.'])
            %get the 
            nc = this.hasChild();
            mnv = min(cell2mat({this.Children.Value}));
            mxv = max(cell2mat({this.Children.Value}));

            %now recursively build further metadata if 
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
                dimensions = [{nc} pres_nc];
                minVals = [{mnv} pres_mnv];
                maxVals = [{mxv} pres_mxv];
            else%if this document has no grand children the dimensions ares simply as follows
                dimensions = {nc};
                minVals = {mnv};
                maxVals = {mxv};
            end

        end
                
        function varargout = subsref(this,s)
            %% SUBSREF - Overload Method for the Subsref Function 
            % This allows us to index an instance of this function. In this
            % case it will pass back the stimulus and corresponding
            % response located at the specified indicies. 
            switch s(1).type
                case '.'
                    %we need to pass along function and data type calls
                    [varargout{1:nargout}] = builtin('subsref',this,s);
                case '()'
                    %assign value by index 
                    if length(s) == 1
                        %first we need to pull out any text keywords from
                        %the subscript data 
                        kwargs = []; idxargs = [];
                        for i = 1:length(s.subs)
                            presArg = s.subs{i}; 
                            if ischar(presArg) || isstring(presArg) 
                                if strcmp(presArg,{this.outputs.name})
                                    kwargs = [kwargs s.subs(i)]; 
                                elseif strcmp(presArg,':')
                                    idxargs = [idxargs s.subs(i)];
                                else
                                    error(['%s is not a valid ' ...
                                        'parameter or keyword'], ...
                                        presArg)
                                end
                            else
                                idxargs = [idxargs s.subs(i)];
                            end
                        end

                        %check that the number of dimensions matches the
                        %dimensions of the input
                        assert(length(idxargs)<=length(this.inputs), ...
                            ['Number of dimensions cannot be greatter ' ...
                            'than the number of inputs.']);
                        
                        %Next we need to pass each argument
                        [stimulus,response] = this.indexFunc(this,idxargs); 
                        varargout{1} = stimulus; 
                        varargout{2} = response; 
                    end
                case '{}'
                    %we need to pass along function and data type calls
                    [varargout{1:nargout}] = builtin('subsref',this,s);
                otherwise
                    error('Not a valid indexing expression');
            end
        end

        function ind = end(this,k,n)
            %get the size of the object
            [dim] = this.buildIndexMetaData()
            ind = dim{k};
        end
        
    end

    methods (Access=private)

        function [stimulus,response] = indexFunc(this,root,indexArgs)
            %initialize the data container
            stimulus = []; response = [];
            %get the present index parameter 
            presIndParam = indexArgs{1}; 
            %now get the index by value 
            %convert comma to all values
            if isequal(presIndParam,':')
                presIndParam = 1:length(root.Children); 
            end
            %now index this level of the array 
            if length(indexArgs)==1 %we are at the lowest level of the data
                %handle numeric and logical data differently from character
                %data 
                stimulus = {root.Children(presIndParam).Value}; 
                response = {root.Children(presIndParam).response}; 
                [nr,~] = size(stimulus); 
                if nr > 1; stimulus = stimulus'; end
                [nr,~] = size(response);
                if nr > 1; response = response'; end
            else
                for childIndex = presIndParam
                    [nData,nResponse] = ...
                            this.indexFunc(root.Children(childIndex), ...
                            indexArgs(2:end)); 
                    stimulus = [stimulus;nData];
                    response = [response;nResponse]; 
                end
                %if the root is not this object
                if not(isequal(root,this))
                    stimulus = shiftdim(stimulus,-1); 
                    response = shiftdim(response,-1);
                end
            end
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
    end
end