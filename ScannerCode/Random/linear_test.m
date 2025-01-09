% a = arduino();
% configurePin(a,'D9','PWM')
% writePWMVoltage(a, 'D9', 5)
% writePWMDutyCycle(a, 'D9', 0.1)
% writeDigitalPin(a, 'D11', 1)
% pause(5)
% writeDigitalPin(a, 'D11', 0)
% writePWMDutyCycle(a, 'D9', 0.5)
% pause(5)
% writeDigitalPin(a, 'D11', 1)
% writePWMDutyCycle(a, 'D9', 0.9)
% pause(5)
% writePWMDutyCycle(a, 'D9', 0.0)
clear all
clc

% x=serialport('COM3', 115200);
% x=serial('COM3');

% configurePin(a,'D11','Tone')
% playTone(a, 'D11', 500, 5)
% 
% writeDigitalPin(a, 'D10', 1)

% writeDigitalPin(a, 'D9', 1)
% pause(5)
% writeDigitalPin(a, 'D9', 0)

for i = 1:100
writeDigitalPin(a, 'D9', 1);
writeDigitalPin(a, 'D10', 0);
writeDigitalPin(a, 'D11', 0);
writeDigitalPin(a, 'D12', 1);
pause(0.0002);
writeDigitalPin(a, 'D9', 0);
writeDigitalPin(a, 'D10', 0);
writeDigitalPin(a, 'D11', 1);
writeDigitalPin(a, 'D12', 1);
pause(0.0002);
writeDigitalPin(a, 'D9', 0);
writeDigitalPin(a, 'D10', 1);
writeDigitalPin(a, 'D11', 1);
writeDigitalPin(a, 'D12', 0);
pause(0.0002);
writeDigitalPin(a, 'D9', 1);
writeDigitalPin(a, 'D10', 1);
writeDigitalPin(a, 'D11', 0);
writeDigitalPin(a, 'D12', 0);
pause(0.0002);
end