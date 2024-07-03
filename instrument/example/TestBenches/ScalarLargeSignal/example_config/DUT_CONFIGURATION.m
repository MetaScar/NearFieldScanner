%% DUT CONFIGURATION FILE 

%% Stage Configuration 

%for stage 1 
%gate settings
gate1.Voff      = 3;            %pinchoff voltage   (V)
gate1.Max       = 4;            %max set voltage    (V)
gate1.Min       = 1;            %min set voltage    (V)
gate1.Ilim      = 10e-3;        %compliance current (A)
gate1.NomStep   = 0.025;        %nominal step size of gate (V)
gate1.wait      = 0.5;          %wait time between steps (s)
gate1.PSU       = gate;         %handle of PSU on gate
gate1.Imeter    = [];           %handle of meter reading current on gate (if empty, use PSU) 
gate1.Vmeter    = [];           %handle of meter reading voltage on gate (if empty, use PSU)

%drain settings 
drain1.Voff     = 0;            %drain off voltage (V)
drain1.Von      = 28;           %drain on voltage (V)
drain1.Max      = 30;           %drain max set voltage (V)
drain1.Min      = 0;            %drain min set voltage (V)
drain1.Ilim     = 180e-3;       %drain compliance current (A)
drain1.NomStep  = 0.5;          %drain nominal step size (V)
drain1.wait     = 0.5;          %drain wait time (s)
drain1.PSU      = drain;        %handle of PSU on drain 
drain1.Imeter   = idMeter;      %handle of meter reading current on drain (if empty, use PSU) 
drain1.Vmeter   = vdMeter;      %handle of meter reading voltage on drain (if empty, use PSU)

%quiescent current settings 
Iq1.Value       = 34e-3;        %target quiescent current value
Iq1.Tol         = 0.1e-3;       %tolerance (A) about Iq1
Iq1.SettleTime  = 10;           %wait this long to settle 

%build the stage
stage1.name     = 'Stage1'; 
stage1.state    = 'off'; 
stage1.gate     = gate1; 
stage1.drain    = drain1; 
stage1.IqTarget = Iq1; 


%% Build Bias On Configuration of Stages 

%bias on procedure will go left to right, bias off procedure goes right to
%left
stages = [stage1]; 