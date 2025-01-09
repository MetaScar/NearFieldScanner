%% EQUIPMENT CONFIGURATION FILE 

%% Addresses

%rf source
RF_SOURCE_ADR           = 'GPIB1::20::INSTR'; 

%power meter
RF_INPUT_POWER_ADR      = 'USB0::0x2A8D::0xA618::MY57390007::0::INSTR'; 
RF_OUTPUT_POWER_ADR     = 'USB0::0x2A8D::0xA618::MY57390010::0::INSTR'; 

%power supplies
MMIC_PSU_ADR            = 'GPIB1::5::INSTR'; 
EQUIP_PSU_ADR           = 'GPIB1::4::INSTR'; 

%multimeter addresses
MUILTIMETER1_ADR        = 'GPIB1::19::INSTR'; %drain current
MUILTIMETER2_ADR        = 'GPIB1::22::INSTR'; %drain voltage


%% Instrument Initialization and Abstraction 

%for rf source...
rfSource    = instruments.SigGen.k83650A('Address',RF_SOURCE_ADR); 

%for power meters...
powerMeter  = instruments.PowerMeter.N1914A('Address',POWER_METER_ADR, ...
                                            'Channel1Name','pwrmeterIn',...
                                            'Channel3Name','pwrmeterOut'); 
%create channel abstractions 
pwrmeterIn  = powerMeter.pwrmeterIn;  %for measuring Pavs 
pwrmeterOut = powerMeter.pwrmeterOut; %for measuring Pout

%for supplies...
supplyMMIC  = instruments.PSU.E3649A('Address',MMIC_PSU_ADR,...
                                     'Output1Name','drain',...
                                     'Output2Name','gate', ...
                                     'Channel1Name','drain',...
                                     'Channel2Name','gate'); 

%create abstractions 
gate    = supplyMMIC.gate; 
drain   = supplyMMIC.drain; 

%for mulitmeters...
idMeter = instruments.Multimeter.k34410A('Address', MUILTIMETER1_ADR); 
vdMeter = instruments.Multimeter.k34410A('Address', MUILTIMETER2_ADR); 

