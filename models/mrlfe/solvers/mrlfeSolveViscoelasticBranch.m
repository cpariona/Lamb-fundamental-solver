function rawResult = mrlfeSolveViscoelasticBranch(problem, configuration)
%MRLFESOLVEVISCOELASTICBRANCH Solve the viscoelastic adaptive mRLFE branch.

options = mrlfeBuildViscoelasticOptions(configuration);
mrlfeParams = options.mrlfeParams;
mrlfeParams.solveComplexK = false;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;

[seed, seedResult] = mrlfeBuildSeed(problem, configuration);
branchSolve = mrlfeTrackBranchRobustStart(problem, seed, configuration, mrlfeParams, options);
branchSolve = mrlfeApplyTerminationPolicy(branchSolve, seed, configuration);
branchSolve.productionPolicy = branchPolicyName(configuration.branch, configuration.terminationPolicy, "viscoelastic");
branchSolve.solverRoute = "viscoelasticAdaptive";
branchSolve.seedMode = seed;
branchSolve.seedResult = seedResult;

rawResult = mrlfeBuildInternalBranchResult(problem, configuration, branchSolve, ...
    "viscoelastic_adaptive", "viscoelastic_adaptive");
end

function options = mrlfeBuildViscoelasticOptions(configuration)
options = configuration.internalOptions;
branchName = configuration.branch;
options.trackerCandidateCount = getOption(options, 'trackerCandidateCount', 8);
options.trackerCpScanPoints = getOption(options, 'trackerCpScanPoints', 900);
options.trackerEdgeGuardPoints = getOption(options, 'trackerEdgeGuardPoints', 6);
options.trackerRefineCandidates = getOption(options, 'trackerRefineCandidates', true);
options.residualTolerance = max(getOption(options, 'residualTolerance', 1e-4), 1e-3);

if branchName == "A0Like"
    options.trackerWindows = getOption(options, 'trackerWindows', [0.20 0.35 0.50 0.80 1.20]);
    options.trackerEdgeGuardPoints = getOption(options, 'trackerEdgeGuardPoints', 4);
    options.trackerMaxJumpRelative = getOption(options, 'trackerMaxJumpRelative', 0.12);
    options.trackerMaxPredictionError = getOption(options, 'trackerMaxPredictionError', 0.12);
    options.trackerResidualWeight = getOption(options, 'trackerResidualWeight', 0.45);
    options.trackerPredictionWeight = getOption(options, 'trackerPredictionWeight', 45.0);
    options.trackerEstablishedMinValidRun = getOption(options, 'trackerEstablishedMinValidRun', 8);
    options.trackerCutAfterEstablishedLoss = getOption(options, 'trackerCutAfterEstablishedLoss', true);
    options.trackerAllowValleyFallback = getOption(options, 'trackerAllowValleyFallback', true);
    options.trackerValleyFallbackRelativeWindow = getOption(options, 'trackerValleyFallbackRelativeWindow', 0.10);
    options.trackerValleyFallbackPredictionWeight = getOption(options, 'trackerValleyFallbackPredictionWeight', 65.0);
    options.trackerValleyFallbackResidualWeight = getOption(options, 'trackerValleyFallbackResidualWeight', 0.30);
else
    options.trackerWindows = getOption(options, 'trackerWindows', [0.12 0.20 0.35 0.50]);
    options.trackerEdgeGuardPoints = getOption(options, 'trackerEdgeGuardPoints', 4);
    options.trackerResidualWeight = getOption(options, 'trackerResidualWeight', 0.35);
    options.trackerPredictionWeight = getOption(options, 'trackerPredictionWeight', 55.0);
    options.trackerMaxJumpRelative = getOption(options, 'trackerMaxJumpRelative', 0.18);
    options.trackerMaxPredictionError = getOption(options, 'trackerMaxPredictionError', 0.18);
    options.trackerCutAfterEstablishedLoss = getOption(options, 'trackerCutAfterEstablishedLoss', true);
    options.trackerEstablishedMinValidRun = getOption(options, 'trackerEstablishedMinValidRun', 8);
end
end

function policy = branchPolicyName(branchName, terminationPolicy, regime)
if branchName == "A0Like" && terminationPolicy == "physicalTail"
    policy = regime + "_A0_physicalTail";
else
    policy = regime + "_" + string(branchName) + "_adaptive";
end
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
