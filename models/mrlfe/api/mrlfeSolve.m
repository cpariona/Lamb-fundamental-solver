function result = mrlfeSolve(request)
%MRLFESOLVE Solve a real-k mRLFE branch through the public request contract.

configuration = mrlfeResolveConfiguration(request);
problem = mrlfeBuildProblem(configuration);

timerStart = tic;
rawResult = mrlfeSolveBranch(problem, configuration);
elapsedSeconds = toc(timerStart);

result = mrlfeBuildResult(configuration, rawResult, elapsedSeconds);
end
