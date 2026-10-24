function tests = test_oce_qh_plate_integration
%TEST_OCE_QH_PLATE_INTEGRATION Reviewed QH rows, native diagnostics and lineage.
tests = functiontests(localfunctions);
end

function testDirectEquivalenceMissingRepetitionsAndExclusions(testCase)
[sources, selection, physical, review] = fixture();
selection.observations = selection.observations([5;1;4;2;3], :);
selection.observations.include(3) = false;
sources(4).scientific_result.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s(2) = NaN;
% Explicit review may retain an already interpolated target; no flag is repaired.
sources(1).scientific_result.dispersion.estimators.kf_ridge.directions(1).ridge.valid_mask(2) = false;
sources(1).scientific_result.dispersion.estimators.kf_ridge.directions(1).ridge.interpolated_mask(2) = true;
assembly = prepareOceQhFitObservations(sources, selection);
manual = manualData(sources, selection);
verifyEqual(testCase, assembly.experimental, manual);
verifyEqual(testCase, assembly.experimental.validMask, [true;true;false;true;true]);
verifyTrue(testCase, isnan(assembly.experimental.Cp_mps(3)));
verifyEqual(testCase, [assembly.lineage.sourceRow]', selection.observations.sourceRow);
verifyEqual(testCase, assembly.physicalFrequency_Hz, [7500;1000;5000;1000;2500]);
for row = 1:height(selection.observations)
    i = selection.observations.sourceRow(row);
    item = assembly.lineage(row);
    verifyEqual(testCase, item.resultFile, sources(i).result_file);
    verifyEqual(testCase, item.acquisitionMetadata, sources(i).acquisition_metadata);
    verifyEqual(testCase, item.prepared.experimental.source.estimatorEvidence.originalMasks, ...
        sources(i).scientific_result.dispersion.estimators.kf_ridge.directions(1).ridge);
    verifyEqual(testCase, item.prepared.experimental.integrationMetadata.repetitionId, ...
        sources(i).acquisition_metadata.rep_id);
    verifyEqual(testCase, item.prepared.experimental.frequency_Hz(1), 0);
    verifyFalse(testCase, item.prepared.experimental.validMask(1));
end
integrated = fitOceQhPrestressedPlate(assembly, physical, review);
direct = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(manual, physical);
verifyEqual(testCase, integrated.nativeResult, direct);
verifyEqual(testCase, integrated.status, "accepted");
verifyEqual(testCase, integrated.independentPhysicalFrequencyCount, 3);
verifyEqual(testCase, direct.diagnostics.frequencyObservationCount, [2;1;1]);
verifyFalse(testCase, isfield(assembly.experimental, 'standardError_Cp_mps'));
end

function testSinglePhysicalFrequencyRetainsNativeRejection(testCase)
[sources, selection, physical, review] = fixture();
selection.observations = selection.observations(1:2, :);
% Replicate speed scatter can give a rank-two observation design, not coverage.
sources(2).scientific_result.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s(2) = ...
    sources(2).scientific_result.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s(2)*1.01;
assembly = prepareOceQhFitObservations(sources, selection);
outcome = fitOceQhPrestressedPlate(assembly, physical, review);
direct = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(manualData(sources,selection), physical);
verifyEqual(testCase, outcome.nativeResult, direct);
verifyEqual(testCase, outcome.status, "rejected");
verifyEqual(testCase, direct.diagnostics.independentFrequencyCount, 1);
verifyTrue(testCase, ismember("insufficient_independent_frequencies", direct.reasons));
end

function testBinJitterCannotManufactureIndependentCoverage(testCase)
[sources, selection, physical, review] = fixture();
selection.observations = selection.observations(1:2, :);
sources(2).scientific_result.dispersion.estimators.kf_ridge.frequency_axis_hz(2) = 1000+eps(1000);
sources(2).scientific_result.dispersion.estimators.kf_ridge.directions(1).target_selection.selected_frequency_hz = 1000+eps(1000);
assembly = prepareOceQhFitObservations(sources, selection);
outcome = fitOceQhPrestressedPlate(assembly, physical, review);
verifyEqual(testCase, outcome.status, "rejected");
verifyEqual(testCase, outcome.nativeResult.diagnostics.independentFrequencyCount, 1);
verifyTrue(testCase,ismember("insufficient_independent_frequencies",outcome.nativeResult.reasons));
verifyFalse(testCase,outcome.nativeGroupingCompatible);
verifyEqual(testCase, outcome.independentPhysicalFrequencyCount, 1);
verifyEqual(testCase, outcome.assembly.experimental.frequency_Hz, [1000;1000+eps(1000)]);
% Native callers without explicit groups retain exact-observed-Hz behavior.
direct = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(assembly.experimental,physical);
verifyEqual(testCase, direct.diagnostics.independentFrequencyCount, 2);
selection.observations = table((1:5)',repmat(2,5,1),true(5,1), ...
    'VariableNames',{'sourceRow','binIndex','include'});
multiple = fitOceQhPrestressedPlate(prepareOceQhFitObservations(sources,selection),physical,review);
verifyEqual(testCase, multiple.independentPhysicalFrequencyCount, 4);
verifyEqual(testCase, multiple.nativeResult.diagnostics.independentFrequencyCount, 4);
verifyEqual(testCase, multiple.nativeResult.diagnostics.frequencyObservationCount, [2;1;1;1]);
end

function testVaryingBinsUsePhysicalGroupsWithoutChangingRegression(testCase)
[sources, selection, physical, review] = fixture();
observed = [990;990.25;2505;5005;7495];
parameters = physical; parameters.alpha_Pa = 314300; parameters.gamma_Pa = 147200;
mode = lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion(observed,parameters);
for row=1:5
    sources(row).acquisition_metadata.period_us = 200+row; % Not a QH frequency identity.
    kf = sources(row).scientific_result.dispersion.estimators.kf_ridge;
    kf.frequency_axis_hz(2) = observed(row);
    for direction=1:2
        kf.directions(direction).target_selection.selected_frequency_hz = observed(row);
        kf.directions(direction).phase_speed_curve.smoothed_phase_speed_m_per_s(2) = ...
            mode.phaseVelocity_mps(row)+direction-1;
    end
    sources(row).scientific_result.dispersion.estimators.kf_ridge = kf;
end
assembly = prepareOceQhFitObservations(sources,selection);
original = assembly;
outcome = fitOceQhPrestressedPlate(assembly,physical,review);
manual = manualData(sources,selection);
ungrouped = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(manual,physical);
manual.independentFrequencyGroupId = [1;1;2;3;4];
direct = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(manual,physical);
verifyEqual(testCase,outcome.nativeResult,direct);
verifyEqual(testCase,outcome.status,"accepted");
verifyEqual(testCase,outcome.assembly,original);
verifyEqual(testCase,outcome.assembly.experimental.frequency_Hz,observed);
verifyEqual(testCase,outcome.assembly.physicalFrequency_Hz,[1000;1000;2500;5000;7500]);
verifyEqual(testCase,outcome.assembly.requestedTargetFrequency_Hz,original.requestedTargetFrequency_Hz);
verifyFalse(testCase,isfield(assembly.experimental,'independentFrequencyGroupId'));
for name=["alpha_Pa","gamma_Pa","etaSquared","regressionResidual_Pa","validMask"]
    verifyEqual(testCase,direct.(name),ungrouped.(name));
end
verifyEqual(testCase,[direct.alpha_Pa;direct.gamma_Pa],[314300;147200],'AbsTol',2e-7);
verifyEqual(testCase,direct.diagnostics.frequencyObservationCount,[2;1;1;1]);
verifyEqual(testCase,direct.diagnostics.observationCount,5);
end

function testExcludedBinJitterPreservesCompatibleLegacyCall(testCase)
[sources, selection, physical, review] = fixture();
selection.observations.include(2) = false;
sources(2).scientific_result.dispersion.estimators.kf_ridge.frequency_axis_hz(2) = 990;
sources(2).scientific_result.dispersion.estimators.kf_ridge.directions(1).target_selection.selected_frequency_hz = 990;
assembly = prepareOceQhFitObservations(sources,selection);
outcome = fitOceQhPrestressedPlate(assembly,physical,review);
direct = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(assembly.experimental,physical);
verifyTrue(testCase,outcome.nativeGroupingCompatible);
verifyEqual(testCase,outcome.nativeResult,direct);
verifyEqual(testCase,outcome.independentPhysicalFrequencyCount,4);
verifyEqual(testCase,outcome.nativeResult.validMask,selection.observations.include);
end

function testExactNumericPhysicalFrequencyIdentity(testCase)
[sources, selection, physical, review] = fixture();
selection.observations = selection.observations(1:2,:);
sources(2).acquisition_metadata.frequency_Hz = 1000+eps(1000);
assembly = prepareOceQhFitObservations(sources,selection);
verifyEqual(testCase,assembly.physicalFrequency_Hz,[1000;1000+eps(1000)]);
verifyEqual(testCase,assembly.experimental.frequency_Hz,[1000;1000]);
outcome = fitOceQhPrestressedPlate(assembly,physical,review);
verifyEqual(testCase,outcome.independentPhysicalFrequencyCount,2);
verifyEqual(testCase,outcome.nativeResult.experimental.independentFrequencyGroupId,[1;2]);
verifyFalse(testCase,outcome.nativeResult.accepted); % Group labels cannot repair rank.
sources(2).acquisition_metadata.frequency_Hz = "1000";
legacyText = prepareOceQhFitObservations(sources,selection);
verifyEqual(testCase,legacyText.physicalFrequency_Hz,[1000;1000]);
end

function testPulsePeriodsCannotBecomeQhFrequencyGroups(testCase)
[sources, selection] = fixture();
for row=1:5
    sources(row).acquisition_metadata.excitation_type = "pulse";
    sources(row).acquisition_metadata.period_us = 100+row;
end
verifyError(testCase,@() prepareOceQhFitObservations(sources,selection),'lamb:oceQh:NotQuasiHarmonic');
end

function testSignedDirectionAndConditionAreNeverPooled(testCase)
[sources, selection] = fixture();
selection.direction = "right";
right = prepareOceQhFitObservations(sources, selection);
verifyEqual(testCase, right.experimental.directionId, "scan_axis_1:right");
verifyEqual(testCase, right.experimental.Cp_mps, manualData(sources,selection).Cp_mps);
verifyEqual(testCase, right.measuredThickness_m, .0007*ones(5,1));
verifyEqual(testCase, right.identity.directionId, "scan_axis_1:right");
sources(2).scientific_result.dispersion.scan_axis_angles_deg = 90;
verifyError(testCase, @() prepareOceQhFitObservations(sources,selection), 'lamb:oceQh:MixedGeometry');
sources(2).scientific_result.dispersion.scan_axis_angles_deg = 0;
sources(3).acquisition_metadata.strain_percent = 10;
verifyError(testCase, @() prepareOceQhFitObservations(sources,selection), 'lamb:oceQh:ConditionMismatch');
end

function testExplicitThicknessPolicyAndModelReview(testCase)
[sources, selection, physical, review] = fixture();
sources(2).scientific_result.borders.directional_mean_thickness_mm(1) = .61;
assembly = prepareOceQhFitObservations(sources,selection);
verifyEqual(testCase, assembly.measuredThickness_m(2), .00061, 'AbsTol', 1e-18);
outcome = fitOceQhPrestressedPlate(assembly,physical,review);
verifyEqual(testCase, outcome.physical.thickness_m, .0005);
verifyEqual(testCase, outcome.assembly.measuredThickness_m(2), .00061, 'AbsTol', 1e-18);
bad = review; bad.thicknessJustification = "";
verifyError(testCase, @() fitOceQhPrestressedPlate(assembly,physical,bad), 'lamb:oceQh:PhysicalReviewRequired');
bad = review; bad.mode = "S0";
verifyError(testCase, @() fitOceQhPrestressedPlate(assembly,physical,bad), 'lamb:oceQh:PhysicalReviewRequired');
badPhysical = physical; badPhysical.appliedMass_kg = .1;
verifyError(testCase, @() fitOceQhPrestressedPlate(assembly,badPhysical,review), 'lamb:oceQh:InvalidPhysicalInputs');
sources(2).scientific_result.borders.directional_mean_thickness_mm(1) = NaN;
missing = prepareOceQhFitObservations(sources,selection);
independent = fitOceQhPrestressedPlate(missing,physical,review);
verifyTrue(testCase, isnan(independent.assembly.measuredThickness_m(2)));
verifyEqual(testCase, independent.review.thicknessSource, review.thicknessSource);
verifyEqual(testCase, independent.nativeResult, outcome.nativeResult);
verifyEqual(testCase, independent.thicknessDiagnostics.unavailableOctThicknessCount, 1);
verifyEqual(testCase, independent.thicknessDiagnostics.finiteOctThicknessCount, 4);
bad = review; bad.thicknessSource = "";
verifyError(testCase, @() fitOceQhPrestressedPlate(missing,physical,bad), 'lamb:oceQh:PhysicalReviewRequired');
for i = 1:numel(sources)
    sources(i).scientific_result.borders.directional_mean_thickness_mm(1) = NaN;
end
allMissing = prepareOceQhFitObservations(sources,selection);
independent = fitOceQhPrestressedPlate(allMissing,physical,review);
verifyTrue(testCase, all(isnan(independent.assembly.measuredThickness_m)));
verifyTrue(testCase, isnan(independent.thicknessDiagnostics.rangeOctThickness_m));
verifyEqual(testCase, independent.nativeResult, outcome.nativeResult);
end

function testSpecimenIdentityRemainsOptionalButCannotBeMixed(testCase)
[sources, selection] = fixture();
assembly = prepareOceQhFitObservations(sources,selection);
verifyEqual(testCase, assembly.identity.sampleId, "SpecimenA");
verifyTrue(testCase, assembly.identity.sampleIdAvailable);
sources(3).acquisition_metadata.sample_id = "SpecimenB";
verifyError(testCase, @() prepareOceQhFitObservations(sources,selection), 'lamb:oceQh:MixedSpecimen');
sources(3).acquisition_metadata.sample_id = "SpecimenA";
selection.sampleId = "SpecimenB";
verifyError(testCase, @() prepareOceQhFitObservations(sources,selection), 'lamb:oceQh:MixedSpecimen');
selection = rmfield(selection,'sampleId');
sources(3).acquisition_metadata = removevars(sources(3).acquisition_metadata,'sample_id');
verifyError(testCase, @() prepareOceQhFitObservations(sources,selection), 'lamb:oceQh:MixedSpecimen');
for i = [1,2,4,5]
    sources(i).acquisition_metadata = removevars(sources(i).acquisition_metadata,'sample_id');
end
unknown = prepareOceQhFitObservations(sources,selection);
verifyFalse(testCase, unknown.identity.sampleIdAvailable);
verifyEqual(testCase, unknown.identity.sampleId, "");
for i = 1:numel(sources), sources(i).acquisition_metadata.sample_id = ""; end
blank = prepareOceQhFitObservations(sources,selection);
verifyEqual(testCase, blank.identity, unknown.identity);
end

function testIntendedExperimentSubexperimentAndScopedAcquisitions(testCase)
[sources, selection] = fixture();
wrong = selection; wrong.experimentId = "other_experiment";
verifyError(testCase, @() prepareOceQhFitObservations(sources,wrong), 'lamb:oceQh:IdentityMismatch');
wrong = selection; wrong.subexperimentId = "OtherCondition";
verifyError(testCase, @() prepareOceQhFitObservations(sources,wrong), 'lamb:oceQh:IdentityMismatch');
% A coherent second subexperiment still cannot be pooled without equivalence.
sources(2).acquisition_metadata.sub_experiment = "OtherCondition";
sources(2).scientific_result.acquisition.subexperiment_id = "OtherCondition";
sources(2).acquisition_metadata.run_id = "R1";
sources(2).scientific_result.acquisition.run_id = "R1";
verifyError(testCase, @() prepareOceQhFitObservations(sources,selection), 'lamb:oceQh:IdentityMismatch');
sources(2).acquisition_metadata.sub_experiment = "Condition0";
sources(2).scientific_result.acquisition.subexperiment_id = "Condition0";
% Repeated run IDs in one subexperiment have distinct source paths.
valid = prepareOceQhFitObservations(sources,selection);
verifyEqual(testCase, valid.lineage(1).prepared.experimental.source.acquisition.run_id, ...
    valid.lineage(2).prepared.experimental.source.acquisition.run_id);
verifyNotEqual(testCase, valid.lineage(1).resultFile, valid.lineage(2).resultFile);
verifyError(testCase, @() prepareOceQhFitObservations([sources;sources],selection), 'lamb:oceQh:AmbiguousSource');
sources(2).result_file = sources(1).result_file;
verifyError(testCase, @() prepareOceQhFitObservations(sources,selection), 'lamb:oceQh:DuplicateAcquisition');
sources(2).result_file = "fixture/PhaseSpeed_2.mat";
sources(2).scientific_result.acquisition.run_id = "mismatched_result";
verifyError(testCase, @() prepareOceQhFitObservations(sources,selection), 'lamb:oceQh:IdentityMismatch');
end

function testNoSilentSelectionRepairOrNonTargetBins(testCase)
[sources, selection] = fixture();
selection.observations.binIndex(1) = 3;
verifyError(testCase, @() prepareOceQhFitObservations(sources,selection), 'lamb:oceQh:NotTargetBin');
selection.observations.binIndex(1) = 2;
selection.observations.sourceRow(2) = 1;
verifyError(testCase, @() prepareOceQhFitObservations(sources,selection), 'lamb:oceQh:DuplicateAcquisition');
selection.observations.sourceRow(2) = 2;
sources(1).scientific_result.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s(2) = NaN;
verifyError(testCase, @() prepareOceQhFitObservations(sources,selection), 'lamb:oceIntegration:InvalidSelectedObservation');
end

function manual = manualData(sources, selection)
n = height(selection.observations); f = zeros(n,1); cp = f;
directionIndex = 1 + (selection.direction == "right");
for row = 1:n
    i = selection.observations.sourceRow(row); bin = selection.observations.binIndex(row);
    kf = sources(i).scientific_result.dispersion.estimators.kf_ridge;
    f(row) = kf.frequency_axis_hz(bin);
    cp(row) = kf.directions(directionIndex).phase_speed_curve.smoothed_phase_speed_m_per_s(bin);
end
manual = struct('frequency_Hz',f,'Cp_mps',cp,'validMask',selection.observations.include, ...
    'conditionId',selection.conditionId,'directionId',"scan_axis_1:"+selection.direction);
end

function [sources, selection, physical, review] = fixture()
f = [1000;1000;2500;5000;7500]; reps = [1;3;1;1;3];
physical = struct('density_kgpm3',1070,'thickness_m',.0005);
forward = physical; forward.alpha_Pa = 314300; forward.gamma_Pa = 147200;
mode = lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion(f, forward);
sources = repmat(struct('summary_source_row',[],'result_file',"", ...
    'acquisition_metadata',table(),'scientific_result',struct(),'provenance',"matching_processing_run_id_only"),5,1);
for row = 1:5
    directions = repmat(struct('scan_axis_index',1,'direction',"left"),2,1);
    directions(2).direction = "right";
    for d = 1:2
        curve = struct('raw_phase_speed_m_per_s',[NaN;mode.phaseVelocity_mps(row)+d;.1], ...
            'smoothed_phase_speed_m_per_s',[NaN;mode.phaseVelocity_mps(row)+d-1;.1]);
        item(d) = struct('phase_speed_curve',curve, ...
            'ridge',struct('valid_mask',logical([0;1;0]),'interpolated_mask',logical([0;0;1]), ...
            'extrapolated_mask',false(3,1)), 'target_selection',struct('selected_bin_index',2, ...
            'selected_frequency_hz',f(row))); %#ok<AGROW>
    end
    result = struct('schema',struct('name',"oce_phase_speed_result",'version',4), ...
        'processing_run_id',"synthetic_run", ...
        'acquisition',struct('experiment_id',"synthetic",'subexperiment_id',"Condition0",'run_id',"R"+row), ...
        'borders',struct('directional_mean_thickness_mm',[.5;.7]), ...
        'angular',struct('source_direction_indices',[2;1],'full_circle_angles_deg',[0;180]), ...
        'dispersion',struct('directions',directions,'scan_axis_angles_deg',0, ...
            'target_frequency',struct('source',"resolved_filter_center",'requested_hz',f(row)), ...
            'filter_effective_passband_hz',[], ...
            'estimators',struct('kf_ridge',struct('frequency_axis_hz',[0;f(row);f(row)+100], ...
                'directions',item))));
    metadata = table("synthetic","Condition0","R"+row,"SpecimenA","quasi_harmonic",f(row),reps(row),0, ...
        'VariableNames',{'experiment_id','sub_experiment','run_id','sample_id','excitation_type','frequency_Hz','rep_id','strain_percent'});
    sources(row).summary_source_row = row; sources(row).result_file = "fixture/PhaseSpeed_"+row+".mat";
    sources(row).acquisition_metadata = metadata; sources(row).scientific_result = result;
end
selection = struct('experimentId',"synthetic",'subexperimentId',"Condition0", ...
    'conditionId',"condition_0",'condition',struct('strain_percent',0), ...
    'scanAxisIndex',1,'direction',"left",'curve',"smoothed",'metadataReference',"synthetic AcquisitionParams", ...
    'observations',table((1:5)',repmat(2,5,1),true(5,1), ...
    'VariableNames',{'sourceRow','binIndex','include'}));
review = struct('mode',"A0",'thicknessPolicy',"explicit_constant_current_thickness", ...
    'thicknessSource',"Independent synthetic current full-thickness calibration, SI metres.", ...
    'thicknessJustification',"Synthetic homogeneous constant-current-thickness plate.", ...
    'densityReference',"Synthetic forward-model density.", ...
    'modelSupportReference',"Synthetic principal propagation, incompressible isotropic plate, traction-free faces.");
end
