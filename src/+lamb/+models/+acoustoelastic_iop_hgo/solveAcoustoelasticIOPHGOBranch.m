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
requestedOptions = options;
timerStart = tic;

lamb.models.acoustoelastic_iop_hgo.configuration.aeValidateRequest(params, 'Context', "iopSolver");
options = lamb.models.acoustoelastic_iop_hgo.configuration.aeResolveConfiguration(options);

[alpha, beta, gamma, state] = lamb.models.acoustoelastic_iop_hgo.constitutive.computeAcoustoelasticABGFromIOPHGO( ...
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
[result, fallbackInvalidated] = lamb.models.acoustoelastic_iop_hgo.policies.aeApplyAtlasA0FallbackPolicy(result);
spec = rebuildSpec(result);
if fallbackInvalidated
    spec.qualityNote = "Official atlasA0 output invalidated because branch selection used unfiltered fallback after A0-like start filters failed. Fallback candidate data are diagnostic-only.";
    spec.qualityFirstMissingAtStartWhenInvalid = true;
    spec.diagnosticFields = struct('fallbackOutputInvalidated', true);
end
spec.postSummaryFields = struct('constitutiveState', state, 'directParams', directParams);
spec.configuration = struct( ...
    'requested', struct('parameters', params, 'options', requestedOptions), ...
    'effective', struct('parameters', directParams, 'options', options));
spec.execution = struct('engine', "atlasA0_iop_hgo", 'elapsedSeconds', toc(timerStart));
result = lamb.models.acoustoelastic_iop_hgo.results.aeBuildResult(spec);
end

function result = solveWithInternalTrackingGrid(directParams, options)
requestedFrequency = directParams.frequency(:).';
if ~isfield(options, 'useInternalAtlasTrackingGrid') || ~logical(options.useInternalAtlasTrackingGrid)
    result = lamb.models.acoustoelastic_iop_hgo.solvers.solveAcoustoelasticAtlasBranch(directParams, options);
    spec = rebuildSpec(result);
    spec.postSummaryFields = struct( ...
        'requestedFrequency', requestedFrequency, ...
        'internalAtlasTracking', struct('Used', false, 'TrackingFrequency_Hz', requestedFrequency));
    result = lamb.models.acoustoelastic_iop_hgo.results.aeBuildResult(spec);
    return;
end

trackingFrequency = lamb.models.acoustoelastic_iop_hgo.configuration.aeBuildInternalTrackingGrid(requestedFrequency, options);
trackingParams = directParams;
trackingParams.frequency = trackingFrequency;

trackingResult = lamb.models.acoustoelastic_iop_hgo.solvers.solveAcoustoelasticAtlasBranch(trackingParams, options);
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
    fields.Cp(isTracked) = trackingResult.phaseVelocity_mps(idx);
    fields.validCp(isTracked) = trackingResult.validMask(idx);
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
spec.qualityBase = trackingResult.quality;
spec.qualityNote = "Cp is reported on the requested output grid after branch identity is selected on an internal atlas tracking grid.";
spec.diagnosticBase = trackingResult.diagnostics;
spec.diagnosticFields = struct('internalAtlasTrackingUsed', true);
spec.postSummaryFields = struct( ...
    'trackingFrequency', trackingFrequency(:).', ...
    'requestedFrequency', requestedFrequency, ...
    'internalAtlasTracking', trackingMetadata, ...
    'trackingObjectiveMap', trackingResult.objectiveMap);
result = lamb.models.acoustoelastic_iop_hgo.results.aeBuildResult(spec);

% The diagnostic branch is part of the returned requested-grid schema. Build
% it again from the projected official fields while retaining the objective
% columns that correspond exactly to those requested frequencies.
if isfield(trackingResult.diagnostics, 'identityA0')
    diagnosticResult = result;
    diagnosticResult.objectiveMap = nan(size(trackingResult.objectiveMap, 1), numel(requestedFrequency));
    if any(isTracked)
        diagnosticResult.objectiveMap(:, isTracked) = trackingResult.objectiveMap(:, loc(isTracked));
    end
    identity = lamb.models.acoustoelastic_iop_hgo.diagnostics.aeBuildIdentityA0DiagnosticBranch(diagnosticResult);
    spec = rebuildSpec(result);
    spec.diagnosticFields = struct( ...
        'identityA0', identity, ...
        'identityA0CandidateValidPoints', identity.summary.CandidateValidPoints, ...
        'identityA0AddedCandidatePoints', identity.summary.AddedCandidatePoints);
    result = lamb.models.acoustoelastic_iop_hgo.results.aeBuildResult(spec);
end
end

function spec = rebuildSpec(result)
spec = struct();
spec.baseResult = result;
spec.qualityBase = result.quality;
spec.qualityNote = result.quality.validityNote;
spec.diagnosticBase = result.diagnostics;
end
