%% Set Output Voltage and Make Measurements on Agilent 6266A Power Supply using the _ Driver
% This example shows the use of MATLAB with an IVI driver to connect to,
% configure and measure AC voltage using Keysight Technologies AC6801A
% power supply and output the result in MATLAB(R).

%%
% Copyright 2015 The MathWorks, Inc.

%% Requirements
% This example requires the following to be installed on the computer:
%
% * Keysight IO libraries version 17.1 or newer
% * Keysight AC6800 AC Power Supplies IVI version 1.0.3.0 or newer
% 

%% Enumerate available IVI-C drivers on the computer
% This enumerates the IVI drivers that have been installed on the computer.
IviInfo = instrhwinfo('ivi');
IviInfo.Modules

%% Create MATLAB Instrument Driver And Connect To The Instrument

% Create the MATLAB instrument driver
makemid('Agilent 8648','Agilent_8648.mdd')

% Use icdevice with the MATLAB instrument driver name and instrument's 
% resource name to create a device object. In this example the instrument 
% is connected by GPIB at board index 0 and primary address 1.
myInstrument = icdevice('hp662xa.mdd', 'GPIB0::04::INSTR','optionstring','simulate=false');

% Connect driver instance
connect(myInstrument);


%% Attributes Definition and Variables Definition

% Attributes Definition. These values are defined in the driver's header file, 'AgAC6800.h'
IVI_ATTR_BASE= 1000000;
IVI_SPECIFIC_ATTR_BASE = IVI_ATTR_BASE + 150000;
AGAC6800_ATTR_OUTPUT_PHASE_VOLTAGE_SOFT_LIMIT_ENABLED = IVI_SPECIFIC_ATTR_BASE + 15;
AGAC6800_VAL_MODE_AC_DC = 2;
AGAC6800_ATTR_PROTECTION_CURRENT_PROTECTION_ENABLED = IVI_SPECIFIC_ATTR_BASE + 37;
AGAC6800_VAL_MEASUREMENT_TYPE_VOLTAGERMS = 0;
AGAC6800_VAL_MEASUREMENT_TYPE_CURRENTRMS = 1;
AGAC6800_VAL_MEASUREMENT_TYPE_VOLTAGEDC = 3;
AGAC6800_VAL_MEASUREMENT_TYPE_CURRENTDC = 4;
AGAC6800_VAL_MEASUREMENT_TYPE_POWER_FACTOR = 5;
AGAC6800_VAL_MEASUREMENT_TYPE_CREST_FACTOR = 6;
AGAC6800_VAL_MEASUREMENT_TYPE_CURRENT_PEAK = 7;
AGAC6800_VAL_MEASUREMENT_TYPE_POWERVA = 8;
AGAC6800_VAL_MEASUREMENT_TYPE_POWERDC = 9;
AGAC6800_VAL_MEASUREMENT_TYPE_POWER_REACTIVE = 12;
AGAC6800_VAL_MEASUREMENT_TYPE_VOLTAGEACDC = 13;
AGAC6800_VAL_MEASUREMENT_TYPE_CURRENTACDC = 14;
AGAC6800_VAL_MEASUREMENT_TYPE_POWER_REAL = 19;
AGAC6800_VAL_MEASUREMENT_TYPE_POWER_REALACDC = 15;
AGAC6800_VAL_MEASUREMENT_TYPE_POWERVAACDC = 16;
AGAC6800_VAL_MEASUREMENT_TYPE_POWER_REACTIVEACDC = 17;
AGAC6800_VAL_MEASUREMENT_TYPE_POWER_FACTORACDC = 18;

% Variables Definition. These values are being passed to the driver.
AcVolts = 1;
AcAmps = 0.2;
Freq = 50;
LoVolt = 0.9 * AcVolts;
HiVolt = 1.1 * AcVolts;
DcVolts = 5;
DcAmps = 1;

%% Get General Device Properties
% Query information about the driver and instrument

