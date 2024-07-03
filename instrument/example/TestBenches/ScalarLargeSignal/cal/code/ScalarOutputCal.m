function results = ScalarOutputCal(rfSrc,inPwrMtr,outPwrMtr,srcPwr,inCalResults,useWtBr)
%SCALAROUTPUTCAL Performs a scalar power aclibration of output network with
% an rf source (sweeper), coupled power meter, and reference power meter 
%   Inputs: 
%    rfSrc              - Handle of rf source instrument
%    inPwrMtr           - Handle of power meter on the input of the TB
%    outPwrMtr          - Handle of the reference power meter on the output
%                         of the TB
%    srcPwr             - Nominal rf power of the source
%    inCalResults       - Results of input calibration. 
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
    wtbr = waitbar(0,'Beginning Scalar Output Calibration.');    
end

%% Build Pdel Offset Function
inOffsetFunction = @(f) interp1([inCalResults.freq], [inCalResults.offset],f); 
Pdel = @(pinRaw,freq) pinRaw + inOffsetFunction(freq); 

%copy frequencies from input calibration data
frqLst = [inCalResults.freq]; 

%% Setup Instruments
%initialize the rf source
if exist('wtbr','var'); waitbar(0,wtbr,'Setup: Initializing RF Source...'); end
rfSrc.set('Frequency',frqLst(1).*1e-9,'Power',srcPwr,'State','OFF'); 

%zero out the power meters 
if exist('wtbr','var'); waitbar(0,wtbr,'Setup: Zeroing Power Meters...'); end
inPwrMtr.zero; 
outPwrMtr.zero; 

TIME_STEPS = 0:STEP_TIME:WAIT_TIME; 
for step = TIME_STEPS
    %update the waitbar
    if exist('wtbr','var'); 
        waitbar(step./WAIT_TIME,wtbr,'Setup: Zeroing RF Source...'); 
    end
    %wait a moment
    pause(STEP_TIME); 
end

%turn the rf source on
rfSrc.set('State','ON');

%% Initialize the Results Array 
%initialize single result element
result.inPwr  = []; %raw power measured by input power meter
result.outPwr = []; %raw output power measured by output power meter
result.delPwr = []; %delivered power into output network
result.offset = []; %calculated offset 
result.freq   = []; %current frequency 

%initialize the results array 
results = repmat(result,1,length(frqLst)); 

%% Run the Loop 

%initialize the progress reporting variables and function handle
if exist('wtbr','var')
    numPoints = length(results); 
    progress = @(index) index./numPoints; 
end


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
    %set the frequency of the power meters 
    inPwrMtr.frequency(freq.*1e-9); 
    outPwrMtr.frequency(freq.*1e-9); 
    %take the measurements 
    results(iFreq).sourcePower = srcPwr; 
    results(iFreq).freq        = freq; 
%     results(iFreq).inPwr       = inPwrMtr.measure(0.001); 
%     results(iFreq).outPwr      = outPwrMtr.measure(0.001); 
    results(iFreq).inPwr       = inPwrMtr.measure('Resolution',0.001); 
    results(iFreq).outPwr      = outPwrMtr.measure('Resolution',0.001); 
    results(iFreq).delPwr      = Pdel(results(iFreq).inPwr,freq); 
    results(iFreq).offset      = results(iFreq).delPwr - ...
                                                results(iFreq).outPwr; 
    %print results to terminal 
    if exist('wtbr','var')
        fprintf('##### RESULTS #####\n')
        fprintf(' Frequency: %0.3f GHz\n',results(iFreq).freq.*1e-9); 
        fprintf(' Input Power: %0.2f dBm\n',results(iFreq).inPwr); 
        fprintf(' Output Power: %0.2f dBm\n',results(iFreq).outPwr); 
        fprintf(' Delivered Power: %0.2f dBm\n',results(iFreq).delPwr); 
        fprintf(' Offset: %0.2f dB\n',results(iFreq).offset);         
    end
end

%turn the rfSource off 
rfSrc.set('State','OFF'); 

%if the waitbar was opened, close it 
if exist('wtbr','var')
    close(wtbr); 
end



end

