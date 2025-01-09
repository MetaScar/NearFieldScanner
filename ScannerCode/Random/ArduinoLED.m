clc; clear; close all


x = serialport('COM4', 9600);
a = arduino;

go = true;

while go
    a = input('Press 1 to turn ON LED & 0 to turn OFF:');
    str_a = string(a);
    writeline(x,str_a);
    if (a == 2)
        go = false;
    end
end
