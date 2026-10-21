function tests = test_oce_fit_observations()
%TEST_OCE_FIT_OBSERVATIONS Lossless app preparation and independent fit owners.
tests = functiontests(localfunctions);
end

function testExactValuesMasksAndUnknownThickness(testCase)
[source, selection, metadata] = fixture();
source.borders.directional_mean_thickness_mm(1) = NaN;
source.dispersion.estimators.kf_ridge.frequency_axis_hz(1) = 0;
source.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s(1) = NaN;
selection.validMask = [false true true false true];
prepared = prepareOceFitObservations(source, selection, metadata);
data = prepared.experimental;
verifyEqual(testCase, data.frequency_Hz, source.dispersion.estimators.kf_ridge.frequency_axis_hz(:));
verifyEqual(testCase, data.Cp_mps, ...
    source.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s(:));
verifyEqual(testCase, data.validMask, selection.validMask(:));
verifyEqual(testCase, data.integrationMetadata, metadata);
verifyEqual(testCase, data.source.acquisition, source.acquisition);
verifyEqual(testCase, data.source.processingRunId, source.processing_run_id);
verifyEqual(testCase, data.source.estimatorEvidence.originalMasks, ...
    source.dispersion.estimators.kf_ridge.directions(1).ridge);
verifyTrue(testCase, isnan(prepared.measuredThickness_m));
verifyFalse(testCase, isfield(data, 'standardError_Cp_mps'));
verifyFalse(testCase, isfield(data, 'numPoints'));
normalized = lamb.fitting.normalizeExperimentalDispersionData(data);
verifyEqual(testCase, normalized.frequency_Hz, data.frequency_Hz);
verifyEqual(testCase, normalized.Cp_mps, data.Cp_mps);
verifyEqual(testCase, normalized.validMask, data.validMask);
verifyEqual(testCase, normalized.integrationMetadata, data.integrationMetadata);
verifyEqual(testCase, normalized.source, data.source);
end

function testRawCurveAndSignedIdentityStayExplicit(testCase)
[source, selection, metadata] = fixture();
selection.directionIndex = 4;
selection.curve = "raw";
first = prepareOceFitObservations(source, selection, metadata);
verifyEqual(testCase, first.experimental.source.angularIndex, 2);
verifyEqual(testCase, first.experimental.source.fullCircleAngle_deg, 90);
verifyEqual(testCase, first.experimental.directionId, "scan_axis_2:right");
verifyEqual(testCase, first.experimental.Cp_mps, ...
    source.dispersion.estimators.kf_ridge.directions(4).phase_speed_curve.raw_phase_speed_m_per_s(:));
verifyEqual(testCase, first.measuredThickness_m, 0.00065, 'AbsTol', 1e-18);
metadata.repetitionId = 2;
source.acquisition.run_id = "run_2";
second = prepareOceFitObservations(source, selection, metadata);
verifyEqual(testCase, second.experimental.integrationMetadata.repetitionId, 2);
verifyEqual(testCase, second.experimental.source.acquisition.run_id, "run_2");
verifyEqual(testCase, numel(second.experimental.frequency_Hz), numel(first.experimental.frequency_Hz));
verifyEqual(testCase, second.experimental.frequency_Hz, first.experimental.frequency_Hz);
end

function testPhaseGradientIsNotSubstitutedOrAveraged(testCase)
[source, selection, metadata] = fixture();
selection = rmfield(selection, 'curve');
selection.estimator = "phase_gradient";
selection.validMask = true;
first = prepareOceFitObservations(source, selection, metadata);
verifyEqual(testCase, first.experimental.frequency_Hz, 1500);
verifyEqual(testCase, first.experimental.Cp_mps, 11);
verifyEqual(testCase, first.experimental.source.estimator, "phase_gradient");
selection.directionIndex = 2;
metadata.repetitionId = 2;
second = prepareOceFitObservations(source, selection, metadata);
verifyEqual(testCase, second.experimental.frequency_Hz, first.experimental.frequency_Hz);
verifyEqual(testCase, second.experimental.Cp_mps, 12);
verifyNotEqual(testCase, second.experimental.directionId, first.experimental.directionId);
source.dispersion.estimators.phase_gradient.directions(2).status = "nonfinite_signal";
source.dispersion.estimators.phase_gradient.directions(2).phase_speed_m_per_s = NaN;
selection.validMask = false;
excluded = prepareOceFitObservations(source, selection, metadata);
verifyTrue(testCase, isnan(excluded.experimental.Cp_mps));
verifyFalse(testCase, excluded.experimental.validMask);
verifyFalse(testCase, excluded.experimental.source.estimatorEvidence.originalMasks.valid_mask);
source.dispersion.estimators.phase_gradient.enabled = false;
verifyError(testCase, @() prepareOceFitObservations(source, selection, metadata), ...
    'lamb:oceIntegration:EstimatorUnavailable');
