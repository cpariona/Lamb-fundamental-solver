function result = mrlfeSolve(request)
%MRLFESOLVE Solve a real-k mRLFE branch through the public request contract.

configuration = lamb.models.mrlfe.configuration.mrlfeResolveConfiguration(request);
problem = lamb.models.mrlfe.core.mrlfeBuildProblem(configuration);

timerStart = tic;
rawResult = lamb.models.mrlfe.solvers.mrlfeSolveBranch(problem, configuration);
elapsedSeconds = toc(timerStart);

result = lamb.models.mrlfe.results.mrlfeBuildResult(configuration, rawResult, elapsedSeconds);
end
