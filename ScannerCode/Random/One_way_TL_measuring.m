%One way transmission line measuring script
clear all;
close all;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%sig gen%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %This is the default signal generator address
sigGen = visadev("GPIB1::20::INSTR");
% 
% %We can always ask it to identify itself
% sig_gen_id = writeread(sigGen,"*IDN?");
% 
%Reset the sigGen to default settings (good practice)
writeline(sigGen,"*RST");
%Clear event and status registers (good practice)
writeline(sigGen,"*CLS");
% 
% %Use *OPC? query to wait for command completion 
% 
% %Set the power level 
% %POW:AMPL <value> (sign and four digits) <units> (DBM, MV, UV, MVEMF, UVEMF, DBUV, DBUVEMF)
% writeline(sigGen,"POW:AMPL -125.1 DBM");
% 
% %Turn RF out on or off
% %OUTP:STAT ON
% %OUTP:STAT OFF
writeline(sigGen,"OUTP:STAT ON");
% 
% %Cautomatic attenuation on/off (default on)
% %POW:ATT:AUTO ON
% %POW:ATI:AUTO OFF
% 
% %Can set a reference power level with
% % writeline(sigGen, "POW:REF <value> <units> (DB or DMB)");
% % must turn on reference power setting
% % writeline(sigGen, "POW:REF:STAT ON");
% 
% %Set freq FREQ:CW <value> (9 digits) <units> (HZ, KHZ, MHZ)
writeline(sigGen,"FREQ:CW 1000 MHZ")
% 
% %Reference freq 
% %FREQ:REF <value> <units>
% 
% %turn ref freq on/off (default off)
% %FREQ:REF:STAT ON
% %FREQ:REF:STAT OFF

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%PNA%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%0.4 - 3.6 GHz 1001 pts
%Default Keysight N5224A PNA address
PNA = visadev("GPIB1::16::INSTR");
% 
% PNA_id = writeread(PNA,"*IDN?");
% % %Reset PNA to default settings (good practice)
% % writeline(PNA,"*RST");
% % %Clear event and status registers (good practice)
% % writeline(PNA,"*CLS");
% 
% % %Set IF Bandwidth to 700 Hz
% % writeline(PNA,"SENSe1:BANDwidth 700");
% 
% %Set number of points to 1001
% writeline(PNA,"SENS:SWE:POINts 1001");
% 
% %start and stop freq
% writeline(PNA,"SENS:FREQ:STARt 4e8");
% writeline(PNA,"SENS:FREQ:STOP  36e8");
% 
% %Set sweep generation mode to Analog
% writeline(PNA,"SENSe1:SWEep:GENeration ANAL");
% 
% %Set sweep time to Automatic
% writeline(PNA,"SENSe1:SWEep:TIME:AUTO ON");




% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%multimeter%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Default HP34401A multimeter address
% multimeter = visadev("GPIB1::22::INSTR");
% 
% %Reset multimeter to default settings (good practice)
% writeline(multimeter,"*RST");
% %Clear event and status registers (good practice)
% writeline(multimeter,"*CLS");
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%power supply%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Default 6626A DC power supply address
supply = visadev("GPIB1::5::INSTR");
% supply_id = writeread(supply,"ID?");
% 
% %Reset power supply to default settings (good practice)
% writeline(supply,"*RST");
% %Clear event and status registers (good practice)
% writeline(supply,"*CLS");


for dcv = 1:0.1:4
    writeline(supply,"VSET 1,"+dcv) %DCV
    for sig_gen_p = 12:0.5:17
        pause(0.05)
        writeline(sigGen,"POW:AMPL +"+sig_gen_p+" DBM"); %Sig gen power sweep
        pause(0.05)
        writeline(PNA,"MMEMory:STORe 'D:\scarborough\OWL2d\test"+dcv*10+"v"+sig_gen_p*10+"dBm"+".s2p'")
        pause(0.05)
        if sscanf(writeread(PNA,"*OPC?"),'%d')~=1; fprintf('Command Incompleted\n'); end
        disp("MMEMory:STORe 'D:\test_for_scpi\test"+dcv*10+"v"+sig_gen_p*10+"dBm"+".s2p'")
    end
    
end
writeline(supply,"VSET 1,0.0")
writeline(sigGen,"*RST");