end

function testSelectedInvalidNumbersCannotBeSilentlyDeselected(testCase)
[source, selection, metadata] = fixture();
source.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s(2) = NaN;
% Show the inherited normalizer hazard independently of the app guard.
unsafe = struct('frequency_Hz', source.dispersion.estimators.kf_ridge.frequency_axis_hz, ...
    'Cp_mps', source.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s, ...
    'validMask', selection.validMask);
normalized = lamb.fitting.normalizeExperimentalDispersionData(unsafe);
verifyFalse(testCase, normalized.validMask(2));
verifyError(testCase, @() prepareOceFitObservations(source, selection, metadata), ...
    'lamb:oceIntegration:InvalidSelectedObservation');
selection.validMask(2) = false;
source.dispersion.estimators.kf_ridge.frequency_axis_hz(1) = 0;
verifyError(testCase, @() prepareOceFitObservations(source, selection, metadata), ...
    'lamb:oceIntegration:InvalidSelectedObservation');
end

function testMetadataAndSelectionHaveNoPhysicalDefaults(testCase)
[source, selection, metadata] = fixture();
metadata.mode = "S0"; % Evidence only; the translator does not impose A0.
prepared = prepareOceFitObservations(source, selection, metadata);
verifyEqual(testCase, prepared.experimental.integrationMetadata, metadata);
verifyFalse(testCase, isfield(prepared, 'density_kgpm3'));
verifyError(testCase, @() prepareOceFitObservations(source, selection, rmfield(metadata, 'conditionId')), ...
    'lamb:oceIntegration:MissingMetadata');
selection.estimator = "auto";
verifyError(testCase, @() prepareOceFitObservations(source, selection, metadata), ...
    'lamb:oceIntegration:UnsupportedEstimator');
end

function testDirectSvdPlateEquivalence(testCase)
[source, selection, metadata] = fixture();
selection.validMask = [true false true true true];
prepared = prepareOceFitObservations(source, selection, metadata);
manual = manualData(source, selection, metadata);
physical = struct('density_kgpm3', 1070, 'thickness_m', 0.0005);
mapped = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(prepared.experimental, physical);
direct = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(manual, physical);
verifyTrue(testCase, mapped.accepted);
verifyEqual(testCase, rmfield(mapped, 'experimental'), rmfield(direct, 'experimental'));
verifyEqual(testCase, [mapped.alpha_Pa, mapped.gamma_Pa], [314300 147200], 'AbsTol', 2e-7);
verifyEqual(testCase, mapped.validMask, selection.validMask(:));
end

function testNonlinearRayleighLambEquivalence(testCase)
[source, selection, metadata] = fixture();
params = lamb.models.rayleigh_lamb.rlDefaultParams();
params.mu = 85e3; params.rho = 1070; params.thickness = 0.5e-3;
frequency = [1000; 2000; 3500; 5000; 7000];
options = lamb.models.rayleigh_lamb.rlDefaultOptions("Fast");
speed = lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(params, frequency, "A0", options);
source.dispersion.estimators.kf_ridge.frequency_axis_hz = frequency;
speed(2) = NaN; % excluded datum must survive preparation and fitting
source.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s = speed;
selection.validMask = [true; false; true; true; true];
prepared = prepareOceFitObservations(source, selection, metadata);
manual = manualData(source, selection, metadata);
config = struct('branchName', "A0", 'freeParams', "mu", ...
    'fixedParams', struct('rho', params.rho, 'thickness', params.thickness, 'nu', params.nu), ...
    'initialGuess', struct('mu', 50e3), 'bounds', struct('mu', [20e3 200e3]), ...
    'solverOptions', options, 'fitOptions', struct('useStandardErrorWeights', false));
