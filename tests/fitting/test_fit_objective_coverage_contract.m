function test_fit_objective_coverage_contract()
%TEST_FIT_OBJECTIVE_COVERAGE_CONTRACT Protect fixed fitting-observation coverage.

fprintf('\nRunning fitting objective coverage contract test...\n');
fprintf('-----------------------------------------------\n');

experimental = struct();
experimental.frequency_Hz = [1000; 2000; 3000; 4000];
experimental.Cp_mps = [2; 3; 4; 5];
experimental.validMask = [true; true; false; true];

%% Explicitly excluded observations do not belong to the objective.
CpModel = [2.1; 3.1; NaN; 5.1];
[residuals, info] = lamb.fitting.computeDispersionFitResiduals(CpModel, experimental);
assert(max(abs(residuals - 0.1)) < 1e-12);
assert(isequal(info.objectiveMask, experimental.validMask));
assert(~info.modelFiniteMask(3));
assert(~any(info.missingModelMask));
assert(info.expectedPointCount == 3 && info.evaluatedPointCount == 3);
assert(info.coverageAccepted && info.numResiduals == 3);

%% A required model point may not disappear from the objective.
assertError(@() lamb.fitting.computeDispersionFitResiduals( ...
    [2; NaN; 4; 5], experimental), 'lamb:fitting:IncompleteModelCoverage');
assertError(@() lamb.fitting.computeDispersionFitMetrics( ...
    [2; NaN; 4; 5], experimental), 'lamb:fitting:IncompleteModelCoverage');

%% Missing coverage is an inadmissible optimizer candidate, not a better fit.
objectiveExperimental = struct('frequency_Hz', [1; 2; 3], ...
    'Cp_mps', [2; 3; 4], 'validMask', true(3,1));
problem = struct();
problem.lowerBounds = 0;
problem.upperBounds = 1;
problem.x0 = 1;
problem.residualFunction = @(x) localCoverageResidual(x, objectiveExperimental);
partialObjective = lamb.fitting.evaluateBoundedObjective(0, problem);
fullObjective = lamb.fitting.evaluateBoundedObjective(1, problem);
assert(isfinite(partialObjective) && partialObjective > 1e100, ...
    'Incomplete model coverage must receive an inadmissible objective penalty.');
assert(abs(fullObjective - 0.03) < 1e-12, ...
    'Complete model coverage must retain the ordinary SSE objective.');

%% Local sensitivity must use the same fixed objective mask for +/- perturbations.
sensitivityExperimental = struct('frequency_Hz', [1; 2; 3], ...
    'Cp_mps', [1; 2; 3], 'validMask', true(3,1));
assertError(@() lamb.fitting.estimateLocalSensitivity( ...
    @localSensitivityModel, struct('a', 1), "a", sensitivityExperimental), ...
    'lamb:fitting:SensitivityIncompleteModelCoverage');

%% AE fitting rejects selected frequencies below its internal initialization anchor.
aeExperimental = struct('frequency_Hz', [100; 300; 1000], ...
    'Cp_mps', [2; 3; 4], 'validMask', true(3,1));
aeConfig = struct('freeParams', "mu", 'bounds', struct('mu', [20e3, 300e3]));
assertError(@() lamb.fitting.acoustoelastic_iop_hgo.aeBuildFitProblem( ...
    aeExperimental, aeConfig), 'lamb:fitting:AEObjectiveOutsideSupportedRange');

aeExperimental.validMask(1) = false;
aeProblem = lamb.fitting.acoustoelastic_iop_hgo.aeBuildFitProblem(aeExperimental, aeConfig);
assert(nnz(aeProblem.experimental.validMask) == 2, ...
    'Explicitly excluded AE observations below the anchor must remain excluded.');

%% The retired RL partial-coverage option cannot silently weaken the contract.
rlExperimental = struct('frequency_Hz', [1000; 2000], ...
    'Cp_mps', [2; 3], 'validMask', true(2,1));
rlConfig = struct('freeParams', "mu", ...
    'fitOptions', struct('useStandardErrorWeights', false, 'minValidFraction', 0.8));
assertError(@() lamb.fitting.rayleigh_lamb.rlBuildFitProblem( ...
    rlExperimental, rlConfig), 'lamb:fitting:PartialCoverageNotSupported');

fprintf('Fitting objective coverage contract test passed.\n');
end

function residuals = localCoverageResidual(x, experimental)
if x < 0.5
    CpModel = [2; NaN; NaN];
else
    CpModel = [2.1; 3.1; 4.1];
end
residuals = lamb.fitting.computeDispersionFitResiduals(CpModel, experimental);
end

function CpModel = localSensitivityModel(params)
CpModel = params.a .* [1; 2; 3];
if params.a < 1
    CpModel(2) = NaN;
end
end

function assertError(fcn, expectedIdentifier)
try
    fcn();
catch ME
    assert(strcmp(ME.identifier, expectedIdentifier), ...
        'Expected error %s, got %s: %s', expectedIdentifier, ME.identifier, ME.message);
    return;
end
error('Expected error %s was not thrown.', expectedIdentifier);
end