AttributeAccessors = get(myInstrument, 'Attributeaccessors');   
DriverIdentification = get(myInstrument,'Inherentiviattributesdriveridentification');
DCGeneration = get(myInstrument,'Dcgeneration');
InstrumentIdentification = get(myInstrument,'Inherentiviattributesinstrumentidentification');
InstrumentModel = get(InstrumentIdentification, 'Instrument_Model');
InstrumentSpecificMeasurement = get(myInstrument, 'Instrumentspecificmeasurement');
InstrumentSpecificOutputPhaseCurrent = get(myInstrument,'Instrumentspecificoutputphasecurrent');
InstrumentSpecificOutputPhaseFrequency = get(myInstrument, 'Instrumentspecificoutputphasefrequency');
InstrumentSpecificOutputPhaseVoltage = get(myInstrument,'Instrumentspecificoutputphasevoltage');
InstrumentSpecificOutputPhaseVoltageSoftLimit = get(myInstrument,'Instrumentspecificoutputphasevoltagesoftlimit');
InstrumentSpecificSystem = get(myInstrument, 'Instrumentspecificsystem');
Output = get(myInstrument,'Output');
Outputs = get(myInstrument,'Outputs');
Utility = get(myInstrument, 'Utility');

Revision = invoke(Utility, 'revisionquery');
Vendor = get(DriverIdentification, 'Specific_Driver_Vendor');
Description = get(DriverIdentification, 'Specific_Driver_Description');
FirmwareRev = get(InstrumentIdentification, 'Instrument_Firmware_Revision');

% Print the queried driver properties
fprintf('Revision:        %s\n', Revision);
fprintf('Vendor:          %s\n', Vendor);
fprintf('Description:     %s\n', Description);
fprintf('InstrumentModel: %s\n', InstrumentModel);
fprintf('FirmwareRev:     %s\n', FirmwareRev);
fprintf(' \n');

%% Enable Auto-Ranging and Configure Output AC Voltage, Current and Frequency

% Enable the voltage auto range so that the maximum current will be
% supplied for the voltage setting
set(InstrumentSpecificOutputPhaseVoltage, 'Auto_Range', true);

% Set voltage level to 120 V    
set(Output, 'Voltage_Level', AcVolts);

% Set output phase current limit to 4 A    
invoke(Output, 'configurecurrentlimit', 'OutputPhase1',AcAmps);

% Set output phase frequency level to 50 Hz    
invoke(Outputs, 'configurefrequency', 50);

%% Configure Phase Voltage Soft Limit
% The AC sources also allow you to set some protection features.  The first
% one is soft limits.  For this example, the limits will be +/- 10%.

% Set output phase voltage soft limit lower limit to 108 V    
set(InstrumentSpecificOutputPhaseVoltageSoftLimit, 'Lower_Limit', LoVolt);

% Set output phase voltage soft limit upper limit to 132 V    
set(InstrumentSpecificOutputPhaseVoltageSoftLimit, 'Upper_Limit', HiVolt);

% Enable the output phase voltage soft limit   
invoke(AttributeAccessors, 'setattributeviboolean', 'OutputPhase1', AGAC6800_ATTR_OUTPUT_PHASE_VOLTAGE_SOFT_LIMIT_ENABLED, 1);

%% Configure Output DC Voltage And Current 

% Set output voltage generation mode to AC Plus DC. Set the DC voltage level to 5 V       
invoke(DCGeneration, 'configuredc', 'OutputPhase1',AGAC6800_VAL_MODE_AC_DC,DcVolts);

% Set the output phase current DC limit to 1 A    
set(InstrumentSpecificOutputPhaseCurrent, 'Dc_Limit', DcAmps);

%% Enable Current Protection Feature and Turn the Output On
% There is also current protection to enable.  The instrument will go into
% protect when it hits current limit

% Enable the current protection
invoke(AttributeAccessors, 'setattributeviboolean', '', AGAC6800_ATTR_PROTECTION_CURRENT_PROTECTION_ENABLED, 1);

% Enable output    
set(Output, 'Enabled', 1);

