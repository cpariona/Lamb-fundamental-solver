function result = mrlfeSolve(request)
%MRLFESOLVE Solve a real-k mRLFE branch through the public request contract.

configuration = mrlfeResolveConfiguration(request);

timerStart = tic;
[~, rawResult] = mrlfeEvaluateAtlasFitModel(configuration.solverParams, ...
    configuration.request.frequency_Hz(:), ...
    configuration.branch, ...
    configuration.internalOptions);
elapsedSeconds = toc(timerStart);

result = mrlfeBuildResult(configuration, rawResult, elapsedSeconds);
end
