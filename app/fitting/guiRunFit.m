function fitOutput = guiRunFit(request)
%GUIRUNFIT Dispatch a normalized fitting request to a model adapter.
%
% This is the stable app-facing fitting entrypoint. Model-specific details
% belong in app/adapters/guiFit<Model>Solver functions.

modelFamily = lower(string(request.modelFamily));

switch modelFamily
    case {"rayleigh_lamb", "rayleighlamb", "rl"}
        fitOutput = guiFitRLSolver(request);
    otherwise
        error('Unsupported GUI fit model family: %s', string(request.modelFamily));
end
end
