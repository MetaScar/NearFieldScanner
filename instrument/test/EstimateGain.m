function [LinearGainEstimate,RawData] = EstimateGain(rfSource,pinMeter,...
                                frequencies,defaultPower,pavsFunction, ...
                                waitTime)
%ESTIMATEGAIN Estimates the linear gain at each frequency point of the
%target sweep.
    %% Determine the Default Wait Time 
    if not(exist('waitTime','var'))
        waitTime = 0.5; 
    end

    %% Create a container for gain estimate 
    RawData            = zeros(1,length(frequencies)); 
    LinearGainEstimate = zeros(size(RawData)); 
    
    %% Now Iterate Over All Frequencies
    for freqIndex = 1:length(frequencies)
        %get the current frequency 
        presFreq = frequencies(freqIndex); %in Hz
        %set the source frequency 
        rfSource.set('Power',defaultPower,'Frequency',presFreq.*1e-9); 
        %set the power meter frequency 
        pinMeter.frequency(presFreq.*1e-9); 
        %now start the RF Source and take a measurment
        rfSource.set('State','ON'); 
        RawData(freqIndex) = pinMeter.measure(0.1); 
        %turn the rf source off 
        rfSource.set('State','OFF');
        %calculate the gain estimate
        LinearGainEstimate(freqIndex) = ...
            pavsFunction(RawData(freqIndex),presFreq) - ...
            defaultPower; 
        %wait the wait time 
        pause(waitTime); 
    end

end

