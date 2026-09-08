function options = mrlfeDefaultFitOptions(branchName, varargin)
%MRLFEDEFAULTFITOPTIONS Default model options for mRLFE fitting.

p = inputParser;
addRequired(p, 'branchName', @(x)ischar(x) || isstring(x));
addParameter(p, 'EtaS', 0.05, @(x)isnumeric(x) && isscalar(x) && isfinite(x));
addParameter(p, 'A0Policy', "physicalTail", @(x)ischar(x) || isstring(x));
parse(p, branchName, varargin{:});

branchName = string(p.Results.branchName);
if ~(branchName == "A0Like" || branchName == "S0Like")
    error('Unsupported mRLFE branchName "%s". Use "A0Like" or "S0Like".', branchName);
end

options = struct();
options.modelFamily = "mrlfe";
options.branchName = branchName;
options.executionProfile = "Fast";
options.effectiveExecutionProfile = "Fast";
options.robustness = "Fast";
options.mrlfeNumericalPreset = "fast";
options.mrlfeA0Policy = normalizeA0Policy(p.Results.A0Policy);
options.mrlfeParams = lamb.models.mrlfe.configuration.mrlfeDefaultInternalParameters();
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;
options.mrlfeParams.etaS = p.Results.EtaS;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;
end

function policy = normalizeA0Policy(policyIn)
policy = string(policyIn);
if policy ~= "physicalTail"
    policy = "physicalTail";
end
end
