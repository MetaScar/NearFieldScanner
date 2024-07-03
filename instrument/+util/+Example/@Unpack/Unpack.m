classdef Unpack < handle
    %UNPACK 
    %   Detailed explanation goes here
    
    properties
        root        = [];
        examplePath = [];
    end

    methods(Static)

    end
    
    methods
        function this = Unpack(varargin)
            %UNPACK Construct an instance of this class
            
            %% Get the relatively path to the example directory 
            this.root = this.getExamplePath;

            %% Handle Input Arguments
            %create the input parser
            p = inputParser; 
            % Add Parameters
            addParameter(p,'Target',examplePath);  %Target project name/path
            addParameter(p,'ToDirectory',[]);      %Directory to move example to
            addParameter(p,'LaunchUI',false);      %Set to true if you want to launch the UI
            % Parse Input Arguments
            parse(p,varargin{:});
        end

        function launchUI(this)
            warning('UI not developed yet for this feature.')
        end
    end
    methods(Access=private)
        function rootPath = getExamplePath(this)
            className = [mfilename('fullpath') '.m']; 
            classPath = fileparts(className);
            rootPath  = fullfile(classPath, '..', ...
                                            '..', '..', ...
                                            'example');  
        end
    end
end

