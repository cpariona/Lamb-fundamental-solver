function assembly = prepareOceQhFitObservations(recovered, selection)
%PREPAREOCEQHFITOBSERVATIONS Assemble explicitly reviewed QH target observations.
% RECOVERED is the unchanged output of OCE PR #144
% oce.results.recoverSummaryObservations(experimentRoot, saved.experiment).
% SELECTION requires experimentId, subexperimentId, conditionId, condition
% (explicit metadata key/value struct), scanAxisIndex, direction (left/right), curve (raw/smoothed),
% metadataReference and observations, a table with sourceRow, binIndex and
% logical include. One reviewed k-f target bin is supplied per acquisition.
% Optional sampleId asserts a recorded specimen ID. Otherwise recorded IDs
% must agree; absent IDs remain explicitly unavailable, never fabricated.
% Source rows are local to the supplied recovered summary, not global IDs.
% Full source paths identify acquisitions; cross-subexperiment pooling is not supported.
% The supplied order is
% preserved. Excluded target rows remain present. Full prepared acquisition
% curves/masks and current metadata remain in lineage, separate from fit data.
% No physical frequency replaces the selected k-f frequency. No thickness,
% density, modal assumption, frequency rounding or weighting is inferred.

validateattributes(recovered, {'struct'}, {'vector', 'nonempty'});
validateattributes(selection, {'struct'}, {'scalar'});
experimentId = identityText(selection.experimentId);
subexperimentId = identityText(selection.subexperimentId);
expectedSampleId = "";
if isfield(selection, 'sampleId')
    expectedSampleId = identityText(selection.sampleId);
end
validateattributes(selection.condition, {'struct'}, {'scalar'});
if isempty(fieldnames(selection.condition))
    error('lamb:oceQh:MissingCondition', 'Explicit experimental condition metadata is required.');
end
reviewed = selection.observations;
if ~istable(reviewed) || isempty(reviewed) || ...
        ~all(ismember(["sourceRow", "binIndex", "include"], string(reviewed.Properties.VariableNames)))
    error('lamb:oceQh:InvalidSelection', 'Supply reviewed sourceRow, binIndex and include columns.');
end
n = height(reviewed);
validateattributes(reviewed.sourceRow, {'double'}, {'column', 'integer', 'positive', 'finite'});
validateattributes(reviewed.binIndex, {'double'}, {'column', 'integer', 'positive', 'finite'});
validateattributes(reviewed.include, {'logical'}, {'column', 'numel', n});
if numel(unique(reviewed.sourceRow)) ~= n
    error('lamb:oceQh:DuplicateAcquisition', 'Each acquisition supplies at most one reviewed QH target.');
end
validateattributes(selection.scanAxisIndex, {'double'}, {'scalar', 'integer', 'positive', 'finite'});
if ~isscalar(string(selection.direction)) || ~ismember(string(selection.direction), ["left", "right"])
    error('lamb:oceQh:InvalidDirection', 'Select one signed left/right direction.');
end
f = nan(n, 1); cp = f; physicalHz = f; requestedHz = f; thickness = f;
lineage = repmat(struct('sourceRow', [], 'resultFile', "", 'binIndex', [], 'acquisitionMetadata', table(), ...
    'producerProvenance', "", 'prepared', struct()), n, 1);
