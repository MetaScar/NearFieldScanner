classdef motorControl
    properties
        x
    end

    methods
        function unlockGRBL(obj)
            writeline(obj.x,'$X');
            pause(0.2);
            writeline(obj.x, "G91");
        end

        function moveXFunc(obj)
            writeline(obj.x, "G0 X5");
        end

        function obj = connectGRBL(obj)
            obj.x = serialport('COM4', 115200);
        end
    end
end