mapped = lamb.fitting.rayleigh_lamb.rlFitDispersionData(prepared.experimental, config);
direct = lamb.fitting.rayleigh_lamb.rlFitDispersionData(manual, config);
% Wall-clock execution time is observational, not a scientific output.
mapped.modelEvaluation.modelResult.execution = ...
    rmfield(mapped.modelEvaluation.modelResult.execution, 'elapsedSeconds');
direct.modelEvaluation.modelResult.execution = ...
    rmfield(direct.modelEvaluation.modelResult.execution, 'elapsedSeconds');
verifyEqual(testCase, rmfield(mapped, 'problem'), rmfield(direct, 'problem'));
verifyEqual(testCase, mapped.problem.experimental.validMask, selection.validMask);
verifyEqual(testCase, mapped.validMask, selection.validMask);
verifyTrue(testCase, isnan(mapped.Cp_exp_mps(2)));
verifyLessThan(testCase, abs(mapped.bestParams.mu-params.mu)/params.mu, 0.03);
end

function manual = manualData(source, selection, metadata)
manual = struct('frequency_Hz', double(source.dispersion.estimators.kf_ridge.frequency_axis_hz(:)), ...
    'Cp_mps', double(source.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s(:)), ...
    'validMask', selection.validMask(:), 'conditionId', metadata.conditionId, ...
    'directionId', "scan_axis_1:left");
end

function [source, selection, metadata] = fixture()
% Narrow consumer projection, not a second complete OCE schema fixture.
frequency = [800.14304727021295 4367.7985459023481 9583.0979186334731 ...
    20543.560908072888 53135.565817473445];
speed = [12.568617595625258 13.721843824166998 15.053095009905279 ...
    16.134875006844061 16.693030321651151];
direction = struct('ridge', struct('valid_mask', [true false true true false], ...
    'interpolated_mask', [false true false false false], ...
    'extrapolated_mask', [false false false false true]), ...
    'phase_speed_curve', struct('smoothed_phase_speed_m_per_s', speed, ...
        'raw_phase_speed_m_per_s', speed+1), 'target_selection', struct('selected_bin_index', 1));
identities = struct('scan_axis_index', {1,1,2,2}, 'direction', {"left","right","left","right"});
gradient = struct('enabled', true, 'directions', ...
    struct('status', {"valid","valid","valid","valid"}, 'phase_speed_m_per_s', {11,12,13,14}));
source = struct('schema', struct('name', "oce_phase_speed_result", 'version', 4), ...
    'processing_run_id', "synthetic_processing", ...
    'acquisition', struct('experiment_id', "synthetic", 'run_id', "run_1"), ...
    'dispersion', struct('directions', identities, 'scan_axis_angles_deg', [0 90], ...
        'estimators', struct('kf_ridge', struct('frequency_axis_hz', frequency, ...
        'directions', repmat(direction, 1, 4)), 'phase_gradient', gradient), ...
        'target_frequency', struct('source', "resolved_filter_center", 'requested_hz', 1500), ...
        'filter_effective_passband_hz', [500 55000]), ...
    'borders', struct('directional_mean_thickness_mm', [0.5 0.55 0.6 0.65]), ...
    'angular', struct('source_direction_indices', [1 4 2 3], 'full_circle_angles_deg', [0 90 180 270]));
selection = struct('directionIndex', 1, 'estimator', "kf_ridge", 'curve', "smoothed", ...
    'validMask', true(1, 5));
metadata = struct('conditionId', "synthetic_state", 'repetitionId', 1, ...
    'loadingCondition', struct('label', "explicit synthetic state"), ...
    'sourceResultFile', "synthetic/PhaseSpeed.mat", 'metadataReference', "synthetic log row 1");
end
