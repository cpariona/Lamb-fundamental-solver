function branch = solveMRLFEViscoBranchAtlas(name, seedMode, material, geometry, mrlfeParams, options)
%SOLVEMRLFEVISCOBRANCHATLAS Prototype direct real-k viscous mRLFE atlas tracker.
%
% branch = solveMRLFEViscoBranchAtlas(name, seedMode, material, geometry, mrlfeParams, options)
%
% This diagnostic/prototype solver evaluates the viscous mRLFE residual directly
% over a Cp scan, extracts multiple local candidates per frequency, and selects
% a continuous branch with the existing dynamic-programming tracker. It does
% not require a precomputed etaS=0 mRLFE elastic reference branch.
%
% The seedMode is still used to identify the modal family and to define a broad
% physically reasonable Cp scan window. In the intended diagnostic workflow this
% seed is the Rayleigh-Lamb A0/S0 branch, not an elastic mRLFE reference branch.

if nargin < 6 || isempty(options)
    options = struct();
end
if nargin < 5 || ~isstruct(mrlfeParams)
    error('mrlfeParams must be a structure.');
end

mrlfeParams.solveComplexK = false;
if ~isfield(mrlfeParams, 'etaL') || isempty(mrlfeParams.etaL)
    mrlfeParams.etaL = 0;
end
if ~isfield(mrlfeParams, 'useComplexLambda') || isempty(mrlfeParams.useComplexLambda)
    mrlfeParams.useComplexLambda = false;
end

options = localApplyViscoAtlasDefaults(options, string(name));
branch = solveMRLFEBranchDP(name, seedMode, material, geometry, mrlfeParams, options, []);
branch.note = "mRLFE direct viscous real-k Cp atlas prototype without elastic mRLFE reference branch.";
branch.viscoAtlas = struct();
branch.viscoAtlas.usedElasticMRLFEReference = false;
branch.viscoAtlas.seedFamily = localSeedFamily(seedMode);
branch.viscoAtlas.etaS = getOption(mrlfeParams, 'etaS', NaN);
branch.viscoAtlas.options = localAtlasOptionSummary(options);
end

function options = localApplyViscoAtlasDefaults(options, branchName)
% Keep the prototype explicitly separate from the elastic fast fitting preset.
options.mrlfeA0DPCandidates = getOption(options, 'mrlfeViscoAtlasCandidates', getOption(options, 'mrlfeA0DPCandidates', 8));
options.mrlfeA0DPCpScanPoints = getOption(options, 'mrlfeViscoAtlasCpScanPoints', getOption(options, 'mrlfeA0DPCpScanPoints', 900));
options.mrlfeA0DPEdgeGuardPoints = getOption(options, 'mrlfeViscoAtlasEdgeGuardPoints', getOption(options, 'mrlfeA0DPEdgeGuardPoints', 6));

switch branchName
    case "S0Like"
        defaultWindow = [0.60, 1.60];
    otherwise
        defaultWindow = [0.25, 3.00];
end
window = getOption(options, 'mrlfeViscoAtlasCpWindow', defaultWindow);
if isnumeric(window) && numel(window) == 2 && all(isfinite(window)) && all(window > 0) && window(2) > window(1)
    options.mrlfeA0DPCpMinFactor = window(1);
    options.mrlfeA0DPCpMaxFactor = window(2);
else
    error('mrlfeViscoAtlasCpWindow must be [lower upper] with 0 < lower < upper.');
end

options.mrlfeA0DPCpMinFloor = getOption(options, 'mrlfeViscoAtlasCpMinFloor', getOption(options, 'mrlfeA0DPCpMinFloor', 0.25));
options.mrlfeA0DPCpMaxCeiling = getOption(options, 'mrlfeViscoAtlasCpMaxCeiling', getOption(options, 'mrlfeA0DPCpMaxCeiling', 120));
options.mrlfeA0DPResidualWeight = getOption(options, 'mrlfeViscoAtlasResidualWeight', getOption(options, 'mrlfeA0DPResidualWeight', 0.45));
options.mrlfeA0DPJumpWeight = getOption(options, 'mrlfeViscoAtlasJumpWeight', getOption(options, 'mrlfeA0DPJumpWeight', 18.0));
options.mrlfeA0DPCurvatureWeight = getOption(options, 'mrlfeViscoAtlasCurvatureWeight', getOption(options, 'mrlfeA0DPCurvatureWeight', 12.0));
options.mrlfeA0DPSeedWeight = getOption(options, 'mrlfeViscoAtlasSeedWeight', getOption(options, 'mrlfeA0DPSeedWeight', 0.10));
options.mrlfeA0DPMaxJumpSoft = getOption(options, 'mrlfeViscoAtlasMaxJumpSoft', getOption(options, 'mrlfeA0DPMaxJumpSoft', 0.35));
options.mrlfeA0DPMissingPenalty = getOption(options, 'mrlfeViscoAtlasMissingPenalty', getOption(options, 'mrlfeA0DPMissingPenalty', 20.0));
options.mrlfeA0DPAllowMissing = getOption(options, 'mrlfeViscoAtlasAllowMissing', getOption(options, 'mrlfeA0DPAllowMissing', true));

% The DP path itself enforces continuity. Keep hard reference gates disabled by
% default because the point of this prototype is to avoid anchoring to an elastic
% mRLFE reference branch.
options.mrlfeA0DPValidationMaxRelativeKDrift = getOption(options, 'mrlfeViscoAtlasValidationMaxRelativeKDrift', inf);
options.mrlfeA0DPValidationMaxRelativeCpDrift = getOption(options, 'mrlfeViscoAtlasValidationMaxRelativeCpDrift', inf);
options.mrlfeA0DPValidationMaxCpJumpRelative = getOption(options, 'mrlfeViscoAtlasValidationMaxCpJumpRelative', inf);
options.mrlfeA0DPValidationMaxCpPredictionError = getOption(options, 'mrlfeViscoAtlasValidationMaxCpPredictionError', inf);
options.mrlfeResidualTolerance = getOption(options, 'mrlfeViscoAtlasResidualTolerance', getOption(options, 'mrlfeResidualTolerance', 1e-3));
end

function family = localSeedFamily(seedMode)
family = "unknown";
if isstruct(seedMode) && isfield(seedMode, 'family')
    family = string(seedMode.family);
elseif isstruct(seedMode) && isfield(seedMode, 'name')
    family = string(seedMode.name);
end
end

function summary = localAtlasOptionSummary(options)
summary = struct();
summary.cpScanPoints = getOption(options, 'mrlfeA0DPCpScanPoints', NaN);
summary.maxCandidates = getOption(options, 'mrlfeA0DPCandidates', NaN);
summary.cpMinFactor = getOption(options, 'mrlfeA0DPCpMinFactor', NaN);
summary.cpMaxFactor = getOption(options, 'mrlfeA0DPCpMaxFactor', NaN);
summary.residualWeight = getOption(options, 'mrlfeA0DPResidualWeight', NaN);
summary.jumpWeight = getOption(options, 'mrlfeA0DPJumpWeight', NaN);
summary.curvatureWeight = getOption(options, 'mrlfeA0DPCurvatureWeight', NaN);
summary.seedWeight = getOption(options, 'mrlfeA0DPSeedWeight', NaN);
summary.residualTolerance = getOption(options, 'mrlfeResidualTolerance', NaN);
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
