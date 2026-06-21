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

result = solveWithInternalTrackingGrid(directParams, options);
result.constitutiveState = state;
result.directParams = directParams;
result = invalidateFallbackOutputIfNeeded(result);
end

function result = solveWithInternalTrackingGrid(directParams, options)
requestedFrequency = directParams.frequency(:).';
if ~isfield(options, 'useInternalAtlasTrackingGrid') || ~logical(options.useInternalAtlasTrackingGrid)
    result = solveAcoustoelasticAtlasBranch(directParams, options);
    result.requestedFrequency = requestedFrequency;
    result.internalAtlasTracking = struct('Used', false, 'TrackingFrequency_Hz', requestedFrequency);
    return;
end

trackingFrequency = buildInternalTrackingFrequency(requestedFrequency, options);
trackingParams = directParams;
trackingParams.frequency = trackingFrequency;

trackingResult = solveAcoustoelasticAtlasBranch(trackingParams, options);
result = restrictResultToRequestedFrequency(trackingResult, requestedFrequency, trackingFrequency, options);
end

function trackingFrequency = buildInternalTrackingFrequency(requestedFrequency, options)
requestedFrequency = unique(requestedFrequency(isfinite(requestedFrequency) & requestedFrequency > 0), 'stable');
requestedFrequency = sort(requestedFrequency(:).');
if isempty(requestedFrequency)
    trackingFrequency = requestedFrequency;
    return;
end

fMax = max(requestedFrequency);
initMin = getOptionValue(options, 'atlasInitializationMinFrequency_Hz', 300);
initMin = max(initMin, eps);
initMin = min(initMin, fMax);

nInit = round(getOptionValue(options, 'atlasInitializationNumFrequencyPoints', 50));
nInit = max(nInit, 2);

% The internal initialization grid anchors branch identity. The requested
% output grid is also included explicitly, so reported Cp values are computed
% by the residual atlas at the GUI frequencies rather than filled by display
% interpolation or previous-point holds.
initFrequency = logspace(log10(initMin), log10(fMax), nInit);
trackingFrequency = unique([initFrequency(:); requestedFrequency(:)], 'sorted').';
end

function result = restrictResultToRequestedFrequency(trackingResult, requestedFrequency, trackingFrequency, options)
result = trackingResult;
requestedFrequency = requestedFrequency(:).';
[isTracked, loc] = ismember(requestedFrequency, trackingFrequency);

result.trackingFrequency = trackingFrequency(:).';
result.requestedFrequency = requestedFrequency;
result.internalAtlasTracking = struct();
result.internalAtlasTracking.Used = true;
result.internalAtlasTracking.TrackingFrequency_Hz = trackingFrequency(:).';
result.internalAtlasTracking.RequestedFrequency_Hz = requestedFrequency(:).';
result.internalAtlasTracking.InitializationMinFrequency_Hz = getOptionValue(options, 'atlasInitializationMinFrequency_Hz', 300);
result.internalAtlasTracking.InitializationNumFrequencyPoints = getOptionValue(options, 'atlasInitializationNumFrequencyPoints', 50);

result.trackingObjectiveMap = trackingResult.objectiveMap;
result.objectiveMap = [];

result.frequency = requestedFrequency;
result.Cp = nan(size(requestedFrequency));
result.validCp = false(size(requestedFrequency));
result.branchExistsAtFrequency = false(size(requestedFrequency));
result.interpolatedCp = false(size(requestedFrequency));
result.objective = nan(size(requestedFrequency));
result.nearestRank = nan(size(requestedFrequency));
result.nearestBranchID = nan(size(requestedFrequency));
result.pointStatus = repmat("belowAtlasInitializationRange", size(requestedFrequency));

if any(isTracked)
    idx = loc(isTracked);
    result.Cp(isTracked) = trackingResult.Cp(idx);
    result.validCp(isTracked) = trackingResult.validCp(idx);
    result.branchExistsAtFrequency(isTracked) = trackingResult.branchExistsAtFrequency(idx);
    result.interpolatedCp(isTracked) = trackingResult.interpolatedCp(idx);
    result.objective(isTracked) = trackingResult.objective(idx);
    result.nearestRank(isTracked) = trackingResult.nearestRank(idx);
    result.nearestBranchID(isTracked) = trackingResult.nearestBranchID(idx);
    result.pointStatus(isTracked) = trackingResult.pointStatus(idx);
end

result.reliability = summarizeRequestedFrequencyReliability(result, trackingResult);
result.diagnostics = summarizeRequestedFrequencyDiagnostics(result, trackingResult);
end

function reliability = summarizeRequestedFrequencyReliability(result, trackingResult)
valid = result.validCp & isfinite(result.Cp);
f = result.frequency;
reliability = trackingResult.reliability;
reliability.TotalPoints = numel(result.Cp);
reliability.ValidPoints = nnz(valid);
reliability.MissingPoints = nnz(~valid);
reliability.ValidFraction = nnz(valid) / max(numel(result.Cp), 1);
reliability.InterpolatedPoints = nnz(result.interpolatedCp);
reliability.ExplicitBranchPoints = nnz(result.branchExistsAtFrequency);
if any(valid)
    validF = f(valid);
    reliability.FirstValidFrequency_Hz = validF(1);
    reliability.FirstValidFrequency_kHz = validF(1)/1e3;
    reliability.LastValidFrequency_Hz = validF(end);
    reliability.LastValidFrequency_kHz = validF(end)/1e3;
else
    reliability.FirstValidFrequency_Hz = nan;
    reliability.FirstValidFrequency_kHz = nan;
    reliability.LastValidFrequency_Hz = nan;
    reliability.LastValidFrequency_kHz = nan;
end
missingAfterStart = find(~valid & f >= reliability.FirstValidFrequency_Hz, 1, 'first');
if isempty(missingAfterStart)
    reliability.FirstMissingFrequency_Hz = nan;
    reliability.FirstMissingFrequency_kHz = nan;
else
    reliability.FirstMissingFrequency_Hz = f(missingAfterStart);
    reliability.FirstMissingFrequency_kHz = f(missingAfterStart)/1e3;
end
reliability.ValidityNote = "Cp is reported on the requested output grid after branch identity is selected on an internal atlas tracking grid.";
end

function diagnostics = summarizeRequestedFrequencyDiagnostics(result, trackingResult)
diagnostics = trackingResult.diagnostics;
diagnostics.validCpPoints = nnz(result.validCp);
diagnostics.totalPoints = numel(result.Cp);
diagnostics.explicitBranchPoints = nnz(result.branchExistsAtFrequency);
diagnostics.interpolatedPoints = nnz(result.interpolatedCp);
diagnostics.missingBranchPoints = nnz(~result.validCp);
diagnostics.lastValidFrequency_kHz = result.reliability.LastValidFrequency_kHz;
diagnostics.validFraction = result.reliability.ValidFraction;
diagnostics.internalAtlasTrackingUsed = true;
if any(result.validCp)
    diagnostics.minCp = min(result.Cp(result.validCp));
    diagnostics.maxCp = max(result.Cp(result.validCp));
    diagnostics.medianCp = median(result.Cp(result.validCp), 'omitnan');
else
    diagnostics.minCp = nan;
    diagnostics.maxCp = nan;
    diagnostics.medianCp = nan;
end
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

function value = getOptionValue(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
