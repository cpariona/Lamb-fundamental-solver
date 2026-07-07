function rawResult = mrlfeSolveElasticBranch(problem, configuration)
%MRLFESOLVEELASTICBRANCH Solve the zero-viscosity adaptive mRLFE branch.

options = configuration.internalOptions;
mrlfeParams = options.mrlfeParams;
mrlfeParams.etaS = 0;
mrlfeParams.solveComplexK = false;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;

seed = mrlfeBuildSeed(problem, configuration);
branchSolve = mrlfeTrackBranchAdaptive(problem, seed, configuration, mrlfeParams, options);
branchSolve = mrlfeApplyTerminationPolicy(branchSolve, seed, configuration);
branchSolve.productionPolicy = branchPolicyName(configuration.branch, configuration.terminationPolicy, "elastic");
branchSolve.solverRoute = "elasticAdaptive";
branchSolve.seedMode = seed;

mrlfeResult = buildModelResult(problem, mrlfeParams, branchSolve, "elastic-adaptive-real-k");
rawResult = mrlfeBuildInternalBranchResult(problem, configuration, mrlfeResult, branchSolve, ...
    "elastic_adaptive", "zero_viscosity_adaptive_atlas");
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
