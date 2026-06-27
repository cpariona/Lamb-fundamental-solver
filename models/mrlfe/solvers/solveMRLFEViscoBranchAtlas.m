function branch = solveMRLFEViscoBranchAtlas(name, seedMode, material, geometry, mrlfeParams, options)
%SOLVEMRLFEVISCOBRANCHATLAS Direct real-k viscous mRLFE Cp-atlas tracker.
%
% branch = solveMRLFEViscoBranchAtlas(name, seedMode, material, geometry, mrlfeParams, options)
%
% This solver evaluates the viscous mRLFE residual directly over a Cp scan,
% extracts multiple local candidates per frequency, and selects a continuous
% branch with the existing dynamic-programming tracker. It does not require a
% precomputed etaS=0 mRLFE elastic reference branch.
%
% The seedMode is still used to identify the modal family and to define a broad
% physically reasonable Cp scan window. In the intended A0Like etaS fitting
% workflow this seed is the Rayleigh-Lamb A0 branch, not an elastic mRLFE
% reference branch.
%
% Canonical option names are the maintained DP and viscous tracking names
% (mrlfeA0DP*, mrlfeVisco*, mrlfeRealK*). Older mrlfeViscoAtlas* names are kept
% only as compatibility aliases and should not be used in new diagnostics.

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

options = localApplyDirectViscousAtlasDefaults(options, string(name));
branch = solveMRLFEBranchDP(name, seedMode, material, geometry, mrlfeParams, options, []);
branch = localApplyViscousModalCutPolicy(branch, options);
branch.note = "mRLFE direct viscous real-k Cp atlas without elastic mRLFE reference branch.";
branch.viscoAtlas = struct();
branch.viscoAtlas.usedElasticMRLFEReference = false;
branch.viscoAtlas.seedFamily = localSeedFamily(seedMode);
branch.viscoAtlas.etaS = getOption(mrlfeParams, 'etaS', NaN);
branch.viscoAtlas.options = localAtlasOptionSummary(options);
branch.viscoAtlas.modalCutPolicy = localModalCutPolicySummary(branch, options);
end

function options = localApplyDirectViscousAtlasDefaults(options, branchName)
% Use canonical maintained tracker option names first. Legacy mrlfeViscoAtlas*
% aliases are read only as fallback for compatibility with older scripts.
options.mrlfeA0DPCandidates = getOptionWithAlias(options, 'mrlfeA0DPCandidates', 'mrlfeViscoAtlasCandidates', 8);
options.mrlfeA0DPCpScanPoints = getOptionWithAlias(options, 'mrlfeA0DPCpScanPoints', 'mrlfeViscoAtlasCpScanPoints', 900);
options.mrlfeA0DPEdgeGuardPoints = getOptionWithAlias(options, 'mrlfeA0DPEdgeGuardPoints', 'mrlfeViscoAtlasEdgeGuardPoints', 6);
options.mrlfeA0DPRefineCandidates = getOption(options, 'mrlfeA0DPRefineCandidates', true);
options.mrlfeA0DPRefineTolX = getOption(options, 'mrlfeA0DPRefineTolX', 1e-6);
options.mrlfeA0DPRefineMaxIter = getOption(options, 'mrlfeA0DPRefineMaxIter', 24);
options.mrlfeA0DPRefineMaxFunEvals = getOption(options, 'mrlfeA0DPRefineMaxFunEvals', 60);

switch branchName
    case "S0Like"
        windowCanonical = 'mrlfeViscoS0ModalCpWindow';
        defaultWindow = [0.70, 1.40];
    otherwise
        windowCanonical = 'mrlfeViscoA0ModalCpWindow';
        defaultWindow = [0.35, 2.50];
end
window = getOptionWithAlias(options, windowCanonical, 'mrlfeViscoAtlasCpWindow', defaultWindow);
if isnumeric(window) && numel(window) == 2 && all(isfinite(window)) && all(window > 0) && window(2) > window(1)
    options.mrlfeA0DPCpMinFactor = window(1);
    options.mrlfeA0DPCpMaxFactor = window(2);
else
    error('Viscous modal Cp window must be [lower upper] with 0 < lower < upper.');
end

