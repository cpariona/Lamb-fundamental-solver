function result = solveAcoustoelasticIOPHGOBranch(params, options)
%SOLVEACOUSTOELASTICIOPHGOBRANCH Solve the physical IOP/HGO production branch.
%
% Required params fields, SI units:
%   IOP, R, thickness, mu, k1, k2, rho, rhoF, fluidBulkModulus, frequency
%
% This public owner validates and resolves the IOP/HGO request, computes the
% constitutive state, tracks/refines the selected atlas branch, projects the
% requested frequency grid, applies the production policy, and builds the
% final result.

if nargin < 2
    options = [];
end

aeValidateRequest(params, 'Context', "iopSolver");
options = aeResolveConfiguration(options);

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
spec = rebuildSpec(result);
spec.postSummaryFields = struct('constitutiveState', state, 'directParams', directParams);
result = aeBuildResult(spec);
result = applyFallbackPolicyAndRebuild(result);
end

function result = solveWithInternalTrackingGrid(directParams, options)
requestedFrequency = directParams.frequency(:).';
if ~isfield(options, 'useInternalAtlasTrackingGrid') || ~logical(options.useInternalAtlasTrackingGrid)
    result = solveAcoustoelasticAtlasBranch(directParams, options);
    spec = rebuildSpec(result);
    spec.postSummaryFields = struct( ...
        'requestedFrequency', requestedFrequency, ...
        'internalAtlasTracking', struct('Used', false, 'TrackingFrequency_Hz', requestedFrequency));
    result = aeBuildResult(spec);
    return;
end

trackingFrequency = aeBuildInternalTrackingGrid(requestedFrequency, options);
trackingParams = directParams;
trackingParams.frequency = trackingFrequency;

trackingResult = solveAcoustoelasticAtlasBranch(trackingParams, options);
result = restrictResultToRequestedFrequency(trackingResult, requestedFrequency, trackingFrequency, options);
end

function result = restrictResultToRequestedFrequency(trackingResult, requestedFrequency, trackingFrequency, options)
requestedFrequency = requestedFrequency(:).';
[isTracked, loc] = ismember(requestedFrequency, trackingFrequency);

fields = struct();
fields.frequency = requestedFrequency;
fields.Cp = nan(size(requestedFrequency));
fields.validCp = false(size(requestedFrequency));
fields.branchExistsAtFrequency = false(size(requestedFrequency));
fields.interpolatedCp = false(size(requestedFrequency));
fields.objective = nan(size(requestedFrequency));
fields.nearestRank = nan(size(requestedFrequency));
fields.nearestBranchID = nan(size(requestedFrequency));
fields.pointStatus = repmat("belowAtlasInitializationRange", size(requestedFrequency));

if any(isTracked)
    idx = loc(isTracked);
    fields.Cp(isTracked) = trackingResult.Cp(idx);
    fields.validCp(isTracked) = trackingResult.validCp(idx);
    fields.branchExistsAtFrequency(isTracked) = trackingResult.branchExistsAtFrequency(idx);
    fields.interpolatedCp(isTracked) = trackingResult.interpolatedCp(idx);
    fields.objective(isTracked) = trackingResult.objective(idx);
    fields.nearestRank(isTracked) = trackingResult.nearestRank(idx);
    fields.nearestBranchID(isTracked) = trackingResult.nearestBranchID(idx);
    fields.pointStatus(isTracked) = trackingResult.pointStatus(idx);
end

fields.objectiveMap = [];
trackingMetadata = struct();
trackingMetadata.Used = true;
trackingMetadata.TrackingFrequency_Hz = trackingFrequency(:).';
trackingMetadata.RequestedFrequency_Hz = requestedFrequency;
trackingMetadata.InitializationMinFrequency_Hz = options.atlasInitializationMinFrequency_Hz;
trackingMetadata.InitializationNumFrequencyPoints = options.atlasInitializationNumFrequencyPoints;

spec = struct();
spec.baseResult = trackingResult;
spec.fields = fields;
spec.qualityBase = trackingResult.reliability;
spec.qualityNote = "Cp is reported on the requested output grid after branch identity is selected on an internal atlas tracking grid.";
spec.diagnosticBase = trackingResult.diagnostics;
spec.diagnosticFields = struct('internalAtlasTrackingUsed', true);
spec.postSummaryFields = struct( ...
    'trackingFrequency', trackingFrequency(:).', ...
    'requestedFrequency', requestedFrequency, ...
    'internalAtlasTracking', trackingMetadata, ...
    'trackingObjectiveMap', trackingResult.objectiveMap);
result = aeBuildResult(spec);

% The diagnostic branch is part of the returned requested-grid schema. Build
% it again from the projected official fields while retaining the objective
% columns that correspond exactly to those requested frequencies.
if isfield(trackingResult, 'identityA0')
    diagnosticResult = result;
    diagnosticResult.objectiveMap = nan(size(trackingResult.objectiveMap, 1), numel(requestedFrequency));
    if any(isTracked)
        diagnosticResult.objectiveMap(:, isTracked) = trackingResult.objectiveMap(:, loc(isTracked));
    end
    identity = aeBuildIdentityA0DiagnosticBranch(diagnosticResult);
    spec = rebuildSpec(result);
    spec.postSummaryFields = struct('identityA0', identity);
    spec.diagnosticFields = struct( ...
        'identityA0CandidateValidPoints', identity.summary.CandidateValidPoints, ...
        'identityA0AddedCandidatePoints', identity.summary.AddedCandidatePoints);
    result = aeBuildResult(spec);
end
end

function result = applyFallbackPolicyAndRebuild(result)
[result, fallbackInvalidated] = aeApplyAtlasA0FallbackPolicy(result);
if ~fallbackInvalidated
    return;
end

spec = rebuildSpec(result);
spec.qualityNote = "Official atlasA0 output invalidated because branch selection used unfiltered fallback after A0-like start filters failed. Fallback candidate data are diagnostic-only.";
spec.qualityFirstMissingAtStartWhenInvalid = true;
spec.diagnosticFields = struct('fallbackOutputInvalidated', true);
result = aeBuildResult(spec);
end

function spec = rebuildSpec(result)
spec = struct();
spec.baseResult = result;
spec.qualityBase = result.reliability;
spec.qualityNote = result.reliability.ValidityNote;
spec.diagnosticBase = result.diagnostics;
end
