function tests = test_ae_plate_fitting()
%TEST_AE_PLATE_FITTING Linear recovery, fixed masks and independent coverage.
tests = functiontests(localfunctions);
end

function testIndependentSyntheticRecovery(testCase)
[data, p] = independentData();
fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p);
verifyTrue(testCase, fit.accepted);
verifyEqual(testCase, [fit.alpha_Pa, fit.gamma_Pa], [314300, 147200], 'AbsTol', 2e-7);
verifyEqual(testCase, fit.regressionResidual_Pa, zeros(5, 1), 'AbsTol', 2e-7);
verifyEqual(testCase, fit.diagnostics.designRank, 2);
verifyEqual(testCase, fit.diagnostics.independentFrequencyCount, 5);
end

function testTwoFrequencyStressByElimination(testCase)
[data, p] = independentData();
data.validMask = [true; false; false; false; true];
fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p);
% Eliminate alpha,gamma from Note 7 using tabulated eta at q=0.1,5.
% With the F definition printed in Eq. (S.11), the sign before the F term
% must be MINUS to agree with rho*Cp^2=alpha-gamma*eta^2 (see model docs).
etaSquared = [0.98690177551891908826, 0.10962452709283784900];
y = p.density_kgpm3*data.Cp_mps([1, 5]).^2;
factor = (sum(etaSquared)-2)/(etaSquared(1)-etaSquared(2));
stress = (sum(y)-(y(1)-y(2))*factor)/2;
verifyTrue(testCase, fit.accepted);
verifyEqual(testCase, stress, 167100, 'AbsTol', 2e-9);
verifyEqual(testCase, fit.alpha_Pa-fit.gamma_Pa, stress, 'AbsTol', 2e-7);
end

function testFixedMaskAndExcludedBadData(testCase)
[data, p] = independentData();
data.frequency_Hz = [NaN; data.frequency_Hz; -1];
data.Cp_mps = [NaN; data.Cp_mps; -100];
data.validMask = [false; true(5, 1); false];
data.conditionId = ["excluded"; repmat("state_1", 5, 1); "other"];
data.directionId = ["opposite"; repmat("+x1", 5, 1); "-x1"];
original = data;
fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p);
verifyTrue(testCase, fit.accepted);
verifyEqual(testCase, fit.experimental, original);
verifyEqual(testCase, fit.validMask, data.validMask);
verifyTrue(testCase, all(isnan(fit.regressionResidual_Pa(~data.validMask))));
data.validMask(1) = true;
verifyError(testCase, @() lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p), ...
    'lamb:aePlate:InvalidSelectedObservation');
end

function testReplicatesRemainSeparate(testCase)
[data, p] = independentData();
data.frequency_Hz = repelem(data.frequency_Hz, 3);
data.Cp_mps = repelem(data.Cp_mps, 3);
data.validMask = true(15, 1);
fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p);
verifyTrue(testCase, fit.accepted);
verifyEqual(testCase, fit.diagnostics.observationCount, 15);
verifyEqual(testCase, fit.diagnostics.independentFrequencyCount, 5);
verifyEqual(testCase, fit.diagnostics.frequencyObservationCount, repmat(3, 5, 1));
verifyEqual(testCase, numel(fit.regressionResidual_Pa), 15);
end

function testOneFrequencyScatterCannotCreateCoverage(testCase)
[data, p] = independentData();
data.frequency_Hz(:) = 1000;
fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p);
verifyFalse(testCase, fit.accepted);
verifyEqual(testCase, fit.diagnostics.designRank, 2);
verifyEqual(testCase, fit.diagnostics.frequencyDesignRank, 1);
verifyTrue(testCase, ismember("insufficient_independent_frequencies", fit.reasons));
end

function testSingleObservationAndRankDeficiency(testCase)
[data, p] = independentData();
data.validMask = [true; false(4, 1)];
fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p);
verifyFalse(testCase, fit.accepted);
verifyTrue(testCase, isnan(fit.alpha_Pa));
verifyTrue(testCase, ismember("rank_deficient", fit.reasons));
data.frequency_Hz(:) = 1000;
data.Cp_mps(:) = 12;
data.validMask(:) = true;
fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p);
verifyEqual(testCase, fit.diagnostics.designRank, 1);
verifyTrue(testCase, isnan(fit.gamma_Pa));
end

function testThinAndHighFrequencyPlateaus(testCase)
[data, p] = independentData();
p.thickness_m = 1e-8;
fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p);
verifyFalse(testCase, fit.accepted);
verifyTrue(testCase, ismember("poor_conditioning", fit.reasons));
verifyTrue(testCase, ismember("insufficient_dispersion_coverage", fit.reasons));
p.thickness_m = 1;
fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p);
verifyFalse(testCase, fit.accepted);
verifyTrue(testCase, ismember("rank_deficient", fit.reasons));
end