% Wait for operation to complete.    
invoke(InstrumentSpecificSystem, 'systemwaitforoperationcomplete', 1000); % Wait for 1000ms maximum

%% Make Voltage Measurements 
% The AC Source can take a bunch of measurements.  Once you do one, you can
% fetch the rest from the same acquisition
fprintf('Voltage Measurements\n');       

VoltAC = invoke(InstrumentSpecificMeasurement, 'measurementmeasure', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_VOLTAGERMS);
fprintf('Measured AC Voltage %0.15g V\n', VoltAC);		

VoltDC = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_VOLTAGEDC);
fprintf('Fetched DC Voltage = %0.15g V\n', VoltDC);

VoltACDC = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_VOLTAGEACDC);
fprintf('Fetched AC+DC Voltage = %0.15g V rms\n', VoltACDC);

%% Make Current Measurements
fprintf('\nCurrent Measurements\n');

CurrAC = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_CURRENTRMS);
fprintf('Fetched AC Current = %0.15g A rms\n', CurrAC);

CurrDC = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_CURRENTDC);
fprintf('Fetched DC Current = %0.15g A\n', CurrDC);

CurrACDC = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_CURRENTACDC);
fprintf('Fetched AC+DC Current = %0.15g A rms\n', CurrACDC);

PeakCurr = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_CURRENT_PEAK);
fprintf('Fetched Peak Current = %0.15g A\n', PeakCurr);

CresFact = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_CREST_FACTOR);
fprintf('Fetched Crest Factor = %0.15g\n', CresFact);

%% Make Power Measurements
fprintf('\nPower Measurements\n');

RealPow = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_POWER_REAL);
fprintf('Fetched AC Real Power = %0.15g W\n', RealPow);

ApparPow = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_POWERVA);
fprintf('Fetched AC Apparent Power = %0.15g VA\n', ApparPow);

ReactPow = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_POWER_REACTIVE);
fprintf('Fetched AC Reactive Power = %0.15g VAR\n', ReactPow);

DCPow = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_POWERDC);
fprintf('Fetched DC Power = %0.15g W\n', DCPow);

PowFact = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_POWER_FACTOR);
fprintf('Fetched Power Factor = %0.15g\n', PowFact);

RealPowACDC = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_POWER_REALACDC);
fprintf('Fetched AC+DC Real Power = %0.15g W\n', RealPowACDC);

ApparPowACDC = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_POWERVAACDC);
fprintf('Fetched AC+DC Apparent Power = %0.15g VA\n', ApparPowACDC);

ReactPowACDC = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_POWER_REACTIVEACDC);    
fprintf('Fetched AC+DC Reactive Power = %0.15g VAR\n', ReactPowACDC);

PowFactACDC = invoke(InstrumentSpecificMeasurement, 'measurementfetch', 'Measurement1', AGAC6800_VAL_MEASUREMENT_TYPE_POWER_FACTORACDC);
fprintf('Fetched AC+DC Power Factor = %0.15g\n', PowFactACDC);
fprintf('\n');

%% Query and Display any Errors

% If there are any errors, query the driver to retrieve and display them.
ErrorNum = 1;
while (ErrorNum ~= 0)
    [ErrorNum, ErrorMsg] = invoke(Utility, 'errorquery');
    fprintf('ErrorQuery: %d, %s\n', ErrorNum, ErrorMsg);
end

%% Disconnect Device Object And Clean Up
disconnect(myInstrument);
% Remove instrument objects from memory.
delete(myInstrument);

%%



%% Additional Information:
% This example shows setting output voltage and make power measurements
% from a power supply using the IVI driver. Once the measured power data
% is retrieved from the instrument, MATLAB can be used to visualize and
% perform analyses on the data using the rich library of functions in the
% Signal Processing Toolbox(TM) and Communications Systems Toolbox(TM).
% Using Instrument Control Toolbox(TM), it is possible to automate control
% of instruments, and, build test systems that use MATLAB to perform
% analyses that may not be possible using the built-in capability of the
% hardware.
