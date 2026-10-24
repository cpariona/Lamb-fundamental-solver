function prepared = prepareOceFitObservations(oceResult, selection, metadata)
%PREPAREOCEFITOBSERVATIONS Translate one validated OCE direction to fit data.
%   OCERESULT must already be validated by oce.results.validateScientificResult
%   or loaded by oce.io.loadScientificResult. OCE owns schema validation/I/O.
%   SELECTION specifies directionIndex in acquisition order, estimator
%   ("kf_ridge" or "phase_gradient") and an explicit logical validMask.
%   For k-f, curve must explicitly be "raw" or "smoothed". No curve is
%   computed here. Phase-gradient supplies one scalar at its physical target.
%   METADATA requires conditionId, repetitionId, loadingCondition (struct),
%   sourceResultFile and metadataReference. All metadata is retained unchanged.
%   PREPARED.experimental is a model-neutral fitting request, including
%   source masks/identity/provenance. PREPARED.measuredThickness_m is the
%   current full directional thickness (mm -> m); unavailable stays NaN.
%   No model, mode, density, physical support, optimizer or weighting policy
%   is selected. Call separately for each acquisition and signed direction.
%   No observations are removed, sorted, averaged, interpolated or reweighted.

validateattributes(oceResult, {'struct'}, {'scalar'});
validateattributes(selection, {'struct'}, {'scalar'});
validateattributes(metadata, {'struct'}, {'scalar'});
if oceResult.schema.name ~= "oce_phase_speed_result" || oceResult.schema.version ~= 4
    error('lamb:oceIntegration:UnsupportedSchema', 'Use a validated OCE schema-v4 result.');
end
required = ["conditionId", "repetitionId", "loadingCondition", ...
    "sourceResultFile", "metadataReference"];
if any(~isfield(metadata, required))
    error('lamb:oceIntegration:MissingMetadata', 'Explicit identity and provenance are required.');
end
for name = ["conditionId", "sourceResultFile", "metadataReference"]
    value = metadata.(name);
    if ~(ischar(value) || isstring(value)) || ~isscalar(string(value)) || ...
            ismissing(string(value)) || strlength(strtrim(string(value))) == 0
        error('lamb:oceIntegration:InvalidMetadata', '%s must be nonempty scalar text.', name);
    end
end
validateattributes(metadata.repetitionId, {'double'}, ...
    {'real', 'scalar', 'finite', 'integer', 'positive'});
validateattributes(metadata.loadingCondition, {'struct'}, {'scalar'});
if isempty(fieldnames(metadata.loadingCondition))
    error('lamb:oceIntegration:InvalidMetadata', 'An explicit loading condition is required.');
end
index = selection.directionIndex;
validateattributes(index, {'double'}, ...
    {'real', 'scalar', 'finite', 'integer', '>=', 1, '<=', numel(oceResult.dispersion.directions)});
identity = oceResult.dispersion.directions(index);
estimator = string(selection.estimator);
switch estimator
    case "kf_ridge"
        kf = oceResult.dispersion.estimators.kf_ridge;
        direction = kf.directions(index);
        frequency = double(kf.frequency_axis_hz(:));
        curve = string(selection.curve);
        if ~isscalar(curve) || ~ismember(curve, ["raw", "smoothed"])
            error('lamb:oceIntegration:UnsupportedCurve', 'Explicitly select raw or smoothed k-f Cp.');
        end
        curveField = curve + "_phase_speed_m_per_s";
        speed = double(direction.phase_speed_curve.(curveField)(:));
        masks = struct();
        for name = ["valid_mask", "interpolated_mask", "extrapolated_mask"]
            if ~isfield(direction.ridge, name)
                error('lamb:oceIntegration:MissingRidgeMasks', 'Original OCE ridge masks are required.');
            end
            validateattributes(direction.ridge.(name), {'logical'}, ...
                {'vector', 'numel', numel(frequency)});
            masks.(name) = direction.ridge.(name);
        end
        estimatorEvidence = struct('curveField', curveField, 'originalMasks', masks, ...
            'targetSelection', direction.target_selection);
    case "phase_gradient"
        gradient = oceResult.dispersion.estimators.phase_gradient;
        if ~gradient.enabled
            error('lamb:oceIntegration:EstimatorUnavailable', 'Phase-gradient was not enabled in OCE.');
        end
        direction = gradient.directions(index);
        frequency = double(oceResult.dispersion.target_frequency.requested_hz);
        speed = double(direction.phase_speed_m_per_s);
        estimatorEvidence = struct('status', direction.status, ...
            'originalMasks', struct('valid_mask', direction.status == "valid"));
    otherwise
        error('lamb:oceIntegration:UnsupportedEstimator', 'Select kf_ridge or phase_gradient explicitly.');
end
validateattributes(selection.validMask, {'logical'}, {'vector', 'numel', numel(frequency)});
mask = selection.validMask(:);
% Downstream fitting normalization intersects a mask with data finiteness.
% Reject invalid selected data here so it cannot silently shrink that mask.
if any(mask & (~isfinite(frequency) | frequency <= 0 | ~isfinite(speed) | speed <= 0))
    error('lamb:oceIntegration:InvalidSelectedObservation', ...
        'Selected observations must have positive finite Hz and Cp; the mask is never repaired.');
end
angularIndex = find(oceResult.angular.source_direction_indices == index);
source = struct('schema', oceResult.schema, 'processingRunId', oceResult.processing_run_id, ...
    'acquisition', oceResult.acquisition, 'estimator', estimator, ...
    'estimatorEvidence', estimatorEvidence, 'directionIndex', index, ...
    'scanAxisIndex', identity.scan_axis_index, 'direction', identity.direction, ...
    'scanAxisAngle_deg', oceResult.dispersion.scan_axis_angles_deg(identity.scan_axis_index), ...
    'angularIndex', angularIndex, ...
    'fullCircleAngle_deg', oceResult.angular.full_circle_angles_deg(angularIndex), ...
    'targetFrequency', oceResult.dispersion.target_frequency, ...
    'effectivePassband_Hz', oceResult.dispersion.filter_effective_passband_hz);
experimental = struct('frequency_Hz', frequency, 'Cp_mps', speed, 'validMask', mask, ...
    'conditionId', metadata.conditionId, ...
    'directionId', compose("scan_axis_%d:%s", identity.scan_axis_index, identity.direction), ...
    'integrationMetadata', metadata, 'source', source);
prepared = struct('experimental', experimental, ...
    'measuredThickness_m', double(oceResult.borders.directional_mean_thickness_mm(index))*1e-3);
end