options.mrlfeA0DPCpMinFloor = getOptionWithAlias(options, 'mrlfeA0DPCpMinFloor', 'mrlfeViscoAtlasCpMinFloor', 0.25);
options.mrlfeA0DPCpMaxCeiling = getOptionWithAlias(options, 'mrlfeA0DPCpMaxCeiling', 'mrlfeViscoAtlasCpMaxCeiling', 120);
options.mrlfeA0DPResidualWeight = getOptionWithAlias(options, 'mrlfeA0DPResidualWeight', 'mrlfeViscoAtlasResidualWeight', 0.45);
options.mrlfeA0DPJumpWeight = getOptionWithAlias(options, 'mrlfeA0DPJumpWeight', 'mrlfeViscoAtlasJumpWeight', 18.0);
options.mrlfeA0DPCurvatureWeight = getOptionWithAlias(options, 'mrlfeA0DPCurvatureWeight', 'mrlfeViscoAtlasCurvatureWeight', 12.0);
options.mrlfeA0DPSeedWeight = getOptionWithAlias(options, 'mrlfeA0DPSeedWeight', 'mrlfeViscoAtlasSeedWeight', 0.10);
options.mrlfeA0DPMaxJumpSoft = getOptionWithAlias(options, 'mrlfeA0DPMaxJumpSoft', 'mrlfeViscoAtlasMaxJumpSoft', ...
    getOption(options, 'mrlfeViscoPreviousCpMaxRelativeJump', 0.18));
options.mrlfeA0DPMissingPenalty = getOptionWithAlias(options, 'mrlfeA0DPMissingPenalty', 'mrlfeViscoAtlasMissingPenalty', 20.0);
options.mrlfeA0DPAllowMissing = getOptionWithAlias(options, 'mrlfeA0DPAllowMissing', 'mrlfeViscoAtlasAllowMissing', true);

% The DP path itself enforces continuity. Keep hard reference gates disabled by
% default because this route intentionally avoids anchoring to an elastic mRLFE
% reference branch.
options.mrlfeA0DPValidationMaxRelativeKDrift = getOptionWithAlias(options, 'mrlfeA0DPValidationMaxRelativeKDrift', 'mrlfeViscoAtlasValidationMaxRelativeKDrift', inf);
options.mrlfeA0DPValidationMaxRelativeCpDrift = getOptionWithAlias(options, 'mrlfeA0DPValidationMaxRelativeCpDrift', 'mrlfeViscoAtlasValidationMaxRelativeCpDrift', inf);
options.mrlfeA0DPValidationMaxCpJumpRelative = getOptionWithAlias(options, 'mrlfeA0DPValidationMaxCpJumpRelative', 'mrlfeViscoAtlasValidationMaxCpJumpRelative', inf);
options.mrlfeA0DPValidationMaxCpPredictionError = getOptionWithAlias(options, 'mrlfeA0DPValidationMaxCpPredictionError', 'mrlfeViscoAtlasValidationMaxCpPredictionError', inf);
options.mrlfeResidualTolerance = max(getOptionWithAlias(options, 'mrlfeResidualTolerance', 'mrlfeViscoAtlasResidualTolerance', 1e-4), 1e-3);

% Use the maintained viscous local-tracker fields for post-DP tail handling.
options.mrlfeRealKUseModalCpWindow = getOption(options, 'mrlfeViscoUseModalLocalTracker', true);
options.mrlfeRealKStopAtFirstMissingModalMinimum = getOption(options, 'mrlfeRealKStopAtFirstMissingModalMinimum', true);
options.mrlfeRealKPreviousCpMaxRelativeJump = getOption(options, 'mrlfeViscoPreviousCpMaxRelativeJump', inf);
end

function branch = localApplyViscousModalCutPolicy(branch, options)
branch.firstMissingModalMinimumIndex = nan;
branch.firstMissingModalMinimumFrequency = nan;
branch.modalCutReason = "none";

useModalCut = getOption(options, 'mrlfeRealKUseModalCpWindow', true) && ...
    getOption(options, 'mrlfeRealKStopAtFirstMissingModalMinimum', true);
if ~useModalCut
    return;
end

Cp = branch.Cp(:);
residual = branch.residual(:);
validCandidate = isfinite(Cp) & Cp > 0 & isfinite(residual);
if isfield(branch, 'candidateIndex')
    validCandidate = validCandidate & isfinite(branch.candidateIndex(:));
