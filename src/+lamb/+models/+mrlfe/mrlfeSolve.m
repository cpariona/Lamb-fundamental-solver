function result = mrlfeSolve(request)
%MRLFESOLVE Solve a real-k mRLFE branch through the public request contract.
%   REQUEST contains branch, frequency_Hz, material, geometry, fluid,
%   numerics, selection, termination, and fallback. Public physical fields
%   use SI units: mu_Pa, etaS_Pas, rho_kgm3, nu, thickness_m,
%   density_kgm3, and soundSpeed_mps. frequency_Hz must be positive and
%   strictly ascending.
%   The maintained public RL seed requires 0.49 <= nu < 0.5. This is an
%   execution-support limit, not a restriction of the constitutive equations.
%
%   RESULT exposes branch, frequency_Hz, phaseVelocity_mps,
%   wavenumber_radpm, validMask, quality, termination, fallback, execution,
%   diagnostics, and requested/effective configuration. Invalid phase speed
%   is NaN. The maintained route selects A0Like/S0Like through adaptive
%   tracking and does not substitute a fallback curve.

configuration = lamb.models.mrlfe.configuration.mrlfeResolveConfiguration(request);
problem = lamb.models.mrlfe.core.mrlfeBuildProblem(configuration);

timerStart = tic;
switch string(configuration.materialRegime)
    case "elasticZeroViscosity"
        options = configuration.internalOptions;
        mrlfeParams = options.mrlfeParams;
        mrlfeParams.etaS = 0;
        regime = "elastic";
        engineName = "elastic_adaptive";
        solverRoute = "elasticAdaptive";
    case "viscoelastic"
        options = mrlfeBuildViscoelasticOptions(configuration);
        mrlfeParams = options.mrlfeParams;
        regime = "viscoelastic";
        engineName = "viscoelastic_adaptive";
        solverRoute = "viscoelasticAdaptive";
    otherwise
        error('mrlfe:InvalidMaterialRegime', ...
            'Unsupported mRLFE material regime "%s".', string(configuration.materialRegime));
end
mrlfeParams.solveComplexK = false;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;

[seed, seedResult] = lamb.models.mrlfe.tracking.mrlfeBuildSeed(problem, configuration);
branchSolve = lamb.models.mrlfe.tracking.mrlfeTrackBranchRobustStart(problem, seed, configuration, mrlfeParams, options);
branchSolve = lamb.models.mrlfe.policies.mrlfeApplyTerminationPolicy(branchSolve, seed, configuration);
branchSolve.productionPolicy = branchPolicyName(configuration.branch, configuration.terminationPolicy, regime);
branchSolve.solverRoute = solverRoute;
branchSolve.seedMode = seed;
branchSolve.seedResult = seedResult;

rawResult = lamb.models.mrlfe.results.mrlfeBuildInternalBranchResult(problem, configuration, branchSolve, ...
    engineName, engineName);
elapsedSeconds = toc(timerStart);

result = lamb.models.mrlfe.results.mrlfeBuildResult(configuration, rawResult, elapsedSeconds);
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
