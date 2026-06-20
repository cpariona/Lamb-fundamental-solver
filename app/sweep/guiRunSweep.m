function sweepOutput = guiRunSweep(request)
%GUIRUNSWEEP Dispatch a normalized GUI sweep request to a model adapter.
%
% This function is the stable GUI-facing sweep entrypoint. Model-specific
% details belong in app/adapters/guiRun<Model>Sweep functions.

modelFamily = lower(string(request.modelFamily));

switch modelFamily
    case "mrlfe"
        sweepOutput = guiRunMRLFESweep(request);
    otherwise
        error('Unsupported GUI sweep model family: %s', string(request.modelFamily));
end
end
