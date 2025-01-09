function results = ScalarInputCal(rfSrc,cpldPwrMtr,rfPwrMtr,srcPwr,frqLst,useWtBr)
%SCALARINPUTCAL Performs a scalar power calibration a coupler with a rf
%source (sweeper), coupled power meter, and reference power meter 
%   Inputs: 
%    rfSrc              - Handle of rf source instrument
%    cpldPwrMtr         - Handle of power meter on the coupled port
%    rfPwrMtr           - Handle of the reference power meter
%    srcPwr             - Nominal rf power of the source
%    frqLst             - List of frequency points to sweep over (in Hz)
%    useWtBr            - Boolean argument that specifies the use of a
%                         progress bar. Defaults to false. No information
%                         will be displayed if the user does not set this
%                         to true. 
%   Outputs: 
%    results            - structure array of offset data calculated by this
%                         function

%% Parameters 
WAIT_TIME = 20; STEP_TIME = 0.5; 

%% Setup the Progress Bar if Requested
if exist('useWtBr','var') && useWtBr
    wtbr = waitbar(0,'Beginning Scalar Input Calibration.');    
end

%% Setup
%initialize the rf source
if exist('wtbr','var'); waitbar(0,wtbr,'Setup: Initializing RF Source...'); end
rfSrc.set('Frequency',frqLst(1).*1e-9,'Power',srcPwr,'State','OFF'); 
pause(5); %wait for system to settle before performing calibration.


%zero out the power meters 
if exist('wtbr','var'); waitbar(0,wtbr,'Setup: Zeroing Power Meters...'); end
cpldPwrMtr.zero; 
rfPwrMtr.zero; 

TIME_STEPS = 0:STEP_TIME:WAIT_TIME; 
for step = TIME_STEPS
    %update the waitbar
    if exist('wtbr','var'); 
        waitbar(step./WAIT_TIME,wtbr,'Setup: Zeroing Power Meters...'); 
    end
    %wait a moment
    pause(STEP_TIME); 
end

%% Now Run the Loop 
%create template results container
result.cpldPwr = []; 
result.refPwr  = [];
result.offset  = []; 
result.freq    = []; 

%initialize the results array
results = repmat(result,1,length(frqLst)); 

%initialize the progress reporting variables and function handle
if exist('wtbr','var')
    numPoints = length(results); 
    progress = @(index) index./numPoints; 
end

%turn on the rf source
rfSrc.set('State','ON'); 

%now start the sweep    
for iFreq = 1:length(frqLst)
    %get the present frequency 
    freq = frqLst(iFreq); 
    %update the waitbar (if requested) 
    if exist('wtbr','var')
        waitbar(progress(iFreq),wtbr, ...
            sprintf('Running... Frequency: %0.3f GHz',freq.*1e-9))
    end
    %set the rf source frequency 
    rfSrc.set('Frequency',freq.*1e-9); 
    %wait for things to settle
    pause(0.25); 
    %set the frequency of the power meters 
    cpldPwrMtr.frequency(freq.*1e-9); 
    rfPwrMtr.frequency(freq.*1e-9); 
    %get estimated value for the cpld and ref power levels
    
    %take the measurements
    results(iFreq).sourcePower  = srcPwr;
    results(iFreq).freq         = freq; 
%     results(iFreq).cpldPwr      = cpldPwrMtr.measure(0.001); 
%     results(iFreq).refPwr       = rfPwrMtr.measure(0.001); 
    results(iFreq).cpldPwr      = cpldPwrMtr.measure('Resolution',0.001); 
    results(iFreq).refPwr       = rfPwrMtr.measure('Resolution',0.001); 
    results(iFreq).offset       = results(iFreq).refPwr - results(iFreq).cpldPwr; 
    results(iFreq).driverGain   = results(iFreq).refPwr - srcPwr; 
    
    %plot the results to the terminal if there is a waitbar
    if exist('wtbr','var')
        fprintf('##### RESULTS #####\n')
        fprintf(' Frequency: %0.3f GHz\n',results(iFreq).freq.*1e-9); 
        fprintf(' Coupled Power: %0.2f dBm\n',results(iFreq).cpldPwr); 
        fprintf(' Reference Power: %0.2f dBm\n',results(iFreq).refPwr); 
        fprintf(' Offset: %0.2f dB\n',results(iFreq).offset); 
        fprintf(' Driver Gain: %0.2f dB\n', results(iFreq).driverGain); 
        
    end
end

%turn the rfSource off 
rfSrc.set('State','OFF'); 

%if the waitbar was opened, close it 
if exist('wtbr','var')
    close(wtbr); 
end

end

