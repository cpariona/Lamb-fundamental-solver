function rawResult = mrlfeSolveViscoelasticBranch(problem, configuration)
%MRLFESOLVEVISCOELASTICBRANCH Solve the viscoelastic adaptive mRLFE branch.

options = mrlfeBuildViscoelasticOptions(configuration);
mrlfeParams = options.mrlfeParams;
mrlfeParams.solveComplexK = false;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;

seed = mrlfeBuildSeed(problem, configuration);
branchSolve = mrlfeTrackBranchAdaptive(problem, seed, configuration, mrlfeParams, options);
branchSolve = mrlfeApplyTerminationPolicy(branchSolve, seed, configuration);
branchSolve.productionPolicy = branchPolicyName(configuration.branch, configuration.terminationPolicy, "viscoelastic");
branchSolve.solverRoute = "viscoelasticAdaptive";
branchSolve.seedMode = seed;

mrlfeResult = buildModelResult(problem, mrlfeParams, branchSolve, "viscoelastic-adaptive-real-k");
rawResult = mrlfeBuildInternalBranchResult(problem, configuration, mrlfeResult, branchSolve, ...
    "viscoelastic_adaptive", "viscous_unified_atlas");
end

function options = mrlfeBuildViscoelasticOptions(configuration)
options = configuration.internalOptions;
branchName = configuration.branch;
options.mrlfeA0DPCandidates = getOption(options, 'mrlfeA0DPCandidates', 8);
options.mrlfeA0DPCpScanPoints = getOption(options, 'mrlfeViscoAtlasCpScanPoints', getOption(options, 'mrlfeA0DPCpScanPoints', 900));
options.mrlfeA0DPEdgeGuardPoints = getOption(options, 'mrlfeA0DPEdgeGuardPoints', 6);
options.mrlfeA0DPRefineCandidates = getOption(options, 'mrlfeA0DPRefineCandidates', true);
options.mrlfeResidualTolerance = max(getOption(options, 'mrlfeResidualTolerance', 1e-4), 1e-3);

if branchName == "A0Like"
    options.mrlfeAdaptiveCpScanPoints = getOption(options, 'mrlfeAdaptiveCpScanPoints', getOption(options, 'mrlfeViscoAtlasCpScanPoints', 900));
    options.mrlfeAdaptiveWindows = getOption(options, 'mrlfeAdaptiveWindows', [0.20 0.35 0.50 0.80 1.20]);
    options.mrlfeAdaptiveEdgeGuardPoints = getOption(options, 'mrlfeAdaptiveEdgeGuardPoints', 4);
    options.mrlfeAdaptiveRefineCandidates = getOption(options, 'mrlfeAdaptiveRefineCandidates', true);
    options.mrlfeAdaptiveMaxJumpRelative = getOption(options, 'mrlfeAdaptiveMaxJumpRelative', 0.12);
    options.mrlfeAdaptiveMaxPredictionError = getOption(options, 'mrlfeAdaptiveMaxPredictionError', 0.12);
    options.mrlfeAdaptiveResidualWeight = getOption(options, 'mrlfeAdaptiveResidualWeight', 0.45);
    options.mrlfeAdaptivePredictionWeight = getOption(options, 'mrlfeAdaptivePredictionWeight', 45.0);
    options.mrlfeAdaptiveEstablishedMinValidRun = getOption(options, 'mrlfeAdaptiveEstablishedMinValidRun', 8);
    options.mrlfeAdaptiveCutAfterEstablishedLoss = getOption(options, 'mrlfeAdaptiveCutAfterEstablishedLoss', true);
    options.mrlfeAdaptiveAllowValleyFallback = getOption(options, 'mrlfeAdaptiveAllowValleyFallback', true);
    options.mrlfeAdaptiveValleyFallbackRelativeWindow = getOption(options, 'mrlfeAdaptiveValleyFallbackRelativeWindow', 0.10);
    options.mrlfeAdaptiveValleyFallbackPredictionWeight = getOption(options, 'mrlfeAdaptiveValleyFallbackPredictionWeight', 65.0);
    options.mrlfeAdaptiveValleyFallbackResidualWeight = getOption(options, 'mrlfeAdaptiveValleyFallbackResidualWeight', 0.30);
else
    options.mrlfeAdaptiveCpScanPoints = getOption(options, 'mrlfeAdaptiveCpScanPoints', getOption(options, 'mrlfeViscoAtlasCpScanPoints', 900));
    options.mrlfeAdaptiveWindows = getOption(options, 'mrlfeAdaptiveWindows', [0.12 0.20 0.35 0.50]);
    options.mrlfeAdaptiveEdgeGuardPoints = getOption(options, 'mrlfeAdaptiveEdgeGuardPoints', 4);
    options.mrlfeAdaptiveResidualWeight = getOption(options, 'mrlfeAdaptiveResidualWeight', 0.35);
    options.mrlfeAdaptivePredictionWeight = getOption(options, 'mrlfeAdaptivePredictionWeight', 55.0);
    options.mrlfeAdaptiveMaxJumpRelative = getOption(options, 'mrlfeAdaptiveMaxJumpRelative', 0.18);
    options.mrlfeAdaptiveMaxPredictionError = getOption(options, 'mrlfeAdaptiveMaxPredictionError', 0.18);
    options.mrlfeAdaptiveCutAfterEstablishedLoss = getOption(options, 'mrlfeAdaptiveCutAfterEstablishedLoss', true);
    options.mrlfeAdaptiveEstablishedMinValidRun = getOption(options, 'mrlfeAdaptiveEstablishedMinValidRun', 8);
end
end

function policy = branchPolicyName(branchName, terminationPolicy, regime)
if branchName == "A0Like" && terminationPolicy == "physicalTail"
    policy = regime + "_A0_physicalTail";
else
    policy = regime + "_" + string(branchName) + "_adaptive";
end
end

function result = buildModelResult(problem, mrlfeParams, branch, variant)
result = struct();
result.modelName = "mRLFE";
result.variant = variant;
result.description = "mRLFE model-layer production branch result.";
result.parameters = mrlfeParams;
result.frequency = problem.frequencySolve_Hz(:);
result.branches = struct();
result.branches.(char(problem.branch)) = branch;
result.diagnostics = struct('variant', variant, 'branchNames', problem.branch);
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
