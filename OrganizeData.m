clc; clear; close all

sz = [3, 3];
varTypes = ["double", "double", "sparameters"];
varNames = ["X position", "Y position", "S parameters"];
paramsTable = table('Size', sz,'VariableTypes', varTypes, 'VariableNames',varNames);

s1 = sparameters("M.s1p");
s2 = sparameters("O.s1p");
s3 = sparameters("S.s1p");

paramsTable(1,:) = {-1, 0, s1};
paramsTable(2,:) = {0,0,s2};
paramsTable(3,:) = {1,0,s3};


potato = organizeData(paramsTable);

saveVariable(potato)

function structy = organizeData(table)

sparams = table.("S parameters");
freq = sparams(1).Frequencies;
selectedFreqIndex = ceil(length(freq)/2);
centerFreq = freq(selectedFreqIndex);

check = true;
while check
a = input("What frequency do you want to analyze? (The default is the center at " + centerFreq/1e9 + " GHz): ");
if ~isempty(a)
    selectedFreqIndex = find_nearest_index(freq, a*1e9);
end

a = input("Confirm; will frequency " + freq(selectedFreqIndex)/1e9 + " GHz work? (y/n): ", "s");
if strcmp(a, "y")
    check = false;
end

end

sdata = zeros(length(sparams), 1);
for i = 1:length(sparams)
    sparam = rfparam(sparams(i), 1, 1);
    sdata(i) = sparam(selectedFreqIndex);
end

structy = struct('x', table.("X position"), 'y', table.("Y position"), 's', sdata, 'frequency', freq(selectedFreqIndex));

end


function index = find_nearest_index(x, num)
[~,index] = min(abs(x-num));
end

function saveVariable(var)
a = input("What do you want to name the .mat file?: ", "s");

name = a + ".mat";
save(name, "var")
end