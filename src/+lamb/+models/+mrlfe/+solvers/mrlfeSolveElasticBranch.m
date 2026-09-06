function rawResult = mrlfeSolveElasticBranch(problem, configuration)
%MRLFESOLVEELASTICBRANCH Solve the zero-viscosity adaptive mRLFE branch.

options = configuration.internalOptions;
mrlfeParams = options.mrlfeParams;
mrlfeParams.etaS = 0;
mrlfeParams.solveComplexK = false;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;

[seed, seedResult] = lamb.models.mrlfe.tracking.mrlfeBuildSeed(problem, configuration);
branchSolve = lamb.models.mrlfe.tracking.mrlfeTrackBranchRobustStart(problem, seed, configuration, mrlfeParams, options);
branchSolve = lamb.models.mrlfe.policies.mrlfeApplyTerminationPolicy(branchSolve, seed, configuration);
branchSolve.productionPolicy = branchPolicyName(configuration.branch, configuration.terminationPolicy, "elastic");
branchSolve.solverRoute = "elasticAdaptive";
branchSolve.seedMode = seed;
branchSolve.seedResult = seedResult;

rawResult = lamb.models.mrlfe.results.mrlfeBuildInternalBranchResult(problem, configuration, branchSolve, ...
    "elastic_adaptive", "elastic_adaptive");
end
function policy = branchPolicyName(branchName, terminationPolicy, regime)
if branchName == "A0Like" && terminationPolicy == "physicalTail"
    policy = regime + "_A0_physicalTail";
else
    policy = regime + "_" + string(branchName) + "_adaptive";
end
end

