function result = solveAcoustoelasticIOPHGOAtlasBranch(params, options)
%SOLVEACOUSTOELASTICIOPHGOATLASBRANCH Solve atlas branch from acoustoelastic IOP/HGO parameters.
%
% Required params fields, SI units:
%   IOP, R, thickness, mu, k1, k2, rho, rhoF, fluidBulkModulus, frequency
%
% This wrapper computes alpha, beta, gamma from the IOP/HGO constitutive block
% and then calls solveAcoustoelasticAtlasBranch.

if nargin < 2 || isempty(options)
    options = defaultAcoustoelasticIOPHGOOptions();
end

requiredFields = {'IOP', 'R', 'thickness', 'mu', 'k1', 'k2', 'rho', 'rhoF', 'fluidBulkModulus', 'frequency'};
for i = 1:numel(requiredFields)
    if ~isfield(params, requiredFields{i})
        error('Missing required acoustoelastic IOP/HGO atlas parameter: %s', requiredFields{i});
    end
end

[alpha, beta, gamma, state] = computeAcoustoelasticABGFromIOPHGO( ...
    params.IOP, params.R, params.thickness, params.mu, params.k1, params.k2);

directParams = struct();
directParams.alpha = alpha;
directParams.beta = beta;
directParams.gamma = gamma;
directParams.thickness = params.thickness;
directParams.rho = params.rho;
directParams.rhoF = params.rhoF;
directParams.fluidBulkModulus = params.fluidBulkModulus;
directParams.frequency = params.frequency;

result = solveAcoustoelasticAtlasBranch(directParams, options);
result.constitutiveState = state;
result.directParams = directParams;
result = invalidateFallbackOutputIfNeeded(result);
end

function result = invalidateFallbackOutputIfNeeded(result)
if ~isfield(result, 'options') || ~isfield(result.options, 'invalidateAtlasFallbackOutput') || ...
        ~logical(result.options.invalidateAtlasFallbackOutput)
    return;
end

if ~isfield(result, 'reliability') || ~isfield(result.reliability, 'SelectionFallbackUsed') || ...
        ~logical(result.reliability.SelectionFallbackUsed)
    return;
end

% Fallback-selected branches remain useful diagnostic evidence, but they are
% not accepted as official atlasA0 output because they failed the A0-like
% start filters. Preserve selectedBranch, branchTable, minimaTable, and the
% original branch points; invalidate only the official Cp/validCp surface.
result.fallbackCandidateCp = result.Cp;
result.fallbackCandidateValidCp = result.validCp;
result.fallbackCandidateBranchExistsAtFrequency = result.branchExistsAtFrequency;
result.fallbackCandidateInterpolatedCp = result.interpolatedCp;
result.fallbackCandidatePointStatus = result.pointStatus;

result.Cp(:) = nan;
result.validCp(:) = false;
result.branchExistsAtFrequency(:) = false;
result.interpolatedCp(:) = false;
result.objective(:) = nan;
result.nearestRank(:) = nan;
result.nearestBranchID(:) = nan;
result.pointStatus(:) = "fallbackRejectedA0StartFilter";

result.reliability.ValidPoints = 0;
result.reliability.MissingPoints = numel(result.Cp);
result.reliability.ValidFraction = 0;
result.reliability.InterpolatedPoints = 0;
result.reliability.ExplicitBranchPoints = 0;
result.reliability.FirstValidFrequency_Hz = nan;
result.reliability.FirstValidFrequency_kHz = nan;
result.reliability.LastValidFrequency_Hz = nan;
result.reliability.LastValidFrequency_kHz = nan;
result.reliability.FirstMissingFrequency_Hz = result.frequency(1);
result.reliability.FirstMissingFrequency_kHz = result.frequency(1)/1e3;
result.reliability.ValidityNote = "Official atlasA0 output invalidated because branch selection used unfiltered fallback after A0-like start filters failed. Fallback candidate data are diagnostic-only.";

if isfield(result, 'diagnostics')
    result.diagnostics.validCpPoints = 0;
    result.diagnostics.explicitBranchPoints = 0;
    result.diagnostics.interpolatedPoints = 0;
    result.diagnostics.missingBranchPoints = numel(result.Cp);
    result.diagnostics.lastValidFrequency_kHz = nan;
    result.diagnostics.validFraction = 0;
    result.diagnostics.minCp = nan;
    result.diagnostics.maxCp = nan;
    result.diagnostics.medianCp = nan;
    result.diagnostics.fallbackOutputInvalidated = true;
end
end