function testResidualUnitsAndOriginalOLS(testCase)
[data, p] = independentData();
data.Cp_mps = data.Cp_mps+[0.02; -0.03; 0.01; 0.04; -0.02];
fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p);
design = [ones(5, 1), -fit.etaSquared];
y = p.density_kgpm3*data.Cp_mps.^2;
% Independent QR via backslash, not the production SVD implementation.
candidate = design\y;
expectedResidual = design*candidate-y;
verifyEqual(testCase, [fit.alpha_Pa; fit.gamma_Pa], candidate, 'AbsTol', 2e-9);
verifyEqual(testCase, fit.regressionResidual_Pa, expectedResidual, 'AbsTol', 1e-9);
verifyEqual(testCase, fit.sumSquaredResidual_Pa2, sum(expectedResidual.^2), 'RelTol', 1e-11);
verifyEqual(testCase, fit.regressionRMSE_Pa, sqrt(mean(expectedResidual.^2)), 'RelTol', 1e-11);
verifyEqual(testCase, fit.validMask, data.validMask);
end

function testMixedConditionsAndOppositeDirectionsRejected(testCase)
[data, p] = independentData();
data.directionId = ["+x1"; "-x1"; "+x1"; "+x1"; "+x1"];
verifyError(testCase, @() lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p), ...
    'lamb:aePlate:MixedGrouping');
data.directionId = "+x1";
data.conditionId = ["one"; "two"; "one"; "one"; "one"];
verifyError(testCase, @() lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p), ...
    'lamb:aePlate:MixedGrouping');
end

function testNonphysicalCandidatePreservesMask(testCase)
[data, p] = independentData();
% Increasing q and decreasing Cp force a negative gamma in the regression.
data.frequency_Hz = [100; 500; 1000; 5000; 10000];
data.Cp_mps = [20; 18; 16; 14; 12];
fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p);
verifyLessThan(testCase, fit.gamma_Pa, 0);
verifyFalse(testCase, fit.accepted);
verifyTrue(testCase, ismember("outside_tensile_model_support", fit.reasons));
verifyEqual(testCase, fit.validMask, data.validMask);
verifyTrue(testCase, all(isfinite(fit.regressionResidual_Pa)));
end

function testRankTwoButPoorCoverage(testCase)
[data, p] = independentData();
p.thickness_m = 2e-6;
fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p);
verifyEqual(testCase, fit.diagnostics.designRank, 2);
verifyFalse(testCase, fit.accepted);
verifyTrue(testCase, ismember("insufficient_dispersion_coverage", fit.reasons));
end

function testUnstressedAndForwardSyntheticRecovery(testCase)
[data, p] = independentData();
for stress = [0, 10e3, 200e3]
    parameters = p;
    parameters.gamma_Pa = 147200;
    parameters.alpha_Pa = parameters.gamma_Pa+stress;
    mode = lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion(data.frequency_Hz, parameters);
    data.Cp_mps = mode.phaseVelocity_mps;
    fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p);
    verifyEqual(testCase, [fit.alpha_Pa, fit.gamma_Pa], ...
        [parameters.alpha_Pa, parameters.gamma_Pa], 'AbsTol', 2e-7);
    if stress > 0
        verifyTrue(testCase, fit.accepted);
    elseif ~fit.accepted
        % Do not fabricate positivity at the tensile boundary. A negative
        % difference below roundoff resolution remains an unaccepted result.
        verifyEqual(testCase, fit.reasons, "tensile_boundary_unresolved");
        verifyLessThanOrEqual(testCase, abs(fit.alpha_Pa-fit.gamma_Pa), ...
            fit.diagnostics.stressDifferenceRoundoffBound_Pa);
    end
end
end

function testRowMaskAndObservationOrder(testCase)
[data, p] = independentData();
order = [4, 2, 5, 1, 3];
data.frequency_Hz = data.frequency_Hz(order).';
data.Cp_mps = data.Cp_mps(order).';
data.validMask = [true, false, true, true, true];
fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p);
verifyEqual(testCase, fit.experimental, data);
verifyEqual(testCase, fit.validMask, data.validMask(:));
verifyEqual(testCase, fit.wavenumberThickness(data.validMask), [2; 5; 0.1; 1], 'AbsTol', 1e-13);
verifyTrue(testCase, fit.accepted);
end

function testInvalidMaskAndMetadataAreRejected(testCase)
[data, p] = independentData();
data.directionId = 1;
verifyError(testCase, @() lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p), ...
    'lamb:aePlate:InvalidGrouping');
data.directionId = "";
verifyError(testCase, @() lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p), ...
    'lamb:aePlate:MixedGrouping');
data.directionId = "+x1";
data.validMask(:) = false;
verifyError(testCase, @() lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data, p), ...
    'lamb:aePlate:InvalidSelectedObservation');
end

function [data, p] = independentData()
% 80-digit roots of the original equation, q=[0.1,0.5,1,2,5].
% rho=1070 kg/m^3, full thickness=0.5 mm, alpha=314.3 kPa, gamma=147.2 kPa.
data = struct('frequency_Hz', [800.14304727021295; 4367.7985459023481; ...
    9583.0979186334731; 20543.560908072888; 53135.565817473445], ...
    'Cp_mps', [12.568617595625258; 13.721843824166998; 15.053095009905279; ...
    16.134875006844061; 16.693030321651151], 'validMask', true(5, 1), ...
    'conditionId', "state_1", 'directionId', "+x1");
p = struct('density_kgpm3', 1070, 'thickness_m', 0.0005);
end