sampleId = ""; sampleIdAvailable = false; directionId = ""; axisAngle = NaN;
for row = 1:n
    match = find([recovered.summary_source_row] == reviewed.sourceRow(row));
    if ~isscalar(match)
        error('lamb:oceQh:AmbiguousSource', 'Each reviewed source row must match exactly one recovered acquisition.');
    end
    source = recovered(match);
    metadata = source.acquisition_metadata;
    result = source.scientific_result;
    if string(metadata.experiment_id) ~= experimentId || ...
            string(metadata.sub_experiment) ~= subexperimentId || ...
            result.acquisition.experiment_id ~= experimentId || ...
            result.acquisition.subexperiment_id ~= subexperimentId || ...
            result.acquisition.run_id ~= string(metadata.run_id)
        error('lamb:oceQh:IdentityMismatch', ...
            'Metadata and original result must match the intended experiment, subexperiment and run.');
    end
    recordedSample = "";
    if ismember('sample_id', metadata.Properties.VariableNames)
        value = strtrim(string(metadata.sample_id));
        if ~isscalar(value)
            error('lamb:oceQh:MixedSpecimen', 'A specimen identifier must be scalar.');
        end
        if ~ismissing(value), recordedSample = value; end
    end
    available = strlength(recordedSample) > 0;
    if strlength(expectedSampleId) > 0 && recordedSample ~= expectedSampleId
        error('lamb:oceQh:MixedSpecimen', 'The recorded specimen does not match the intended sampleId.');
    end
    if row == 1
        sampleId = recordedSample; sampleIdAvailable = available;
    elseif available ~= sampleIdAvailable || recordedSample ~= sampleId
        error('lamb:oceQh:MixedSpecimen', 'Do not mix distinct specimens or recorded and unavailable specimen identities.');
    end
    if string(metadata.excitation_type) ~= "quasi_harmonic"
        error('lamb:oceQh:NotQuasiHarmonic', 'This operation accepts QH acquisitions only.');
    end
    for key = string(fieldnames(selection.condition))'
        if ~ismember(key, string(metadata.Properties.VariableNames))
            error('lamb:oceQh:ConditionMismatch', 'Condition key %s is absent.', key);
        end
        expected = selection.condition.(key);
        actual = metadata.(key);
        if isnumeric(expected)
            equal = isscalar(expected) && str2double(string(actual)) == expected;
        else
            equal = isscalar(string(expected)) && string(actual) == string(expected);
        end
        if ~equal
            error('lamb:oceQh:ConditionMismatch', 'Source row %d does not match %s.', reviewed.sourceRow(row), key);
        end
    end
    identities = result.dispersion.directions;
    directionIndex = find([identities.scan_axis_index] == selection.scanAxisIndex & ...
        string({identities.direction}) == string(selection.direction));
    if ~isscalar(directionIndex)
        error('lamb:oceQh:AmbiguousDirection', 'Each acquisition must contain the requested signed direction.');
    end
    kf = result.dispersion.estimators.kf_ridge;
    bin = reviewed.binIndex(row);
    if bin ~= kf.directions(directionIndex).target_selection.selected_bin_index
        error('lamb:oceQh:NotTargetBin', 'Review one existing QH target bin; full FFT bins are not pooled.');
    end
    mask = false(size(kf.frequency_axis_hz)); mask(bin) = reviewed.include(row);
    physicalHz(row) = str2double(string(metadata.frequency_Hz));
    validateattributes(physicalHz(row), {'double'}, {'scalar', 'finite', 'positive'});
    repetition = str2double(string(metadata.rep_id));
    evidence = struct('conditionId', selection.conditionId, 'repetitionId', repetition, ...
        'loadingCondition', selection.condition, 'sourceResultFile', source.result_file, ...
        'metadataReference', selection.metadataReference);
    prepared = prepareOceFitObservations(result, struct('directionIndex', directionIndex, ...
        'estimator', "kf_ridge", 'curve', selection.curve, 'validMask', mask), evidence);
    if row == 1
        directionId = prepared.experimental.directionId;
        axisAngle = prepared.experimental.source.scanAxisAngle_deg;
    elseif prepared.experimental.directionId ~= directionId || ...
            prepared.experimental.source.scanAxisAngle_deg ~= axisAngle
        error('lamb:oceQh:MixedGeometry', 'Use one experiment and the same signed physical scan axis.');
    end
    f(row) = prepared.experimental.frequency_Hz(bin);
    cp(row) = prepared.experimental.Cp_mps(bin);
    requestedHz(row) = result.dispersion.target_frequency.requested_hz;
    thickness(row) = prepared.measuredThickness_m;
    lineage(row) = struct('sourceRow', reviewed.sourceRow(row), 'resultFile', source.result_file, 'binIndex', bin, ...
        'acquisitionMetadata', metadata, 'producerProvenance', source.provenance, 'prepared', prepared);
end
paths = replace(string({lineage.resultFile}), '\', '/');
if ispc, paths = lower(paths); end
if numel(unique(paths)) ~= n
    error('lamb:oceQh:DuplicateAcquisition', 'A source result path must not supply duplicate QH observations.');
end
experimental = struct('frequency_Hz', f, 'Cp_mps', cp, 'validMask', reviewed.include, ...
    'conditionId', selection.conditionId, 'directionId', directionId);
assembly = struct('experimental', experimental, 'physicalFrequency_Hz', physicalHz, ...
    'requestedTargetFrequency_Hz', requestedHz, 'measuredThickness_m', thickness, ...
    'selection', selection, 'lineage', lineage, ...
    'identity', struct('experimentId', experimentId, 'subexperimentId', subexperimentId, ...
    'sampleId', sampleId, 'sampleIdAvailable', sampleIdAvailable, 'directionId', directionId));
end

function value = identityText(value)
if ~(ischar(value) || isstring(value)) || ~isscalar(string(value)) || ...
        ismissing(string(value)) || strlength(strtrim(string(value))) == 0
    error('lamb:oceQh:InvalidIdentity', 'Explicit nonempty scalar identity text is required.');
end
value = strtrim(string(value));
end
