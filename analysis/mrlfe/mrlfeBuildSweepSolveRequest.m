function request = mrlfeBuildSweepSolveRequest(baseParams, sweepPoint, frequency_Hz, branchName, sweepOptions)
%MRLFEBUILDSWEEPSOLVEREQUEST Apply one point and build the public request.

if nargin < 2 || isempty(sweepPoint)
    sweepPoint = struct();
end
if nargin < 4 || isempty(branchName)
    branchName = "A0Like";
end
if nargin < 5 || isempty(sweepOptions)
    sweepOptions = struct();
end
if nargin < 1 || ~isstruct(baseParams)
    error('mrlfe:InvalidSweepParameters', 'mRLFE sweep baseParams must be a struct.');
end

pointParams = applySweepPoint(baseParams, sweepPoint);
policy = struct('parameterOptions', sweepOptions);
request = mrlfeBuildPublicSolveRequest(pointParams, frequency_Hz, branchName, policy);
end

function params = applySweepPoint(baseParams, sweepPoint)
params = baseParams;
if ~isstruct(sweepPoint) || ~isfield(sweepPoint, 'parameterName') || isempty(sweepPoint.parameterName)
    return;
end

parameterName = string(sweepPoint.parameterName);
if ~isscalar(parameterName)
    error('mrlfe:InvalidSweepPoint', 'Sweep point parameterName must be scalar text.');
end
if ~isfield(sweepPoint, 'parameterValue') || isempty(sweepPoint.parameterValue)
    error('mrlfe:InvalidSweepPoint', 'Sweep point for "%s" is missing parameterValue.', parameterName);
end
value = sweepPoint.parameterValue;
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
    error('mrlfe:InvalidSweepPoint', 'Sweep point "%s" value must be a finite scalar.', parameterName);
end

switch parameterName
    case {"mu", "mu_Pa"}
        params.mu = value;
    case {"etaS", "etaS_Pas"}
        params.etaS = value;
    case {"rho", "rho_kgm3"}
        params.rho = value;
    case "nu"
        params.nu = value;
    case {"thickness", "thickness_m"}
        params.thickness = value;
    case {"fluidDensity", "fluidDensity_kgm3", "density_kgm3"}
        params.fluidDensity = value;
    case {"fluidSoundSpeed", "fluidSoundSpeed_mps", "soundSpeed_mps"}
        params.fluidSoundSpeed = value;
    otherwise
        error('mrlfe:UnsupportedSweepParameter', ...
            'Unsupported mRLFE sweep parameter "%s".', parameterName);
end
end
