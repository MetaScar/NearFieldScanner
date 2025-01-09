clc; clear; close all

x = serialport('COM3', 115200);

go = true;

while go
    a = input('Write desired command:','s');

    if isequal(a, 'exit')
        break;
    end
%    str_a = string(a);
    % display command about to be sent
    disp(a);
    writeline(x,a);

    % get reponse
    reading = true;
    while reading
        grbl_out = readline(x);
        grbl_response = decode_unicode(strip(grbl_out));
        disp(grbl_response);

        if isequal(grbl_response, 'ok')
            reading = false;
        end
        pause(0.2); % apparantly pull at 5 Hz
    end


end

function out = decode_unicode(in_unicode)
out = string(char(in_unicode));
end