end

residualTolerance = getOption(options, 'mrlfeResidualTolerance', 1e-3);
missingByResidual = validCandidate & residual > residualTolerance;
missingByCandidate = ~validCandidate;

firstMissing = find(missingByCandidate | missingByResidual, 1, 'first');
reason = "missing_modal_minimum";

maxJump = getOption(options, 'mrlfeRealKPreviousCpMaxRelativeJump', inf);
if isfinite(maxJump) && maxJump > 0
    for i = 2:numel(Cp)
        if ~isfinite(Cp(i-1)) || ~isfinite(Cp(i)) || Cp(i-1) <= 0 || Cp(i) <= 0
            continue;
        end
        relJump = abs(Cp(i) - Cp(i-1)) / max(abs(Cp(i-1)), eps);
        if relJump > maxJump
            if isempty(firstMissing) || i < firstMissing
                firstMissing = i;
                reason = "cp_jump_exceeds_viscous_limit";
            end
            break;
        end
    end
end

if isempty(firstMissing)
    return;
end

branch.firstMissingModalMinimumIndex = firstMissing;
branch.firstMissingModalMinimumFrequency = branch.frequency(firstMissing);
branch.modalCutReason = reason;
fieldsToNan = {'k', 'kReal', 'kImag', 'attenuation', 'Cp', 'kThickness', 'residual', 'score', 'candidateRank', 'dpPathCost'};
for i = 1:numel(fieldsToNan)
    fieldName = fieldsToNan{i};
    if isfield(branch, fieldName)
        values = branch.(fieldName);
        if numel(values) == numel(Cp)
            values(firstMissing:end) = nan;
            branch.(fieldName) = values;
        end
    end
end
fieldsToFalse = {'validResidual', 'validReference', 'validSmooth', 'validCp', 'validAttenuation', 'valid'};
for i = 1:numel(fieldsToFalse)
    fieldName = fieldsToFalse{i};
    if isfield(branch, fieldName)
        values = branch.(fieldName);
        if numel(values) == numel(Cp)
            values(firstMissing:end) = false;
            branch.(fieldName) = values;
        end
    end
end
if isfield(branch, 'candidateIndex') && numel(branch.candidateIndex) == numel(Cp)
    branch.candidateIndex(firstMissing:end) = nan;
end
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
summary.refineCandidates = getOption(options, 'mrlfeA0DPRefineCandidates', NaN);
summary.refineTolX = getOption(options, 'mrlfeA0DPRefineTolX', NaN);
summary.refineMaxIter = getOption(options, 'mrlfeA0DPRefineMaxIter', NaN);
summary.refineMaxFunEvals = getOption(options, 'mrlfeA0DPRefineMaxFunEvals', NaN);
summary.useModalCpWindow = getOption(options, 'mrlfeRealKUseModalCpWindow', NaN);
summary.stopAtFirstMissingModalMinimum = getOption(options, 'mrlfeRealKStopAtFirstMissingModalMinimum', NaN);
summary.previousCpMaxRelativeJump = getOption(options, 'mrlfeRealKPreviousCpMaxRelativeJump', NaN);
end

function summary = localModalCutPolicySummary(branch, options)
summary = struct();
summary.useModalCpWindow = getOption(options, 'mrlfeRealKUseModalCpWindow', true);
summary.stopAtFirstMissingModalMinimum = getOption(options, 'mrlfeRealKStopAtFirstMissingModalMinimum', true);
summary.previousCpMaxRelativeJump = getOption(options, 'mrlfeRealKPreviousCpMaxRelativeJump', inf);
summary.firstMissingModalMinimumIndex = branch.firstMissingModalMinimumIndex;
summary.firstMissingModalMinimumFrequency = branch.firstMissingModalMinimumFrequency;
summary.modalCutReason = branch.modalCutReason;
end

function value = getOptionWithAlias(options, canonicalName, legacyAlias, defaultValue)
if isstruct(options) && isfield(options, canonicalName) && ~isempty(options.(canonicalName))
    value = options.(canonicalName);
elseif isstruct(options) && isfield(options, legacyAlias) && ~isempty(options.(legacyAlias))
    value = options.(legacyAlias);
else
    value = defaultValue;
end
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
