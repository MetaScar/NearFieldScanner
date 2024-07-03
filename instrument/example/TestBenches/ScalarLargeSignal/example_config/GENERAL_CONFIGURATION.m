%% GENERAL USER CONFIGURATION FILE 

%% OPERATIONAL PARAMETERS 

%set these 
freq = linspace(6,14,31);           %list of frequency points to run over
power= 0:1:25;                      %available source power to sweep over

%amplifier biasing conditions 
AUTO_BIAS_AMPLIFIER = true;         %change to false if you want to autobias the amplifier

%Robust mode (if driver compresses over part of the band)
ROBUST_MODE             = false;    %return sweep power to lower limit, and blacklist frequencies where driver is saturated (don't error out)
ROBUST_MODE_POW_SWITCH  = 20;       %power level that will trigger robust mode. (type in inf if you don't want this to trigger)

%main loop parameters
powStepInit                     = 1;                      %dBm (nominal power step size when searching for Pavs) 
powInitOffset                   = -40;                    %dBm (power to offset by at the beginning of each frequency sweep--make this enough to cancel out driver gain.)
powInitSweep                    = -2;                     %dBm (power to offset from power found at prior frequency)
powTolerance                    = 0.05;                   %dBm (search tolerance)
powSettleTime                   = 0.5;                    %time between loops 
maxRfSourcePower                = 10;                     %power limit where driver will be damaged
TURN_SRC_PWR_OFF_BETWEEN_FREQS = false;                   %turn the source power off between sweeps
%% CALIBRATION PARAMETERS 

%location for probes 
PROBE_FP = ['C:\Users\W-band\Documents\Paul\ScalarPowerCal_Char\Thru' ...
            '\probes_thru.s2p']; 

% INPUT_OFFSET_FP = 
% OUTPUT_OFFSET_FP = 

%% PLOTTING PARAMETERS 

PLOT_RESULTS                    = true; 

 
